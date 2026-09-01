-- Migration V2: SKUs table with units, pricing, and inventory management

-- =====================================================
-- Table: skus (Stock Keeping Units - Products)
-- Product catalog with units, pricing, and logistics data
-- =====================================================
CREATE TABLE IF NOT EXISTS skus (
    sku_id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sku_code VARCHAR(30) NOT NULL UNIQUE,
    sku_name VARCHAR(200) NOT NULL,
    description TEXT,
    category VARCHAR(100),
    subcategory VARCHAR(100),
    brand VARCHAR(100),
    unit_of_measure VARCHAR(20) NOT NULL,
    weight_kg DECIMAL(8,3),
    volume_liter DECIMAL(8,3),
    base_price DECIMAL(12,2) NOT NULL,
    currency VARCHAR(3) DEFAULT 'VND',
    tax_rate DECIMAL(5,4) DEFAULT 0.0,
    reorder_point INTEGER DEFAULT 0,
    max_stock_level INTEGER DEFAULT 0,
    is_perishable BOOLEAN DEFAULT FALSE,
    shelf_life_days INTEGER,
    requires_refrigeration BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    is_discontinued BOOLEAN DEFAULT FALSE,
    discontinuation_date DATE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    updated_by UUID,
    version INTEGER DEFAULT 1,
    CHECK (base_price >= 0),
    CHECK (weight_kg >= 0),
    CHECK (volume_liter >= 0),
    CHECK (tax_rate >= 0 AND tax_rate <= 1),
    CHECK (shelf_life_days IS NULL OR shelf_life_days >= 0)
);

-- Indexes for skus
CREATE INDEX IF NOT EXISTS idx_skus_code ON skus(sku_code);
CREATE INDEX IF NOT EXISTS idx_skus_name ON skus(sku_name);
CREATE INDEX IF NOT EXISTS idx_skus_category ON skus(category);
CREATE INDEX IF NOT EXISTS idx_skus_brand ON skus(brand);
CREATE INDEX IF NOT EXISTS idx_skus_unit ON skus(unit_of_measure);
CREATE INDEX IF NOT EXISTS idx_skus_active ON skus(is_active) WHERE is_active = TRUE;
CREATE INDEX IF NOT EXISTS idx_skus_perishable ON skus(is_perishable) WHERE is_perishable = TRUE;
CREATE INDEX IF NOT EXISTS idx_skus_updated ON skus(updated_at);
CREATE INDEX IF NOT EXISTS idx_skus_price ON skus(base_price);

DROP TRIGGER IF EXISTS update_skus_updated_at ON skus;
CREATE TRIGGER update_skus_updated_at
    BEFORE UPDATE ON skus
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();