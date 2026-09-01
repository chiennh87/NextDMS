-- =====================================================================
-- FILE: 002_core_master_data.sql
-- MỤC ĐÍCH: Thiết kế Schema PostgreSQL cho Master Data cốt lõi
-- YÊU CẦU PHI CHỨC NĂNG: > 100,000 điểm bán, 1,000 salesman
-- LƯU Ý: GPS lưu dạng double precision (không phụ thuộc PostGIS)
-- =====================================================================

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- =====================================================================
-- 1. OUTLETS (Điểm bán)
-- =====================================================================
CREATE TABLE IF NOT EXISTS outlets (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code              VARCHAR(50)  NOT NULL,
    name              VARCHAR(255) NOT NULL,
    address           TEXT,
    province_code     VARCHAR(20),
    district_code     VARCHAR(20),
    channel_type      VARCHAR(20)  NOT NULL DEFAULT 'GT',
    region_id         UUID,
    owner_name        VARCHAR(150),
    phone             VARCHAR(20),
    gps_lat           DOUBLE PRECISION,
    gps_long          DOUBLE PRECISION,
    geofence_radius_m INT NOT NULL DEFAULT 100,
    credit_limit      NUMERIC(18, 2) NOT NULL DEFAULT 0,
    is_active         BOOLEAN NOT NULL DEFAULT TRUE,
    created_at        TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at        TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_outlets_code_active ON outlets (code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_outlets_gps ON outlets (gps_lat, gps_long) WHERE gps_lat IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_outlets_region_channel ON outlets (region_id, channel_type) WHERE is_active = TRUE;
DROP TRIGGER IF EXISTS trg_outlets_updated_at ON outlets;
CREATE TRIGGER trg_outlets_updated_at BEFORE UPDATE ON outlets FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- =====================================================================
-- 2. SKUS + đơn vị tính + giá
-- =====================================================================
CREATE TABLE IF NOT EXISTS skus (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code         VARCHAR(50)  NOT NULL,
    name         VARCHAR(255) NOT NULL,
    category_id  UUID,
    brand_id     UUID,
    base_uom     VARCHAR(20)  NOT NULL,
    is_active    BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_skus_code_active ON skus (code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_skus_category_brand ON skus (category_id, brand_id) WHERE is_active = TRUE;
DROP TRIGGER IF EXISTS trg_skus_updated_at ON skus;
CREATE TRIGGER trg_skus_updated_at BEFORE UPDATE ON skus FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TABLE IF NOT EXISTS sku_units (
    id                UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku_id            UUID NOT NULL REFERENCES skus (id) ON DELETE CASCADE,
    uom               VARCHAR(20) NOT NULL,
    conversion_factor NUMERIC(18, 4) NOT NULL DEFAULT 1,
    barcode           VARCHAR(100),
    is_base_unit      BOOLEAN NOT NULL DEFAULT FALSE,
    CONSTRAINT uq_sku_units_sku_uom UNIQUE (sku_id, uom)
);
CREATE INDEX IF NOT EXISTS idx_sku_units_barcode ON sku_units (barcode);

CREATE TABLE IF NOT EXISTS sku_prices (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku_id         UUID NOT NULL REFERENCES skus (id) ON DELETE CASCADE,
    uom            VARCHAR(20) NOT NULL,
    channel_type   VARCHAR(20),
    region_id      UUID,
    price          NUMERIC(18, 2) NOT NULL CHECK (price >= 0),
    effective_from TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    effective_to   TIMESTAMPTZ,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_sku_prices_lookup ON sku_prices (sku_id, uom, effective_from DESC);

-- =====================================================================
-- 3. MASTER_ROUTES + ROUTE_OUTLETS
-- =====================================================================
CREATE TABLE IF NOT EXISTS master_routes (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code            VARCHAR(50)  NOT NULL,
    name            VARCHAR(255) NOT NULL,
    salesman_id     UUID NOT NULL,
    visit_frequency VARCHAR(20)  NOT NULL DEFAULT 'F1',
    days_of_week    SMALLINT[]   NOT NULL DEFAULT '{}',
    is_active       BOOLEAN NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_master_routes_code_active ON master_routes (code) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_master_routes_salesman ON master_routes (salesman_id) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_master_routes_days_gin ON master_routes USING GIN (days_of_week);
DROP TRIGGER IF EXISTS trg_master_routes_updated_at ON master_routes;
CREATE TRIGGER trg_master_routes_updated_at BEFORE UPDATE ON master_routes FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TABLE IF NOT EXISTS route_outlets (
    route_id       UUID NOT NULL REFERENCES master_routes (id) ON DELETE CASCADE,
    outlet_id      UUID NOT NULL REFERENCES outlets (id) ON DELETE CASCADE,
    visit_sequence SMALLINT NOT NULL,
    PRIMARY KEY (route_id, outlet_id)
);
CREATE UNIQUE INDEX IF NOT EXISTS uq_route_outlets_sequence ON route_outlets (route_id, visit_sequence);
CREATE INDEX IF NOT EXISTS idx_route_outlets_outlet ON route_outlets (outlet_id);

