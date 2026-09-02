-- DATABASE SCHEMA: OUTLET ONBOARDING (Phan 1: Master Data & Address)
-- Enterprise Features: Multi-Country, Sync Status, Offline-First

CREATE TABLE IF NOT EXISTS tblValueSet (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    value_set_code VARCHAR(100) NOT NULL UNIQUE,
    value_set_name VARCHAR(255) NOT NULL,
    description TEXT,
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tblValueSetValue (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    value_set_code VARCHAR(100) NOT NULL REFERENCES tblValueSet(value_set_code) ON DELETE CASCADE,
    value_code VARCHAR(100) NOT NULL,
    value_name VARCHAR(255) NOT NULL,
    parent_code VARCHAR(100),
    display_order INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    country_code VARCHAR(10) NOT NULL DEFAULT 'VNM' CHECK (country_code IN ('VNM', 'LAO', 'CAM', 'MMR')),
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    effective_to TIMESTAMPTZ,
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(value_set_code, value_code, country_code)
);

CREATE INDEX IF NOT EXISTS idx_value_set_value_code ON tblValueSetValue(value_code);
CREATE INDEX IF NOT EXISTS idx_value_set_parent ON tblValueSetValue(parent_code);
CREATE INDEX IF NOT EXISTS idx_value_set_active ON tblValueSetValue(is_active, delete_flg);
CREATE INDEX IF NOT EXISTS idx_value_set_country ON tblValueSetValue(country_code) WHERE delete_flg = '0';

CREATE TABLE IF NOT EXISTS tblProvince (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    province_code VARCHAR(20) NOT NULL UNIQUE,
    province_name VARCHAR(255) NOT NULL,
    country_code VARCHAR(10) NOT NULL DEFAULT 'VNM',
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tblDistrict (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    province_code VARCHAR(20) NOT NULL REFERENCES tblProvince(province_code) ON DELETE CASCADE,
    district_code VARCHAR(20) NOT NULL UNIQUE,
    district_name VARCHAR(255) NOT NULL,
    country_code VARCHAR(10) NOT NULL DEFAULT 'VNM',
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tblWard (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    district_code VARCHAR(20) NOT NULL REFERENCES tblDistrict(district_code) ON DELETE CASCADE,
    ward_code VARCHAR(30) NOT NULL UNIQUE,
    ward_name VARCHAR(255) NOT NULL,
    street_number VARCHAR(50),
    street_name VARCHAR(255),
    country_code VARCHAR(10) NOT NULL DEFAULT 'VNM',
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW()
);

CREATE OR REPLACE FUNCTION update_last_update_date() RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update_date = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_tblValueSet ON tblValueSet;
CREATE TRIGGER trg_update_tblValueSet BEFORE UPDATE ON tblValueSet FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblValueSetValue ON tblValueSetValue;
CREATE TRIGGER trg_update_tblValueSetValue BEFORE UPDATE ON tblValueSetValue FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblProvince ON tblProvince;
CREATE TRIGGER trg_update_tblProvince BEFORE UPDATE ON tblProvince FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblDistrict ON tblDistrict;
CREATE TRIGGER trg_update_tblDistrict BEFORE UPDATE ON tblDistrict FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblWard ON tblWard;
CREATE TRIGGER trg_update_tblWard BEFORE UPDATE ON tblWard FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

CREATE TABLE IF NOT EXISTS tblSyncLog (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    table_name VARCHAR(100) NOT NULL,
    local_id VARCHAR(100),
    server_id BIGINT,
    action VARCHAR(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE')),
    payload JSONB,
    sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'FAILED', 'CONFLICT')),
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    created_by BIGINT NOT NULL,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_sync_attempt TIMESTAMPTZ,
    resolved_at TIMESTAMPTZ,
    resolution_strategy VARCHAR(20) CHECK (resolution_strategy IN ('SERVER_WINS', 'CLIENT_WINS', 'MERGED'))
);

CREATE INDEX IF NOT EXISTS idx_sync_log_status ON tblSyncLog(sync_status, creation_date);
CREATE INDEX IF NOT EXISTS idx_sync_log_local_id ON tblSyncLog(table_name, local_id);


-- UNIQUE constraints for ON CONFLICT (added in Phan 3 seed data)
DO $$ BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'tblvaluesetvalue_unique') THEN
        ALTER TABLE tblValueSetValue ADD CONSTRAINT tblvaluesetvalue_unique UNIQUE (value_set_code, value_code);
    END IF;
END $$;
