# Kế hoạch: WebView2 Composition Controller & xử lý focus/touch trên Windows

## 1. Tổng quan vấn đề

- **Hiện tượng:** Khi dùng WebView2 trong app (POS Online / InAppWebView), WebView2 tạo **một child HWND** và child này **liên tục giành focus** với main window.
- **Hệ quả:** Main window mất focus; với **chuột** có thể click lại để lấy focus, nhưng với **màn hình cảm ứng (touch)** người dùng phải nhấn nhiều lần mới lấy lại được focus.
- **Liên quan:** Xem thêm [pos_online_webview_focus_touch_windows.md](./pos_online_webview_focus_touch_windows.md) (bàn phím ảo hiện rồi ẩn, mất focus trên Windows cảm ứng).

---

## 2. Phân tích package `flutter_inappwebview_windows`

### 2.1 Hai cách tạo WebView2 trên Windows

| Cách tạo | API | Child HWND? | Dùng khi nào trong package |
|----------|-----|-------------|----------------------------|
| **Controller** | `CreateCoreWebView2Controller(hwnd, ...)` | **Có** – WebView2 tạo một child HWND bên trong `hwnd` | `willBeSurface == false`: InAppBrowser, Headless |
| **Composition Controller** | `CreateCoreWebView2CompositionController(parentWindow, ...)` | **Không** – không tạo child HWND; vẽ qua composition, input qua host | `willBeSurface == true`: **InAppWebView nhúng trong Flutter (platform view)** |

### 2.2 Luồng tạo WebView hiện tại (embedded view)

Trong `in_app_webview_manager.cpp`, khi tạo InAppWebView nhúng trong Flutter:

```cpp
InAppWebView::createInAppWebViewEnv(hwnd, true, ...);  // willBeSurface = true
```

Trong `in_app_webview.cpp` → `createInAppWebViewEnv()`:

- Nếu `willBeSurface && (webViewEnv10 || webViewEnv3)`:
  - Gọi **CreateCoreWebView2CompositionControllerWithOptions** hoặc **CreateCoreWebView2CompositionController**.
  - WebView **không** tạo child HWND; nội dung gắn vào cây visual qua `put_RootVisualTarget(...)` (Windows.UI.Composition).
  - Chuột/touch được chuyển vào WebView qua `SendMouseInput` / `SendPointerInput`.
- Nếu không (thiếu Environment3/10 hoặc không phải surface):
  - Fallback sang **CreateCoreWebView2Controller** → khi đó WebView2 **sẽ tạo child HWND** và dễ gây tranh focus.

**Kết luận:** Với **embedded InAppWebView (platform view)**, package **đã dùng Composition Controller** khi runtime hỗ trợ `ICoreWebView2Environment3` (hoặc 10). Khi đó **WebView2 không tạo child HWND**. Child HWND duy nhất trong sơ đồ là **cửa sổ host** do plugin tạo bằng `CreateWindowEx(..., parentFlutterView, ...)` trong `createInAppWebView` – đây là con của Flutter view, **không** phải do WebView2 tạo.

---

## 3. CreateCoreWebView2CompositionController – tài liệu Microsoft

- **ICoreWebView2CompositionController** mở rộng **ICoreWebView2Controller**, dùng cho **visual hosting**.
- **Khác biệt quan trọng:** Object implement **ICoreWebView2CompositionController** **không** tạo window con; host app:
  - Kết nối WebView vào cây visual của app qua **RootVisualTarget** (IDCompositionVisual hoặc Windows::UI::Composition::ContainerVisual).
  - Tự xử lý **input** (chuột, touch, pen) và gửi vào WebView qua **SendMouseInput** / **SendPointerInput**.
  - **Focus** được quản lý ở phía host (cửa sổ chính hoặc cửa sổ host), không có HWND riêng của WebView để tranh focus.

Tài liệu: [ICoreWebView2CompositionController](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2compositioncontroller).

---

## 4. Đánh giá tính khả thi

### 4.1 Đã đúng hướng

- **Embedded WebView (trong Flutter)** đã dùng **Composition Controller** khi có Environment3/10 → WebView2 **không** tạo child HWND trong trường hợp này.
- Package đã có:
  - `put_RootVisualTarget` để gắn WebView vào composition tree.
  - `SendMouseInput` / `SendPointerInput` cho chuột và touch.
  - Tích hợp với Flutter qua texture + method channel (setCursorPos, setPointerUpdate, setPointerButton, setScrollDelta).

