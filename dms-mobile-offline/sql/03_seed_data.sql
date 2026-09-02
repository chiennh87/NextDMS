-- ============================================================================
-- SEED DATA (Phần 3)
-- ============================================================================

-- Insert ValueSet
INSERT INTO tblValueSet (value_set_code, value_set_name, description, created_by) VALUES
('CUSTOMER_TYPE', 'Loại cửa hàng', 'Phân loại cửa hàng theo LEVEL', 1),
('CUSTOMER_CHANNEL', 'Kênh bán hàng', 'Kênh phân phối sản phẩm', 1),
('TIER', 'Phân hạng điểm bán', 'Cấp độ điểm bán', 1),
('STATUS', 'Trạng thái', 'Trạng thái đơn đăng ký', 1),
('BUSINESS_TYPE', 'Hình thức kinh doanh', 'Doanh nghiệp hoặc hộ kinh doanh', 1)
ON CONFLICT (value_set_code) DO NOTHING;

-- Insert ValueSetValue: CUSTOMER_TYPE (NONE, Level 1 -> Level 5)
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('CUSTOMER_TYPE', 'NONE', 'Không phân loại', 0, 0, 1),
('CUSTOMER_TYPE', 'LEVEL_1', 'Level 1', 1, 10, 1),
('CUSTOMER_TYPE', 'LEVEL_2', 'Level 2', 2, 20, 1),
('CUSTOMER_TYPE', 'LEVEL_3', 'Level 3', 3, 30, 1),
('CUSTOMER_TYPE', 'LEVEL_4', 'Level 4', 4, 40, 1),
('CUSTOMER_TYPE', 'LEVEL_5', 'Level 5', 5, 50, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: CUSTOMER_CHANNEL (GT, MT, EC)
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('CUSTOMER_CHANNEL', 'GT', 'Truyền thống', 1, 10, 1),
('CUSTOMER_CHANNEL', 'MT', 'Hiện đại', 2, 20, 1),
('CUSTOMER_CHANNEL', 'EC', 'Thương mại điện tử', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: TIER
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('TIER', 'GOLD', 'Vàng', 1, 10, 1),
('TIER', 'SILVER', 'Bạc', 2, 20, 1),
('TIER', 'BRONZE', 'Bronze', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: STATUS
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('STATUS', 'PENDING_VERIFICATION', 'Chờ xác thực', 1, 10, 1),
('STATUS', 'ACTIVE', 'Hoạt động', 2, 20, 1),
('STATUS', 'REJECTED', 'Từ chối', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: BUSINESS_TYPE
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('BUSINESS_TYPE', 'DOANH_NGHIEP', 'Doanh nghiệp', 1, 10, 1),
('BUSINESS_TYPE', 'HOP_KINH_DOANH', 'Hộ kinh doanh', 2, 20, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- ============================================================================
-- INSERT MẪU DISTRICTS & WARDS (với địa chỉ thực tế Việt Nam)
-- ============================================================================

-- Insert sample provinces
INSERT INTO tblProvince (province_code, province_name, created_by) VALUES
('HN', 'Hà Nội', 1),
('HCM', 'Hồ Chí Minh', 1),
('DN', 'Đà Nẵng', 1)
ON CONFLICT (province_code) DO NOTHING;

-- Insert sample districts
INSERT INTO tblDistrict (province_code, district_code, district_name, created_by) VALUES
('HN', 'Q_HOAN_KIEM', 'Quận Hoàn Kiếm', 1),
('HN', 'Q_BA_DINH', 'Quận Ba Đình', 1),
('HCM', 'Q_1', 'Quận 1', 1),
('HCM', 'Q_3', 'Quận 3', 1),
('DN', 'Q_HAI_CHAU', 'Quận Hải Châu', 1)
ON CONFLICT (district_code) DO NOTHING;

-- Insert sample wards
INSERT INTO tblWard (district_code, ward_code, ward_name, street_number, street_name, created_by) VALUES
('Q_HOAN_KIEM', 'PH_OLD_QUARTER', 'Phường Phố Cổ', '123', 'Đinh Tiên Hoàng', 1),
('Q_BA_DINH', 'PH_THA_THANH', 'Phường Thạch Thán', '45', 'Điện Biên Phủ', 1),
('Q_1', 'PH_BEN_NGHE', 'Phường Bến Nghé', '100', 'Nguyễn Huệ', 1),
('Q_3', 'PH_NGUYEN_THI_MINH_KHAI', 'Phường Nguyễn Thị Minh Khai', 200, 'Nguyễn Thị Minh Khai', 1),
('Q_HAI_CHAU', 'PH_HAI_CHAU_1', 'Phường Hải Châu 1', 50, 'Trần Phú', 1)
ON CONFLICT (ward_code) DO NOTHING;

-- Verify
SELECT '✅ Seed data completed' AS status;