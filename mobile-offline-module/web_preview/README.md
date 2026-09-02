# Web Preview - DMS Sales Login Demo

## 🚀 Cách chạy
Cách 1: Mở file `index.html` trực tiếp bằng Chrome/Edge.

Cách 2 (khuyến nghị): Chạy local server
```
cd C:\Projects\NextDMS\NextDMS\mobile-offline-module\web_preview
python -m http.server 8000
# hoặc: npx http-server -p 8000
```
Mở: http://localhost:8000

## 🧪 Test Cases

### 1️⃣ Login Online
- Username: `sales01` | Password: `Sales@123` | Device: `DEV-001`
- Click "Đăng Nhập" → loading 1.2s → vào Home Dashboard

### 2️⃣ Login Offline (PIN)
- Tab "Offline PIN" → nhập `123456` → auto-verify → Home
- Sai PIN: hiện toast đỏ + reset

### 3️⃣ Forgot Password (3 bước)
- Từ Login, click "Quên mật khẩu?"
- **Step 1**: Email `sales01@dms.local` → "Gửi Mã OTP" → toast mock
- **Step 2**: Nhập OTP `123456` (6 boxes, auto-focus) → "Xác Nhận"
  - 60s countdown cho nút "Gửi lại OTP"
- **Step 3**: Password mới (min 8) + xác nhận
  - Strength bar: Yếu / Trung bình / Khá / Mạnh
  - Match check real-time
- Submit → Success screen → Quay lại Login

### 4️⃣ Logout (2 loại)
- Home → click avatar 👤 → Profile
- Button 1: "🚪 Đăng xuất" (chỉ thiết bị này)
- Button 2: "📱 Đăng xuất khỏi tất cả thiết bị"
- Confirm dialog → về Login

## 📁 Files
- `index.html` - UI 5 màn hình (Login, Forgot, Home, Profile)
- `style.css` - Material Design 3, mobile-first (375x667)
- `app.js` - Logic, mock API, 60s cooldown, strength checker