### 4.2 Còn có thể cải thiện

1. **Đảm bảo luôn dùng Composition Controller cho platform view**
   - Hiện tại nếu không có `ICoreWebView2Environment3` (hoặc 10) thì code **fallback** sang `CreateCoreWebView2Controller` → lại có child HWND và tranh focus.
   - **Khả thi:** Bắt buộc Composition (hoặc báo lỗi rõ ràng) cho embedded view; không fallback sang Controller khi `willBeSurface == true`.

2. **Focus và “child” HWND thực sự**
   - Child HWND duy nhất là **cửa sổ host** (CreateWindowEx của plugin). Cửa sổ này có thể tham gia vào chuỗi focus (activation) khi user chạm vào vùng WebView.
   - **Khả thi:** Xử lý focus cho host window (ví dụ **WM_MOUSEACTIVATE** trả về `MA_NOACTIVATE` hoặc không chuyển focus sang host), hoặc chủ động giữ focus ở main window và chỉ forward input xuống WebView qua SendMouseInput/SendPointerInput.

3. **Touch và bàn phím ảo**
   - Vấn đề mô tả trong `pos_online_webview_focus_touch_windows.md` (bàn phím ảo hiện rồi ẩn, mất focus) có thể do:
     - Gesture arena (Flutter vs WebView),
     - Hoặc focus chuyển giữa main window và host window / các control.
   - Với Composition Controller, phần “WebView2 tạo child HWND” đã được loại bỏ; cải thiện focus (mục 2) có thể giảm thêm mất focus trên touch.

4. **InAppBrowser / Headless**
   - Hiện dùng `willBeSurface = false` → **CreateCoreWebView2Controller** → có child HWND. Nếu sau này cần trải nghiệm tương tự (không tranh focus) cho browser window hoặc headless, có thể cân nhắc chuyển sang Composition Controller và tự vẽ/input (phức tạp hơn, có thể làm giai đoạn sau).

---

## 5. Kế hoạch thực hiện (đề xuất)

### Phase 1: Xác nhận và bắt buộc Composition Controller cho embedded view

| Bước | Nội dung |
|------|----------|
| 1.1 | Trên máy phát sinh lỗi, **kiểm tra** xem embedded WebView đang đi vào nhánh Composition hay Controller. Xem mục **“Cách debug: Composition vs fallback”** bên dưới. |
| 1.2 | Đảm bảo **WebView2 Runtime** đủ mới (Environment3 có từ bản SDK tương ứng; thường từ 1.0.774.44). Nếu cần, nêu rõ version tối thiểu trong tài liệu/dependency. |
| 1.3 | **Không fallback** sang CreateCoreWebView2Controller khi `willBeSurface == true`: nếu không query được Environment3/10 hoặc CreateCoreWebView2CompositionController thất bại thì trả lỗi rõ ràng thay vì tạo Controller (để tránh lại có child HWND). |

#### Cách debug: xem WebView đang dùng Composition hay fallback

- **Build Debug:** Chạy app Windows ở **Debug** (không build Release). Trong package đã thêm log trong `in_app_webview.cpp` → `createInAppWebViewEnv()`:
  - Khi vào nhánh Composition: in ra **`[WebView2] Using Composition Controller (ICoreWebView2CompositionController) - no child HWND`**.
  - Khi fallback: in ra **`[WebView2] Fallback to Controller (CreateCoreWebView2Controller) - WebView2 will create child HWND`**.
  - Trước đó có dòng **`[WebView2] willBeSurface=... hasEnv3=... hasEnv10=...`** (cho biết có lấy được Environment3/10 hay không).
- **Xem log:** Chạy app từ **terminal** (VD: `flutter run -d windows`) hoặc từ **Visual Studio** (Run/Debug) và xem **console** (stdout). Hoặc dùng **DebugView** (Sysinternals) / **Output** tab trong Visual Studio (OutputDebugString) để bắt message.
- **Breakpoint:** Đặt breakpoint trong `in_app_webview.cpp` tại dòng `if (willBeSurface && (webViewEnv10 || webViewEnv3))` và xem `webViewEnv3` / `webViewEnv10` có khác null không; bước tiếp theo sẽ biết đang vào Composition hay `else` (fallback).
- **Lưu ý:** Log chỉ xuất khi build **Debug** (macro `debugLog` chỉ hoạt động khi không define `NDEBUG`). Build Release sẽ không in các dòng trên.

