## Mục Tiêu
- Hết lỗi [cloud_firestore/permission-denied] khi admin duyệt/ẩn/xóa bài.
- Bảng tin chỉ hiển thị bài đã duyệt, member quản lý bài của mình.
- iOS Simulator chạy ổn, Xcode không còn cảnh báo “No such module 'Flutter'”.

## Bước 1: Cập nhật Firestore Rules
1. Mở Firebase Console → Firestore Database → Rules.
2. Dán và Publish đoạn rules:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid)).data.role == 'admin';
    }
    match /users/{userId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
    }
    match /posts/{postId} {
      allow read: if resource.data.isApproved == true ||
                  (request.auth != null && (resource.data.ownerId == request.auth.uid || isAdmin()));
      allow create: if request.auth != null && request.resource.data.ownerId == request.auth.uid;
      allow update, delete: if request.auth != null && (resource.data.ownerId == request.auth.uid || isAdmin());
    }
    match /favorites/{favoriteId} {
      allow read, write: if request.auth != null &&
                         (request.auth.uid == request.resource.data.userId || request.auth.uid == resource.data.userId);
    }
    match /reviews/{reviewId} {
      allow read: if true;
      allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
      allow update, delete: if request.auth != null && (request.auth.uid == resource.data.userId || isAdmin());
    }
  }
}
```
3. Nếu Firestore yêu cầu composite index cho truy vấn (`isAvailable`, `isApproved`, `createdAt`), tạo index theo link gợi ý.

## Bước 2: Xác nhận tài khoản admin
1. Kiểm tra `users/{uid}` của email admin:
   - Có `role: 'admin'` (nếu thiếu, tạo/sửa doc với `userId`, `email`, `name`, `role: 'admin'`).
2. Đảm bảo email admin nằm trong `adminEmails` của app.
3. Đăng xuất và đăng nhập lại bằng email admin để app đồng bộ vai trò.

## Bước 3: Kiểm tra dữ liệu bài viết
1. Mở một doc trong `posts`:
   - Trường `ownerId` là đúng UID người đăng.
   - `isApproved: false` với bài mới, sau khi duyệt sẽ là `true`.
   - `isAvailable: true` để hiển thị khi đã duyệt.

## Bước 4: Xác minh hành vi trong app
1. Trang chủ: bài chưa duyệt không xuất hiện; bài đã duyệt hiển thị.
2. Admin Dashboard → Quản lý bài viết:
   - Bấm “Duyệt”: chuyển `isApproved` sang `true`, nhận SnackBar thành công.
   - “Ẩn/Hiện”: cập nhật `isAvailable`.
   - “Xóa”: xóa doc bài viết, nhận SnackBar xác nhận.
3. Chi tiết bài → Đánh giá:
   - Đăng nhập → gửi đánh giá, thấy cập nhật tức thời trong danh sách.

## Bước 5: Sửa cảnh báo Xcode (chỉ index)
1. Mở đúng workspace: `ios/Runner.xcworkspace`.
2. `cd ios && pod install` (Apple Silicon: `arch -arm64 pod install`).
3. Xóa DerivedData: Xcode → Settings → Locations → DerivedData → Delete.
4. Product → Clean Build Folder → chọn Simulator → Run.

## Bước 6: Chạy lại trên Simulator (xác nhận end-to-end)
1. CLI: `flutter run -d ios` (Simulator đã khởi chạy).
2. Thực hiện: đăng nhập admin → duyệt/ẩn/xóa bài → đăng xuất → đăng nhập member → quản lý bài của mình.
3. Ghi nhận nếu còn lỗi permission để điều chỉnh rules hoặc dữ liệu tương ứng.

## Lưu ý Bảo mật
- Giữ quyền ghi chặt chẽ: chỉ chủ bài hoặc admin mới update/delete.
- Cho phép đọc `users` công khai để app tải tên chủ bài mà không đòi hỏi đăng nhập.

## Kết quả mong đợi
- Không còn `permission-denied` khi admin thao tác.
- Bài viết chỉ hiển thị khi đã duyệt.
- iOS Simulator build ổn; cảnh báo module Flutter biến mất sau khi dùng workspace và dọn DerivedData.
