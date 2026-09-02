-- ============================================
-- Auth Service Database Schema
-- ============================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Bảng users
CREATE TABLE IF NOT EXISTS users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    username        VARCHAR(50) UNIQUE NOT NULL,
    phone           VARCHAR(20) UNIQUE NOT NULL,
    email           VARCHAR(100) UNIQUE,
    password_hash   VARCHAR(255) NOT NULL,
    full_name       VARCHAR(100) NOT NULL,
    employee_code   VARCHAR(50) UNIQUE NOT NULL,
    role_id         UUID NOT NULL,
    is_active       BOOLEAN DEFAULT true,
    failed_logins   INTEGER DEFAULT 0,
    locked_until    TIMESTAMPTZ,
    last_master_sync TIMESTAMPTZ,
    master_data_version VARCHAR(20) DEFAULT 'v0',
    is_deleted      BOOLEAN DEFAULT false,
    created_at      TIMESTAMPTZ DEFAULT NOW(),
    updated_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_username ON users(username);
CREATE INDEX idx_users_phone ON users(phone);
CREATE INDEX idx_users_employee_code ON users(employee_code);
CREATE INDEX idx_users_role_id ON users(role_id);

-- Bảng roles
CREATE TABLE IF NOT EXISTS roles (
    id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name        VARCHAR(50) UNIQUE NOT NULL,
    description TEXT,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

-- Bảng permissions
CREATE TABLE IF NOT EXISTS permissions (
    id    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code  VARCHAR(100) UNIQUE NOT NULL,
    name  VARCHAR(100) NOT NULL,
    module VARCHAR(50) NOT NULL
);

-- Bảng role_permissions
CREATE TABLE IF NOT EXISTS role_permissions (
    role_id        UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id  UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- Bảng user_permissions (override/addition)
CREATE TABLE IF NOT EXISTS user_permissions (
    user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id UUID NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (user_id, permission_id)
);

-- Insert default data
INSERT INTO roles (id, name, description) VALUES
  ('00000000-0000-0000-0000-000000000001', 'SALESMAN', 'Salesman role - field sales'),
  ('00000000-0000-0000-0000-000000000002', 'ADMIN', 'Admin role - full access'),
  ('00000000-0000-0000-0000-000000000003', 'MANAGER', 'Manager role - reports + team management')
ON CONFLICT DO NOTHING;

INSERT INTO permissions (id, code, name, module) VALUES
  ('11111111-0000-0000-0000-000000000001', 'order:create', 'Create Order', 'ORDER'),
  ('11111111-0000-0000-0000-000000000002', 'order:read', 'Read Order', 'ORDER'),
  ('11111111-0000-0000-0000-000000000003', 'order:update', 'Update Order', 'ORDER'),
  ('11111111-0000-0000-0000-000000000004', 'order:delete', 'Delete Order', 'ORDER'),
  ('11111111-0000-0000-0000-000000000005', 'checkin:create', 'Create Check-in', 'CHECKIN'),
  ('11111111-0000-0000-0000-000000000006', 'checkin:read', 'Read Check-in', 'CHECKIN'),
  ('11111111-0000-0000-0000-000000000007', 'report:read', 'Read Reports', 'REPORT'),
  ('11111111-0000-0000-0000-000000000008', 'user:manage', 'Manage Users', 'ADMIN')
ON CONFLICT DO NOTHING;

-- Assign permissions to roles
INSERT INTO role_permissions (role_id, permission_id)
SELECT '00000000-0000-0000-0000-000000000001', id FROM permissions WHERE code IN
  ('order:create', 'order:read', 'checkin:create', 'checkin:read')
ON CONFLICT DO NOTHING;

INSERT INTO role_permissions (role_id, permission_id)
SELECT '00000000-0000-0000-0000-000000000002', id FROM permissions
ON CONFLICT DO NOTHING;

-- Test salesman (password: "password123" - bcrypt hash)
INSERT INTO users (id, username, phone, password_hash, full_name, employee_code, role_id) VALUES
  ('22222222-0000-0000-0000-000000000001', 'salesman01', '0901234567',
   '$2a$12$LQv3c1yqBwEHxv6jK8h8SuYK1Q3bZ4Y5xH5yH5yH5yH5yH5yH5yH5y',
   'Nguyen Van A', 'NV001', '00000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;