### Phase 2: Quản lý focus (host window)

| Bước | Nội dung |
|------|----------|
| 2.1 | Cửa sổ host (CreateWindowEx trong createInAppWebView) hiện dùng **DefWindowProc** (trong `InAppWebViewManager`, `windowClass_.lpfnWndProc = &DefWindowProc`). Cần **subclass** cửa sổ này (hoặc tạo với WndProc riêng) để xử lý message. |
| 2.2 | Trong WndProc của host window, xử lý **WM_MOUSEACTIVATE**: trả về **MA_NOACTIVATE** (và có thể **MA_NOACTIVATE** kèm eat message) để click/touch vào vùng WebView **không** kích hoạt (activate) cửa sổ host, giữ focus/activation ở main window. Lưu ý: cần test kỹ để input vẫn được Flutter chuyển xuống WebView qua SendMouseInput/SendPointerInput. |
| 2.3 | (Tùy chọn) Nếu vẫn mất focus, thử **SetFocus** về main window (hoặc Flutter view) sau một số sự kiện (ví dụ sau khi nhận pointer down trong vùng WebView), hoặc dùng **SetActiveWindow** khi phát hiện focus sai. |

### Phase 3: Touch và bàn phím ảo

| Bước | Nội dung |
|------|----------|
| 3.1 | Đảm bảo Flutter gửi đủ **pointer events** (touch) xuống platform view; package đã có `setPointerUpdate` (SendPointerInput). Kiểm tra trên Windows touch rằng chuỗi Activate/Down/Update/Up/Leave được gửi đúng và WebView nhận được (input trong WebView hoạt động, có thể focus vào input trong trang). |
| 3.2 | **Lưu ý:** Trên **Windows**, implementation `WindowsInAppWebViewWidget` **không dùng** `gestureRecognizers` – build chỉ trả về `CustomPlatformView` (có `Listener` nhận mọi pointer event). Do đó **thay đổi gestureRecognizers trong app (pos_online_page) không ảnh hưởng** tới việc forward event trên Windows. Nếu sau Phase 2 vẫn còn "bàn phím ảo hiện rồi ẩn", ưu tiên kiểm tra **resizeToAvoidBottomInset** / layout và xử lý focus ở package (host window / Focus widget). |

### Phase 4: Tài liệu và kiểm thử

| Bước | Nội dung |
|------|----------|
| 4.1 | Ghi lại trong docs: embedded InAppWebView trên Windows dùng **CreateCoreWebView2CompositionController**; yêu cầu WebView2 Runtime hỗ trợ Environment3 (version tối thiểu). |
| 4.2 | Test trên **Windows có màn hình cảm ứng**: focus không bị mất khi tap vào input trong WebView, bàn phím ảo không tự ẩn ngay, không cần nhấn nhiều lần để lấy focus. |
| 4.3 | Test với **chuột**: scroll, click, focus vào link/input vẫn hoạt động bình thường. |

---

## 6. Rủi ro và lưu ý

- **WM_MOUSEACTIVATE = MA_NOACTIVATE:** Một số app giữ focus ở main window bằng cách này; cần đảm bảo Flutter vẫn nhận hit test và gửi pointer events xuống platform view. Nếu có side effect (ví dụ một số click không tới WebView), có thể cần điều chỉnh (ví dụ chỉ dùng MA_NOACTIVATE khi touch, hoặc chỉ khi focus đang ở main).  
- **Version WebView2:** Một số máy cài Runtime cũ có thể không có Environment3; cần nêu rõ yêu cầu version và hành vi khi không đủ (báo lỗi thay vì fallback sang Controller).  
- **InAppBrowser/Headless:** Giữ nguyên CreateCoreWebView2Controller cho đến khi có nhu cầu và nguồn lực chuyển sang Composition; tránh thay đổi lớn cùng lúc.

---

## 7. Tóm tắt

