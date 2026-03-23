RESTAURANT MOBILE APPLICATION

Ứng dụng di động đa nền tảng thuộc hệ thống Quản lý nhà hàng, hỗ trợ trải nghiệm gọi món không tiếp xúc và quản lý vận hành từ xa. Ứng dụng tích hợp công nghệ quét mã QR, cập nhật trạng thái đơn hàng thời gian thực và thanh toán điện tử, mang lại quy trình khép kín từ lúc khách vào bàn đến khi hoàn tất giao dịch

1. CÔNG NGHỆ SỬ DỤNG

- Framework: Flutter (Dart)
- Quản lý trạng thái (State Management): Xử lý luồng dữ liệu phức tạp giữa các màn hình và API
- Giao tiếp API: Dio / Http Client để tương tác với Backend ASP.NET Core qua chuẩn RESTful
- Real-time: Tích hợp SignalR Client (WebSockets) để nhận thông báo trạng thái món ăn và đơn hàng tức thì
- Tiện ích: QR Code Scanner, Local Storage, Image Picker

2. CÁC TÍNH NĂNG CHÍNH

- QR Ordering & Identification: Quét mã QR tại bàn để định danh vị trí và truy xuất thực đơn tương ứng
- Smart Menu: Hiển thị thực đơn trực quan, cho phép tùy chỉnh kích thước món ăn (Food Size) và thêm ghi chú yêu cầu
- Real-time Tracking: Theo dõi tiến độ chế biến món ăn từ bếp theo thời gian thực mà không cần tải lại trang
- Payment Integration: Kết nối API thanh toán Momo, VNPAY và quản lý lịch sử giao dịch ngay trên ứng dụng
- Statistics & Reports: Cung cấp biểu đồ thống kê doanh thu và tần suất đặt món (dành cho quản lý)
- Inventory Management: Phân hệ dành cho nhân viên để kiểm tra và cập nhật tình trạng kho nguyên liệu ngay tại quầy

3. CẤU TRÚC THƯ MỤC SOURCE CODE

- lib/config/: Quản lý các biến môi trường, định nghĩa URL API và các thiết lập chung
- lib/models/: Định nghĩa cấu trúc dữ liệu (Data Classes) phục vụ việc mapping JSON từ API
- lib/screen/: Chứa mã nguồn giao diện được module hóa theo tính năng:
    - order/ & payment/: Xử lý luồng đặt món và thanh toán.
    - menu/ & menu_category/: Hiển thị và phân loại thực đơn. 
    - table/: Quản lý sơ đồ và trạng thái bàn ăn. 
    - statistics/: Xử lý logic hiển thị số liệu và biểu đồ. 
    - inventory/: Giao diện quản lý kho và nguyên liệu. 
    - login_register/: Hệ thống xác thực và quản lý tài khoản người dùng.
