-- DATABASE SCHEMA: OUTLET ONBOARDING (Phan 2: Outlet + Enterprise)
-- Enterprise Features: Approval Workflow, Offline-First Sync, Multi-Country, Data Scoping

CREATE TABLE IF NOT EXISTS tblOutlets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(100) NOT NULL,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(255),
    owner_dob DATE,
    phone VARCHAR(20),
    zalo_phone VARCHAR(20),
    identity_card_number VARCHAR(20),
    business_type VARCHAR(50),
    business_license_no VARCHAR(100),
    tax_code VARCHAR(50),
    address TEXT,
    province_code VARCHAR(20),
    district_code VARCHAR(20),
    ward_code VARCHAR(30),
    street_number VARCHAR(50),
    street_name VARCHAR(255),
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    photo_url TEXT,
    customer_type_code VARCHAR(50),
    customer_channel_code VARCHAR(50),
    tier VARCHAR(20),
    mcp_id BIGINT,
    -- Enterprise: Scoping
    distributor_id BIGINT NOT NULL,
    territory_id BIGINT NOT NULL,
    -- Enterprise: Approval Workflow
    approval_status VARCHAR(30) NOT NULL DEFAULT 'PENDING_APPROVAL' CHECK (approval_status IN ('DRAFT', 'PENDING_APPROVAL', 'APPROVED', 'REJECTED')),
    approved_by BIGINT,
    approval_date TIMESTAMPTZ,
    rejected_reason TEXT,
    -- Enterprise: Offline-First Sync
    sync_status VARCHAR(20) NOT NULL DEFAULT 'PENDING' CHECK (sync_status IN ('PENDING', 'SYNCING', 'SYNCED', 'FAILED')),
    local_id VARCHAR(100),
    sync_error_log TEXT,
    -- Enterprise: Multi-Country
    country_code VARCHAR(10) NOT NULL DEFAULT 'VNM' CHECK (country_code IN ('VNM', 'LAO', 'CAM', 'MMR')),
    -- Status
    status VARCHAR(20) DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE', 'INACTIVE')),
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    -- Audit
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(code, distributor_id, territory_id)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_outlets_distributor ON tblOutlets(distributor_id);
CREATE INDEX IF NOT EXISTS idx_outlets_territory ON tblOutlets(territory_id);
CREATE INDEX IF NOT EXISTS idx_outlets_scoping ON tblOutlets(distributor_id, territory_id);
CREATE INDEX IF NOT EXISTS idx_outlets_approval ON tblOutlets(approval_status);
CREATE INDEX IF NOT EXISTS idx_outlets_sync ON tblOutlets(sync_status);
CREATE INDEX IF NOT EXISTS idx_outlets_local_id ON tblOutlets(local_id) WHERE local_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_outlets_country ON tblOutlets(country_code);
CREATE INDEX IF NOT EXISTS idx_outlets_phone ON tblOutlets(phone) WHERE phone IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_outlets_gps ON tblOutlets(latitude, longitude) WHERE latitude IS NOT NULL;

-- Trigger for last_update_date
DROP TRIGGER IF EXISTS trg_update_tblOutlets ON tblOutlets;
CREATE TRIGGER trg_update_tblOutlets BEFORE UPDATE ON tblOutlets FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

-- Function: Check duplicate outlet by scoping
CREATE OR REPLACE FUNCTION fn_check_duplicate_outlet(
    p_phone VARCHAR,
    p_tax_code VARCHAR,
    p_identity_card VARCHAR,
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION,
    p_distributor_id BIGINT,
    p_territory_id BIGINT
) RETURNS TABLE(
    outlet_id BIGINT,
    outlet_code VARCHAR,
    outlet_name VARCHAR,
    field_name VARCHAR,
    match_type VARCHAR,
    distance_meters DOUBLE PRECISION
) AS $$
BEGIN
    RETURN QUERY
    -- Exact matches by phone
    SELECT o.id, o.code, o.name, 'phone'::VARCHAR, 'EXACT'::VARCHAR, 0::DOUBLE PRECISION
    FROM tblOutlets o
    WHERE o.phone = p_phone AND o.phone IS NOT NULL
      AND o.distributor_id = p_distributor_id AND o.territory_id = p_territory_id
      AND o.delete_flg = '0' AND o.status = 'ACTIVE'
    UNION ALL
    -- Exact matches by tax code
    SELECT o.id, o.code, o.name, 'tax_code'::VARCHAR, 'EXACT'::VARCHAR, 0::DOUBLE PRECISION
    FROM tblOutlets o
    WHERE o.tax_code = p_tax_code AND o.tax_code IS NOT NULL
      AND o.distributor_id = p_distributor_id AND o.territory_id = p_territory_id
      AND o.delete_flg = '0' AND o.status = 'ACTIVE'
    UNION ALL
    -- Exact matches by identity card
    SELECT o.id, o.code, o.name, 'identity_card'::VARCHAR, 'EXACT'::VARCHAR, 0::DOUBLE PRECISION
    FROM tblOutlets o
    WHERE o.identity_card_number = p_identity_card AND o.identity_card_number IS NOT NULL
      AND o.distributor_id = p_distributor_id AND o.territory_id = p_territory_id
      AND o.delete_flg = '0' AND o.status = 'ACTIVE';
END;
$$ LANGUAGE plpgsql;

-- Function: Get outlets by scoping
CREATE OR REPLACE FUNCTION fn_get_outlets_by_scoping(
    p_distributor_id BIGINT,
    p_territory_id BIGINT
) RETURNS TABLE(
    id BIGINT,
    code VARCHAR,
    name VARCHAR,
    phone VARCHAR,
    address TEXT,
    province_code VARCHAR,
    district_code VARCHAR,
    ward_code VARCHAR,
    latitude DOUBLE PRECISION,
    longitude DOUBLE PRECISION,
    approval_status VARCHAR,
    sync_status VARCHAR,
    country_code VARCHAR
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.code, o.name, o.phone, o.address,
           o.province_code, o.district_code, o.ward_code,
           o.latitude, o.longitude,
           o.approval_status, o.sync_status, o.country_code
    FROM tblOutlets o
    WHERE o.distributor_id = p_distributor_id
      AND o.territory_id = p_territory_id
      AND o.delete_flg = '0'
    ORDER BY o.creation_date DESC;
END;
$$ LANGUAGE plpgsql;

-- Function: Get pending sync outlets
CREATE OR REPLACE FUNCTION fn_get_pending_sync_outlets(
    p_distributor_id BIGINT,
    p_territory_id BIGINT
) RETURNS TABLE(
    id BIGINT,
    code VARCHAR,
    name VARCHAR,
    local_id VARCHAR,
    sync_status VARCHAR,
    sync_error_log TEXT,
    last_update_date TIMESTAMPTZ
) AS $$
BEGIN
    RETURN QUERY
    SELECT o.id, o.code, o.name, o.local_id, o.sync_status, o.sync_error_log, o.last_update_date
    FROM tblOutlets o
    WHERE o.distributor_id = p_distributor_id
      AND o.territory_id = p_territory_id
      AND o.sync_status IN ('PENDING', 'FAILED')
      AND o.delete_flg = '0'
    ORDER BY o.last_update_date ASC;
END;
$$ LANGUAGE plpgsql;

