# Phân tích: Mất focus Text Field trong WebView trên Windows cảm ứng (POS Online)

## Tóm tắt vấn đề

- **Hiện tượng:** Trên **Windows có màn hình cảm ứng**, text field bên trong WebView (POS Online) bị **mất focus**. Trên **Windows dùng chuột thông thường** thì không bị.
- **Ngữ cảnh:** Trang POS Online chạy trong `InAppWebView` (flutter_inappwebview); WebView có chức năng **quét/ nhập mã vạch (barcode)** (trong nội dung web), và focus vào ô nhập liệu rất quan trọng cho trải nghiệm.

---

## Cập nhật từ thực tế kiểm tra: Không phải do JS scan barcode

- **Đã kiểm chứng:** Khi **ẩn/tắt JS phần scan barcode**, vấn đề **vẫn xảy ra** trên **màn hình login** (trang web chưa có JS scan barcode).
- **Kết luận:** Nguyên nhân **không phải** do logic barcode trong web, mà là lỗi chung của **input + bàn phím ảo + focus** trong WebView trên Windows cảm ứng.

**Chuỗi sự kiện khi user bấm vào input (bất kỳ, ví dụ ô username/password trên login):**

1. User chạm vào ô input trong WebView.
2. **Bàn phím ảo (Windows touch keyboard) hiện lên.**
3. **Ngay sau đó bàn phím ảo tự ẩn đi.**
4. **Focus cũng bị mất** (ô input không còn focus, không gõ được).

→ Nghi ngờ chính: khi bàn phím ảo hiện lên, một sự kiện hoặc thay đổi layout/focus nào đó (từ Flutter, WebView, hoặc Windows) khiến bàn phím bị dismiss và focus bị clear. Cần ưu tiên tìm nguyên nhân ở **tương tác bàn phím ảo + platform view + focus** trên Windows touch.

---

## 1. Nguyên nhân có thể

### 1.1. Gesture recognizers và “gesture arena” (khả năng cao)

Trong `pos_online_page.dart` đang dùng:

```dart
gestureRecognizers: {}..addAll([
  Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
  Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
  Factory<OneSequenceGestureRecognizer>(() => EagerGestureRecognizer()),
]),
```

- **EagerGestureRecognizer:** “Eagerly claims victory in all gesture arenas” – giành thắng sớm trong mọi gesture arena và chuyển **toàn bộ** pointer events xuống view nhúng (WebView). Mục đích là để scroll/touch trong WebView hoạt động.
- **VerticalDragGestureRecognizer / HorizontalDragGestureRecognizer:** Dùng để scroll (kéo dọc/ngang) trong WebView.

**Vì sao dễ gây mất focus trên touch:**

- Trên **touch**, một lần chạm có thể vừa được coi là “tap” (để focus vào input) vừa là “drag” (để scroll). Cả Flutter (drag recognizers) và Eager (chuyển event xuống WebView) cùng tham gia **gesture arena**.
- Trên **Windows cảm ứng**, thứ tự/phân loại pointer (touch vs mouse) có thể khác với môi trường chỉ chuột. Kết quả có thể là:
  - Flutter layer “giành” event (ví dụ coi là drag) → event không tới WebView đúng cách → **focus không được set hoặc bị clear**.
  - Hoặc event tới WebView muộn/khác đi sau khi Flutter đã xử lý, dẫn tới focus bị mất hoặc không ổn định.

Trên **Windows chỉ chuột**, hành vi pointer ổn định hơn (click rõ ràng là click), nên ít xảy ra conflict và focus thường giữ được.

---

### 1.2. Khác biệt Touch vs Mouse trên Windows (platform view)

