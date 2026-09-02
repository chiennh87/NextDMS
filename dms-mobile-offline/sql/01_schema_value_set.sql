-- ============================================================================
-- DATABASE SCHEMA: OUTLET ONBOARDING (Phần 1: Master Data & Address)
-- Author: Senior Mobile Developer - DMS Team
-- ============================================================================

-- ============================================================================
-- MASTER DATA TABLES (ValueSet, ValueSetValue)
-- ============================================================================

-- Table: tblValueSet (Quản lý các nhóm giá trị master)
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

-- Table: tblValueSetValue (Chi tiết các giá trị trong mỗi nhóm)
CREATE TABLE IF NOT EXISTS tblValueSetValue (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    value_set_code VARCHAR(100) NOT NULL REFERENCES tblValueSet(value_set_code) ON DELETE CASCADE,
    value_code VARCHAR(100) NOT NULL,
    value_name VARCHAR(255) NOT NULL,
    parent_code VARCHAR(100),
    display_order INTEGER DEFAULT 0,
    sort_order INTEGER DEFAULT 0,
    description TEXT,
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    effective_to TIMESTAMPTZ,
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(value_set_code, value_code)
);

CREATE INDEX IF NOT EXISTS idx_value_set_value_code ON tblValueSetValue(value_code);
CREATE INDEX IF NOT EXISTS idx_value_set_parent ON tblValueSetValue(parent_code);
CREATE INDEX IF NOT EXISTS idx_value_set_active ON tblValueSetValue(is_active, delete_flg);

-- ============================================================================
-- ADDRESS REFERENCE TABLES (Tỉnh/Huyện/Xã)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tblProvince (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    province_code VARCHAR(20) NOT NULL UNIQUE,
    province_name VARCHAR(255) NOT NULL,
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
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(province_code, district_code)
);

CREATE TABLE IF NOT EXISTS tblWard (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    district_code VARCHAR(20) NOT NULL REFERENCES tblDistrict(district_code) ON DELETE CASCADE,
    ward_code VARCHAR(30) NOT NULL UNIQUE,
    ward_name VARCHAR(255) NOT NULL,
    street_number VARCHAR(50),
    street_name VARCHAR(255),
    is_active CHAR(1) DEFAULT '1' CHECK (is_active IN ('0', '1')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(district_code, ward_code)
);

-- ============================================================================
-- TRIGGER: Tự động cập nhật last_update_date
-- ============================================================================

CREATE OR REPLACE FUNCTION update_last_update_date()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_update_date = NOW();
    NEW.updated_by = COALESCE(NEW.updated_by, 0);
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trg_update_tblValueSet ON tblValueSet;
CREATE TRIGGER trg_update_tblValueSet 
BEFORE UPDATE ON tblValueSet 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblValueSetValue ON tblValueSetValue;
CREATE TRIGGER trg_update_tblValueSetValue 
BEFORE UPDATE ON tblValueSetValue 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblProvince ON tblProvince;
CREATE TRIGGER trg_update_tblProvince 
BEFORE UPDATE ON tblProvince 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblDistrict ON tblDistrict;
CREATE TRIGGER trg_update_tblDistrict 
BEFORE UPDATE ON tblDistrict 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

DROP TRIGGER IF EXISTS trg_update_tblWard ON tblWard;
CREATE TRIGGER trg_update_tblWard 
BEFORE UPDATE ON tblWard 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();
