-- ============================================================================
-- SEED DATA (Ph???n 3)
-- ============================================================================

-- Insert ValueSet
INSERT INTO tblValueSet (value_set_code, value_set_name, description, created_by) VALUES
('CUSTOMER_TYPE', 'Lo???i c???a h??ng', 'Ph??n lo???i c???a h??ng theo LEVEL', 1),
('CUSTOMER_CHANNEL', 'K??nh b??n h??ng', 'K??nh ph??n ph???i s???n ph???m', 1),
('TIER', 'Ph??n h???ng ??i???m b??n', 'C???p ????? ??i???m b??n', 1),
('STATUS', 'Tr???ng th??i', 'Tr???ng th??i ????n ????ng k??', 1),
('BUSINESS_TYPE', 'H??nh th???c kinh doanh', 'Doanh nghi???p ho???c h??? kinh doanh', 1)
ON CONFLICT (value_set_code) DO NOTHING;

-- Insert ValueSetValue: CUSTOMER_TYPE (NONE, Level 1 -> Level 5)
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('CUSTOMER_TYPE', 'NONE', 'Kh??ng ph??n lo???i', 0, 0, 1),
('CUSTOMER_TYPE', 'LEVEL_1', 'Level 1', 1, 10, 1),
('CUSTOMER_TYPE', 'LEVEL_2', 'Level 2', 2, 20, 1),
('CUSTOMER_TYPE', 'LEVEL_3', 'Level 3', 3, 30, 1),
('CUSTOMER_TYPE', 'LEVEL_4', 'Level 4', 4, 40, 1),
('CUSTOMER_TYPE', 'LEVEL_5', 'Level 5', 5, 50, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: CUSTOMER_CHANNEL (GT, MT, EC)
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('CUSTOMER_CHANNEL', 'GT', 'Truy???n th???ng', 1, 10, 1),
('CUSTOMER_CHANNEL', 'MT', 'Hi???n ?????i', 2, 20, 1),
('CUSTOMER_CHANNEL', 'EC', 'Th????ng m???i ??i???n t???', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: TIER
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('TIER', 'GOLD', 'V??ng', 1, 10, 1),
('TIER', 'SILVER', 'B???c', 2, 20, 1),
('TIER', 'BRONZE', 'Bronze', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: STATUS
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('STATUS', 'PENDING_VERIFICATION', 'Ch??? x??c th???c', 1, 10, 1),
('STATUS', 'ACTIVE', 'Ho???t ?????ng', 2, 20, 1),
('STATUS', 'REJECTED', 'T??? ch???i', 3, 30, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- Insert ValueSetValue: BUSINESS_TYPE
INSERT INTO tblValueSetValue (value_set_code, value_code, value_name, display_order, sort_order, created_by) VALUES
('BUSINESS_TYPE', 'DOANH_NGHIEP', 'Doanh nghi???p', 1, 10, 1),
('BUSINESS_TYPE', 'HOP_KINH_DOANH', 'H??? kinh doanh', 2, 20, 1)
ON CONFLICT (value_set_code, value_code) DO NOTHING;

-- ============================================================================
-- INSERT M???U DISTRICTS & WARDS (v???i ?????a ch??? th???c t??? Vi???t Nam)
-- ============================================================================

-- Insert sample provinces
INSERT INTO tblProvince (province_code, province_name, created_by) VALUES
('HN', 'H?? N???i', 1),
('HCM', 'H??? Ch?? Minh', 1),
('DN', '???? N???ng', 1)
ON CONFLICT (province_code) DO NOTHING;

-- Insert sample districts
INSERT INTO tblDistrict (province_code, district_code, district_name, created_by) VALUES
('HN', 'Q_HOAN_KIEM', 'Qu???n Ho??n Ki???m', 1),
('HN', 'Q_BA_DINH', 'Qu???n Ba ????nh', 1),
('HCM', 'Q_1', 'Qu???n 1', 1),
('HCM', 'Q_3', 'Qu???n 3', 1),
('DN', 'Q_HAI_CHAU', 'Qu???n H???i Ch??u', 1)
ON CONFLICT (district_code) DO NOTHING;

-- Insert sample wards
INSERT INTO tblWard (district_code, ward_code, ward_name, street_number, street_name, created_by) VALUES
('Q_HOAN_KIEM', 'PH_OLD_QUARTER', 'Ph?????ng Ph??? C???', '123', '??inh Ti??n Ho??ng', 1),
('Q_BA_DINH', 'PH_THA_THANH', 'Ph?????ng Th???ch Th??n', '45', '??i???n Bi??n Ph???', 1),
('Q_1', 'PH_BEN_NGHE', 'Ph?????ng B???n Ngh??', '100', 'Nguy???n Hu???', 1),
('Q_3', 'PH_NGUYEN_THI_MINH_KHAI', 'Ph?????ng Nguy???n Th??? Minh Khai', 200, 'Nguy???n Th??? Minh Khai', 1),
('Q_HAI_CHAU', 'PH_HAI_CHAU_1', 'Ph?????ng H???i Ch??u 1', 50, 'Tr???n Ph??', 1)
ON CONFLICT (ward_code) DO NOTHING;

-- Verify
SELECT '??? Seed data completed' AS status;
