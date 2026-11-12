# Quản lý giảng viên

Ứng dụng Flutter quản lý giảng viên trên web và thiết bị di động. Backend
Node.js/Express kết nối MongoDB; Flutter không kết nối trực tiếp tới cơ sở dữ
liệu để tránh đưa thông tin truy cập MongoDB vào ứng dụng.

## Cấu trúc

- `lib/models/`: mô hình dữ liệu giảng viên.
- `lib/services/`: hợp đồng repository và REST API client.
- `lib/screens/`: màn hình danh sách và biểu mẫu thêm/sửa.
- `lib/widgets/`: thẻ giảng viên và ảnh đại diện dùng lại.
- `backend/`: REST API, kết nối MongoDB và dữ liệu mẫu.

Collection là `QLHocPhan.GiangVien`. Mỗi bản ghi nghiệp vụ chỉ có bốn thuộc
tính `IDGV` (string), `Fullname` (string), `Image` (data URI hoặc URL) và
`SumClass` (số nguyên). Hệ thống tự tạo `IDGV` theo dạng `GV001`, `GV002`, ...
khi thêm giảng viên; mã này không được nhập hoặc thay đổi thủ công. MongoDB tự
quản lý `_id`. Ảnh tải lên được nén và lưu dưới dạng data URI trong `Image`;
giới hạn tệp là 5 MB.

## Chạy backend

Cần Node.js 20+ và MongoDB đang chạy. Từ thư mục dự án:

```powershell
cd backend
npm install
Copy-Item .env.example .env
```

Điều chỉnh `MONGODB_URI` trong `backend/.env` nếu MongoDB không chạy trên máy
cục bộ. Đặt `AUTH_USERNAME` và `AUTH_PASSWORD` cho tài khoản quản trị; tạo
`AUTH_TOKEN_SECRET` ngẫu nhiên dài ít nhất 32 ký tự. Có thể tạo secret bằng:

```powershell
node -e "console.log(require('node:crypto').randomBytes(48).toString('base64url'))"
```

Chỉ lưu các giá trị này trong `backend/.env` (không commit hoặc gửi vào ứng
dụng Flutter). Backend xác minh thông tin đăng nhập, cấp token có hạn 8 giờ và
yêu cầu token cho các API giảng viên. Tài khoản không được lưu trong MongoDB;
đăng xuất sẽ xóa token khỏi phiên ứng dụng hiện tại.

Sau đó khởi động:

```powershell
npm start
```

API mặc định chạy ở `http://localhost:3000`. Endpoint kiểm tra là
`http://localhost:3000/api/health`.

Để nạp ba bản ghi mẫu vào collection (có thể chạy lại an toàn):

```powershell
npm run seed
```

`backend/sample-data.json` là tệp JSON dữ liệu mẫu có đúng bốn trường yêu cầu.
Ảnh mẫu để trống nên giao diện hiển thị ảnh đại diện mặc định; ảnh thật có thể
thêm/chỉnh sửa trong ứng dụng.

## Chạy Flutter

Với Flutter 3.47+ và backend đang chạy:

```powershell
flutter pub get
flutter run -d chrome
```

Địa chỉ API mặc định là `http://localhost:3000/api` trên web/desktop và
`http://10.0.2.2:3000/api` trên Android Emulator. Có thể cấu hình lại khi
build/chạy:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000/api
```

Trên Android Emulator, ứng dụng tự dùng địa chỉ host `10.0.2.2` thay cho
`localhost`. Khi cần ghi đè địa chỉ:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:3000/api
```

Trên thiết bị thật, thay bằng địa chỉ IP LAN của máy chạy backend. Đảm bảo
backend và tường lửa cho phép thiết bị truy cập cổng 3000. Ứng dụng hỗ trợ
chọn ảnh từ thư viện và chụp ảnh trên thiết bị có camera.

## Kiểm tra

```powershell
flutter analyze
flutter test
```

Khi triển khai công khai, cần dùng HTTPS và cấu hình `CORS_ORIGIN` chỉ cho
phép các nguồn tin cậy.