| Câu hỏi | Kết luận |
|--------|----------|
| **Dùng CreateCoreWebView2CompositionController có khả thi không?** | **Có.** Package **đã dùng** cho embedded view khi có Environment3/10. WebView2 khi đó **không** tạo child HWND. |
| **Còn gì cần làm?** | (1) Đảm bảo **luôn** dùng Composition cho embedded view (bỏ fallback Controller). (2) **Focus:** xử lý host window (WM_MOUSEACTIVATE / MA_NOACTIVATE hoặc SetFocus) để main window không mất focus. (3) **Touch:** đảm bảo pointer events đầy đủ và kết hợp với các gợi ý trong pos_online_webview_focus_touch_windows.md. |
| **Tài liệu tham khảo** | [ICoreWebView2CompositionController](https://learn.microsoft.com/en-us/microsoft-edge/webview2/reference/win32/icorewebview2compositioncontroller), [pos_online_webview_focus_touch_windows.md](./pos_online_webview_focus_touch_windows.md). |

---

## 8. App side (pos_online_page.dart) – Có thể và không thể làm gì

**Luồng sử dụng:** `main.dart` → `Application` → `ApplicationMaterialApp` (initialRoute: online POS) → **PosOnlinePage** với `InAppWebView` (webViewEnvironment, initialUrlRequest, gestureRecognizers, …).

### 8.1 Không thể làm từ app (Dart)

- **Force dùng Composition Controller:** Không có API Dart nào để “bật” hoặc “ép” dùng Composition Controller. Quyết định nằm hoàn toàn ở native Windows: khi plugin tạo **platform view** (embedded InAppWebView), nó luôn gọi `createInAppWebViewEnv(hwnd, true, ...)` (willBeSurface = true). Nếu runtime có Environment3/10 thì native **đã** dùng Composition Controller; nếu không thì fallback sang Controller. App không thể thay đổi điều này từ Dart.
- **Gửi “đặc biệt” input events để tránh lỗi:** Trên Windows, platform view được vẽ bằng **texture** + **Listener** trong `CustomPlatformView`. Mọi pointer event (chuột, touch) tới vùng WebView đều do **Listener** nhận và gửi xuống native qua `setCursorPos` / `setPointerUpdate` / `setPointerButton` / `setScrollDelta`. App **không** gửi event thủ công; app chỉ có thể ảnh hưởng **gesture arena** (xem dưới). Trên Windows, **gestureRecognizers** của `InAppWebView` **không được dùng** trong build (Windows build không wrap với PlatformViewLink/gesture recognizers), nên thay đổi gestureRecognizers trong `pos_online_page.dart` **không** ảnh hưởng tới việc forward event hay focus trên Windows.

### 8.2 Có thể làm từ app (khuyến nghị)

- **Đảm bảo môi trường:** Cài **WebView2 Runtime** đủ mới (hỗ trợ `ICoreWebView2Environment3`, thường từ 1.0.774.44) để native luôn dùng Composition Controller thay vì fallback sang Controller (child HWND). Có thể ghi trong README / docs cho team và khách hàng.
- **Giữ cấu hình hiện tại có lợi cho focus/keyboard:**  
  - `resizeToAvoidBottomInset: false` (Scaffold) – đã đặt; giúp tránh layout thay đổi khi bàn phím ảo mở, giảm nguy cơ mất focus.  
  - Toastr patch `document.hasFocus` / `window.hasFocus` – đã có; tránh logic phía web dựa vào focus bị sai.
- **gestureRecognizers:** Trên Windows không có tác dụng với platform view. Có thể giữ như hiện tại (Vertical + Horizontal drag) cho tương lai nếu package Windows sau này dùng; hoặc bỏ cho gọn. **Không** cần thêm EagerGestureRecognizer để “gửi event” trên Windows – event đã được Listener trong package chuyển xuống.

### 8.3 Kết luận cho pos_online_page

- **Không cần sửa gì trong package** chỉ để “force Composition” hay “gửi input” từ app: bản thân app không có API để làm hai việc đó; Composition đã được dùng khi runtime đủ mới, input đã do package forward.
- **Để giảm mất focus / lỗi touch:** cần chỉnh **trong package** (Phase 1–2: bỏ fallback Controller, xử lý WM_MOUSEACTIVATE / focus host window; và nếu cần, xem xét Focus/requestFocus trong CustomPlatformView). App chỉ cần đảm bảo WebView2 Runtime đủ mới và giữ các cấu hình đã nêu.

---

*Tài liệu dựa trên review `packages/flutter_inappwebview/flutter_inappwebview_windows` (in_app_webview.cpp, in_app_webview_manager.cpp, in_app_webview.dart, custom_platform_view.dart/cc), `lib/main.dart`, `lib/src/application.dart`, `lib/src/presentation/pages/pos_online/pos_online_page.dart`, và tài liệu WebView2 Win32.*
