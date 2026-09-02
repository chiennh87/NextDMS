-- ============================================================================
-- OUTLET TABLE & VIEWS & FUNCTIONS (Phần 2)
-- ============================================================================

-- ============================================================================
-- OUTLET TABLE (Điểm bán)
-- ============================================================================

CREATE TABLE IF NOT EXISTS tblOutlets (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(100) NOT NULL UNIQUE,
    name VARCHAR(255) NOT NULL,
    short_name VARCHAR(255),
    owner_dob DATE,
    phone VARCHAR(20),
    zalo_phone VARCHAR(20),
    identity_card_number VARCHAR(50),
    business_type VARCHAR(20),
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
    customer_type_code VARCHAR(100) REFERENCES tblValueSetValue(value_code) ON DELETE SET NULL,
    customer_channel_code VARCHAR(100) REFERENCES tblValueSetValue(value_code) ON DELETE SET NULL,
    tier VARCHAR(50),
    mcp_id BIGINT,
    status VARCHAR(50) DEFAULT 'PENDING_VERIFICATION',
    delete_flg CHAR(1) DEFAULT '0' CHECK (delete_flg IN ('0', '1')),
    created_by BIGINT NOT NULL,
    updated_by BIGINT,
    creation_date TIMESTAMPTZ DEFAULT NOW(),
    last_update_date TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for fast duplicate detection
CREATE INDEX IF NOT EXISTS idx_outlet_phone ON tblOutlets(phone) WHERE delete_flg = '0';
CREATE INDEX IF NOT EXISTS idx_outlet_zalo ON tblOutlets(zalo_phone) WHERE delete_flg = '0';
CREATE INDEX IF NOT EXISTS idx_outlet_tax_code ON tblOutlets(tax_code) WHERE delete_flg = '0';
CREATE INDEX IF NOT EXISTS idx_outlet_id_card ON tblOutlets(identity_card_number) WHERE delete_flg = '0';
CREATE INDEX IF NOT EXISTS idx_outlet_gps ON tblOutlets USING GIST(
    ST_MakePoint(longitude, latitude)::GEOGRAPHY
) WHERE delete_flg = '0';

-- Trigger for tblOutlets
DROP TRIGGER IF EXISTS trg_update_tblOutlets ON tblOutlets;
CREATE TRIGGER trg_update_tblOutlets 
BEFORE UPDATE ON tblOutlets 
FOR EACH ROW EXECUTE FUNCTION update_last_update_date();

-- ============================================================================
-- VIEW: Thông tin đầy đủ của điểm bán
-- ============================================================================

CREATE OR REPLACE VIEW vwOutletDetails AS
SELECT 
    o.*,
    COALESCE(p.province_name, '') as province_name,
    COALESCE(d.district_name, '') as district_name,
    COALESCE(w.ward_name, '') as ward_name,
    COALESCE(p.province_name || ' - ' || d.district_name || ' - ' || w.ward_name, '') as full_address,
    CASE 
        WHEN w.street_number IS NOT NULL AND w.street_name IS NOT NULL 
        THEN w.street_number || ' ' || w.street_name 
        ELSE o.address 
    END as complete_address
FROM tblOutlets o
LEFT JOIN tblProvince p ON o.province_code = p.province_code
LEFT JOIN tblDistrict d ON o.district_code = d.district_code
LEFT JOIN tblWard w ON o.ward_code = w.ward_code
WHERE o.delete_flg = '0';

-- ============================================================================
-- FUNCTION: Haversine distance (đơn vị: mét)
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_haversine_distance(
    lon1 DOUBLE PRECISION, lat1 DOUBLE PRECISION,
    lon2 DOUBLE PRECISION, lat2 DOUBLE PRECISION
) RETURNS DOUBLE PRECISION AS $$
DECLARE
    earth_radius CONSTANT DOUBLE PRECISION := 6371000;
    dLon DOUBLE PRECISION;
    dLat DOUBLE PRECISION;
    a DOUBLE PRECISION;
    c DOUBLE PRECISION;
BEGIN
    IF lon1 IS NULL OR lat1 IS NULL OR lon2 IS NULL OR lat2 IS NULL THEN
        RETURN NULL;
    END IF;
    
    dLon = RADIANS(lon2 - lon1);
    dLat = RADIANS(lat2 - lat1);
    
    a = SIN(dLat/2) * SIN(dLat/2) +
        COS(RADIANS(lat1)) * COS(RADIANS(lat2)) *
        SIN(dLon/2) * SIN(dLon/2);
    
    c = 2 * ATAN2(SQRT(a), SQRT(1-a));
    RETURN earth_radius * c;
END;
$$ LANGUAGE plpgsql;

-- ============================================================================
-- FUNCTION: Kiểm tra trùng lặp tức thời (Duplicate Detection)
-- trả về tất cả các outlet trùng với tiêu chí phone/zalo/tax/id_card/GPS
-- ============================================================================

CREATE OR REPLACE FUNCTION fn_check_duplicate_outlet(
    p_phone VARCHAR(20),
    p_zalo_phone VARCHAR(20),
    p_tax_code VARCHAR(50),
    p_identity_card VARCHAR(50),
    p_latitude DOUBLE PRECISION,
    p_longitude DOUBLE PRECISION,
    p_radius_meters DOUBLE PRECISION DEFAULT 20
) RETURNS TABLE (
    outlet_id BIGINT,
    outlet_code VARCHAR(100),
    outlet_name VARCHAR(255),
    field_name VARCHAR(50),
    match_type VARCHAR(20)
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        o.id, o.code, o.name, 'phone'::VARCHAR(50), 'exact'::VARCHAR(20)
    FROM tblOutlets o
    WHERE (o.phone = p_phone OR o.zalo_phone = p_zalo_phone) AND o.delete_flg = '0'
    
    UNION ALL
    
    SELECT 
        o.id, o.code, o.name, 'tax_code'::VARCHAR(50), 'exact'::VARCHAR(20)
    FROM tblOutlets o
    WHERE o.tax_code = p_tax_code AND o.delete_flg = '0'
    
    UNION ALL
    
    SELECT 
        o.id, o.code, o.name, 'identity_card'::VARCHAR(50), 'exact'::VARCHAR(20)
    FROM tblOutlets o
    WHERE o.identity_card_number = p_identity_card AND o.delete_flg = '0'
    
    UNION ALL
    
    SELECT 
        o.id, o.code, o.name, 'gps'::VARCHAR(50), 'distance'::VARCHAR(20)
    FROM tblOutlets o
    WHERE fn_haversine_distance(p_longitude, p_latitude, o.longitude, o.latitude) <= p_radius_meters
      AND o.delete_flg = '0';
END;
$$ LANGUAGE plpgsql;