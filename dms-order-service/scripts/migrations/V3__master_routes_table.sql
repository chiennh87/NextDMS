-- Migration V3: Master Routes table for MCP (Mobile Sales Person) routes

-- =====================================================
-- Table: master_routes (MCP Routes - Salesman Routes)
-- Predefined delivery routes for Mobile Sales Persons
-- =====================================================
CREATE TABLE IF NOT EXISTS master_routes (
    route_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    route_code VARCHAR(20) NOT NULL UNIQUE,
    route_name VARCHAR(200) NOT NULL,
    description TEXT,
    salesman_id UUID NOT NULL,
    district VARCHAR(100),
    province VARCHAR(100),
    route_stops JSONB NOT NULL,
    total_distance_km DECIMAL(8,2),
    estimated_duration_minutes INTEGER,
    is_active BOOLEAN DEFAULT TRUE,
    effective_from DATE,
    effective_to DATE,
    frequency VARCHAR(20),
    visit_day_of_week INTEGER[],
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    version INTEGER DEFAULT 1,
    CHECK (total_distance_km >= 0),
    CHECK (estimated_duration_minutes >= 0)
);

-- Indexes for master_routes
CREATE INDEX IF NOT EXISTS idx_routes_code ON master_routes(route_code);
CREATE INDEX IF NOT EXISTS idx_routes_name ON master_routes(route_name);
CREATE INDEX IF NOT EXISTS idx_routes_salesman ON master_routes(salesman_id);
CREATE INDEX IF NOT EXISTS idx_routes_district ON master_routes(district);
CREATE INDEX IF NOT EXISTS idx_routes_province ON master_routes(province);
CREATE INDEX IF NOT EXISTS idx_routes_active ON master_routes(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_routes_frequency ON master_routes(frequency);
CREATE INDEX IF NOT EXISTS idx_routes_updated ON master_routes(updated_at);
CREATE INDEX IF NOT EXISTS idx_routes_stops ON master_routes USING GIN (route_stops);

DROP TRIGGER IF EXISTS update_master_routes_updated_at ON master_routes;
CREATE TRIGGER update_master_routes_updated_at
    BEFORE UPDATE ON master_routes
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Add comments for documentation
COMMENT ON TABLE master_routes IS 'Predefined delivery routes for MCP sales representatives';
COMMENT ON COLUMN master_routes.route_stops IS 'JSON array of outlet_ids defining the visit sequence';