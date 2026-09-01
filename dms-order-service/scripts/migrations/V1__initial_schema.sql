-- Migration V1: Initial schema for master data
-- This creates the core master data tables for FMCG DMS

-- Enable PostGIS extension for GPS coordinate support
CREATE EXTENSION IF NOT EXISTS postgis;

-- Function: Update updated_at column automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- =====================================================
-- Table: outlets (Points of Sale)
-- 100,000+ retail locations with GPS coordinates
-- =====================================================
CREATE TABLE IF NOT EXISTS outlets (
    outlet_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    outlet_code VARCHAR(20) NOT NULL UNIQUE,
    outlet_name VARCHAR(200) NOT NULL,
    outlet_type VARCHAR(50),
    address_line1 VARCHAR(255),
    address_line2 VARCHAR(255),
    city VARCHAR(100),
    district VARCHAR(100),
    province VARCHAR(100),
    postal_code VARCHAR(20),
    country VARCHAR(50) DEFAULT 'Vietnam',
    phone_number VARCHAR(20),
    email VARCHAR(100),
    contact_person VARCHAR(100),
    contact_phone VARCHAR(20),
    gps_location GEOGRAPHY(POINT, 4326),
    is_active BOOLEAN DEFAULT TRUE,
    is_blocked BOOLEAN DEFAULT FALSE,
    blocked_reason TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    version INTEGER DEFAULT 1
);

-- Indexes for outlets
CREATE INDEX IF NOT EXISTS idx_outlets_code ON outlets(outlet_code);
CREATE INDEX IF NOT EXISTS idx_outlets_name ON outlets(outlet_name);
CREATE INDEX IF NOT EXISTS idx_outlets_city ON outlets(city);
CREATE INDEX IF NOT EXISTS idx_outlets_province ON outlets(province);
CREATE INDEX IF NOT EXISTS idx_outlets_district ON outlets(district);
CREATE INDEX IF NOT EXISTS idx_outlets_active ON outlets(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_outlets_location ON outlets USING GIST (gps_location);
CREATE INDEX IF NOT EXISTS idx_outlets_updated ON outlets(updated_at);

DROP TRIGGER IF EXISTS update_outlets_updated_at ON outlets;
CREATE TRIGGER update_outlets_updated_at
    BEFORE UPDATE ON outlets
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();