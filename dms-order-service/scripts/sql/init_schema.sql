-- Database Schema for FMCG DMS (Order Service)
-- PostgreSql version 15+ 

-- 1. Bảng Outlets (Điểm bán)
CREATE TABLE IF NOT EXISTS outlets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL, -- Mã duy nhất của POS (ERP code)
    name VARCHAR(255) NOT NULL,
    address TEXT,
    gps_lat DOUBLE PRECISION,           -- Vĩ độ GPS
    gps_long DOUBLE PRECISION,          -- Kinh độ GPS
    channel_type VARCHAR(50), -- GT (General Trade), MT (Modern Trade)
    region_id VARCHAR(50),
    owner_name VARCHAR(100),
    phone VARCHAR(20),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index cho tìm kiếm tọa độ (Geo-fencing) - sử dụng b-tree đơn giản
CREATE INDEX IF NOT EXISTS idx_outlets_gps ON outlets (gps_lat, gps_long);
CREATE INDEX IF NOT EXISTS idx_outlets_code ON outlets(code);

-- 2. Bảng SKUs (Sản phẩm & Giá)
CREATE TABLE IF NOT EXISTS skus (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    barcode VARCHAR(100),
    uom VARCHAR(20) NOT NULL, -- Unit of Measure (Thùng, Chai, Gói)
    base_price DECIMAL(18, 2) NOT NULL DEFAULT 0,
    category_id VARCHAR(50),
    brand_id VARCHAR(50),
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_skus_code ON skus(code);

-- 3. Bảng Master Routes (Tuyến bán hàng MCP)
CREATE TABLE IF NOT EXISTS master_routes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    code VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    salesman_id UUID NOT NULL, -- ID của nhân viên bán hàng phụ trách
    visit_frequency VARCHAR(20), -- F1 (1 lần/tuần), F2...
    days_of_week INT[] NOT NULL, -- [1, 3, 5] (Thứ 2, 4, 6)
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng trung gian Route - Outlet (Thứ tự viếng thăm trong tuyến)
CREATE TABLE IF NOT EXISTS route_outlets (
    route_id UUID REFERENCES master_routes(id),
    outlet_id UUID REFERENCES outlets(id),
    visit_sequence INT, -- Thứ tự viếng thăm trong ngày
    PRIMARY KEY (route_id, outlet_id)
);

-- 4. Bảng Orders (Bảng chính cho nghiệp vụ đặt hàng)
CREATE TABLE IF NOT EXISTS orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_number VARCHAR(50) UNIQUE NOT NULL,
    salesman_id UUID NOT NULL,
    outlet_id UUID REFERENCES outlets(id),
    total_amount DECIMAL(18, 2) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18, 2) DEFAULT 0,
    final_amount DECIMAL(18, 2) NOT NULL,
    order_date DATE DEFAULT CURRENT_DATE,
    gps_lat DOUBLE PRECISION,
    gps_long DOUBLE PRECISION,
    status VARCHAR(20) DEFAULT 'PENDING', -- PENDING, CONFIRMED, SHIPPED, CANCELLED
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Partitioning orders theo tháng (Ví dụ)
-- Chú ý: Việc partitioning thực tế cần cấu hình cụ thể hơn tùy phiên bản PG
CREATE INDEX IF NOT EXISTS idx_orders_salesman_date ON orders(salesman_id, order_date);
CREATE INDEX IF NOT EXISTS idx_orders_outlet_id ON orders(outlet_id);

-- 5. Bảng Order Items (Chi tiết đơn hàng)
CREATE TABLE IF NOT EXISTS order_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_id UUID REFERENCES orders(id) ON DELETE CASCADE,
    sku_id UUID REFERENCES skus(id),
    quantity INT NOT NULL,
    price_at_order DECIMAL(18, 2) NOT NULL,
    total_price DECIMAL(18, 2) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_order_items_order_id ON order_items(order_id);
