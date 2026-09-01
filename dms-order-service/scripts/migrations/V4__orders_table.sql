-- Migration V4: Orders and Order Items tables
-- Core transaction tables for DMS order management

-- =====================================================
-- Table: orders
-- Order header with salesman and outlet information
-- =====================================================
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) NOT NULL UNIQUE,
    salesman_id UUID NOT NULL,
    outlet_id UUID NOT NULL,
    total_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    final_amount DECIMAL(12,2) NOT NULL DEFAULT 0,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    gps_lat DOUBLE PRECISION,
    gps_long DOUBLE PRECISION,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    confirmed_at TIMESTAMPTZ,
    shipped_at TIMESTAMPTZ,
    delivered_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    cancellation_reason TEXT,
    version INTEGER DEFAULT 1,
    CONSTRAINT chk_order_status CHECK (status IN ('PENDING', 'CONFIRMED', 'SHIPPED', 'DELIVERED', 'CANCELLED'))
);

-- Indexes for orders
CREATE INDEX IF NOT EXISTS idx_orders_number ON orders(order_number);
CREATE INDEX IF NOT EXISTS idx_orders_salesman ON orders(salesman_id);
CREATE INDEX IF NOT EXISTS idx_orders_outlet ON orders(outlet_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_created_at ON orders(created_at);
CREATE INDEX IF NOT EXISTS idx_orders_salesman_date ON orders(salesman_id, created_at);

DROP TRIGGER IF EXISTS update_orders_updated_at ON orders;
CREATE TRIGGER update_orders_updated_at
    BEFORE UPDATE ON orders
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- =====================================================
-- Table: order_items
-- Individual line items within an order
-- =====================================================
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    sku_id UUID NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    unit_of_measure VARCHAR(20) NOT NULL,
    price_at_order DECIMAL(12,2) NOT NULL,
    tax_rate DECIMAL(5,4) DEFAULT 0,
    discount_amount DECIMAL(12,2) DEFAULT 0,
    total_price DECIMAL(12,2) NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CHECK (price_at_order >= 0),
    CHECK (discount_amount >= 0),
    CHECK (total_price >= 0)
);

-- Indexes for order_items
CREATE INDEX IF NOT EXISTS idx_order_items_order ON order_items(order_id);
CREATE INDEX IF NOT EXISTS idx_order_items_sku ON order_items(sku_id);
CREATE INDEX IF NOT EXISTS idx_order_items_order_sku ON order_items(order_id, sku_id);

DROP TRIGGER IF EXISTS update_order_items_updated_at ON order_items;
CREATE TRIGGER update_order_items_updated_at
    BEFORE UPDATE ON order_items
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Comments
COMMENT ON TABLE orders IS 'Order header: salesman creates order at outlet';
COMMENT ON TABLE order_items IS 'Order line items: SKU details with quantity and price';