- Flutter có **platform view** (WebView là native view nhúng vào Flutter). Trên Windows đã có báo cáo: **touch events không hoạt động đúng giữa PlatformView và Flutter widgets** (ví dụ issue #116023).
- Trên **touch**, event có thể:
  - Bị Flutter xử lý trước thay vì chuyển thẳng xuống WebView.
  - Hoặc focus được quản lý khác (focus có thể bị lấy về Flutter hoặc không được set đúng cho phần tử trong WebView).

Kết hợp với gesture recognizers ở trên, môi trường **Windows cảm ứng** dễ làm focus trong WebView bị ảnh hưởng.

---

### 1.3. Bàn phím ảo hiện rồi ẩn ngay + mất focus (nghi ngờ chính sau khi kiểm tra)

- **Hiện tượng:** Bấm vào input → bàn phím ảo hiện → **ngay sau đó ẩn** → focus mất. Xảy ra cả trên màn login (không có JS barcode).
- **Khả năng cao:** Khi bàn phím ảo **xuất hiện**, một trong các việc sau xảy ra và gây ra chuỗi "ẩn bàn phím + mất focus":
  - **Layout thay đổi** (view bị đẩy lên / resize) → Flutter hoặc WebView rebuild/relayout → focus bị clear hoặc chuyển về Flutter/OS.
  - **Một pointer/focus event thứ hai** được kích hoạt (ví dụ do gesture recognizer hoặc hit-test sau khi keyboard show) → hệ thống coi như "tap ra ngoài" → dismiss keyboard và clear focus.
  - **Windows / Flutter** trên tablet mode xử lý focus cho platform view chưa đúng: khi keyboard show, focus có thể bị lấy lại khỏi WebView (Flutter issues #99050, #97269, #36057).
- Cần ưu tiên tìm workaround hoặc fix ở phía **bàn phím ảo + focus trong platform view (WebView)** trên Windows cảm ứng.

---

### 1.4. Thời điểm và luồng xử lý focus

- **EagerGestureRecognizer** chuyển event xuống WebView ngay. Tuy vậy, trên touch có thể có thêm lớp xử lý (hit test, focus scope) ở Flutter hoặc Windows.
- Nếu bất kỳ bước nào trong luồng đó **clear focus** hoặc **chuyển focus** sang widget Flutter (hoặc không set focus cho element trong WebView), user sẽ thấy “mất focus” dù đang tap vào ô nhập barcode trong WebView.

---

## 2. Liên quan tới Barcode trong WebView

- Trong POS Online, **barcode** được xử lập **trong nội dung web** (input trong WebView), không phải native Flutter (như `barcode_scan2` ở màn hình POS offline).
- Text field nhận barcode (hoặc nhập tay) nằm **bên trong WebView**. Mất focus ở đây nghĩa là:
  - User chạm vào ô nhập → focus không giữ hoặc bị mất ngay.
  - Ảnh hưởng trực tiếp tới việc quét/ nhập mã vạch trên màn hình POS Online.

---

## 3. Hướng xử lý / Giảm thiểu gợi ý

1. **Ưu tiên: Bàn phím ảo + focus**
   - Vì chuỗi rõ ràng là "keyboard hiện → ẩn ngay → mất focus", nên thử: (a) tắt/giảm ảnh hưởng của layout khi keyboard show (ví dụ `resizeToAvoidBottomInset` hoặc tương đương cho WebView); (b) tìm trong Flutter/Windows có option giữ focus trong platform view khi soft keyboard mở; (c) tra issue flutter_inappwebview + Windows + keyboard/focus.
   - Có thể thử tạm **bỏ hết** `gestureRecognizers` (hoặc chỉ để Eager) để xem có phải event thứ hai do gesture gây dismiss keyboard + mất focus không.

2. **Thử điều chỉnh gesture recognizers**
   - Thử **bỏ** `VerticalDragGestureRecognizer` và `HorizontalDragGestureRecognizer`, chỉ giữ `EagerGestureRecognizer` (nếu scroll trong WebView vẫn đủ dùng).
   - Hoặc thử **chỉ dùng** `EagerGestureRecognizer` và kiểm tra xem focus trên Windows touch có cải thiện không.

3. **Phân biệt thiết bị (touch vs không touch)**
   - Trên Windows, có thể detect touch (ví dụ `PointerDeviceKind.touch`) và dùng bộ gesture recognizers **khác** cho touch (ít “ăn” event hơn) so với chuột.

4. **Cấu hình InAppWebView (nếu có tuỳ chọn)**
   - Kiểm tra tài liệu / options của `flutter_inappwebview` cho Windows về:
     - Focus behavior.
     - Transparent background / input focus.
   - Áp dụng nếu có option giúp focus luôn nằm trong WebView khi tương tác với input.

5. **Cập nhật Flutter / engine**
   - Các issue liên quan touch + platform view / focus trên Windows có thể đã được cải thiện ở bản Flutter mới. Nên chạy thử trên channel/bản Flutter mới nhất hỗ trợ Windows.

6. **Báo lỗi / tìm workaround**
   - Nếu xác định đúng là do Flutter hoặc flutter_inappwebview trên Windows touch, có thể tìm workaround trên GitHub (flutter/flutter, pichillilorenzo/flutter_inappwebview) hoặc báo issue kèm mô tả: Windows touch, WebView, text field focus, barcode input.

---

## 4. Tóm tắt nguyên nhân chính

| Nguyên nhân | Mô tả ngắn |
|-------------|------------|
| **Bàn phím ảo hiện rồi ẩn + mất focus** ⭐ | Đã xác nhận: xảy ra cả khi không có JS barcode (màn login). Tap input → keyboard hiện → **keyboard ẩn ngay** → focus mất. Nghi ngờ do layout/event sau khi keyboard show (Flutter/Windows/platform view). |
| **Gesture arena (Eager + Drag)** | Trên Windows touch, drag/tap có thể conflict; Flutter giành event hoặc xử lý sai → event không tới WebView đúng → mất focus. |
| **Touch vs Platform View (Windows)** | Touch events giữa Flutter và platform view trên Windows chưa hoàn hảo → focus/input trong WebView dễ bị ảnh hưởng. |
| **Luồng focus** | Eager chuyển event xuống WebView nhưng có thể vẫn có bước clear/chuyển focus (đặc biệt sau khi bàn phím ảo hiện) ở Flutter/OS. |

---

*Tài liệu tổng hợp từ review `lib/src/presentation/pages/pos_online/pos_online_page.dart` và các vấn đề đã biết về Flutter WebView, gesture, và Windows touch.*
