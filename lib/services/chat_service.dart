import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/ai_config.dart';

class ChatService {
  static Future<String> ask({required String prompt, List<Map<String, String>> history = const []}) async {
    if (AIConfig.openaiApiKey.isEmpty) {
      return _localReply(prompt);
    }
    final uri = Uri.parse('https://api.openai.com/v1/chat/completions');
    final messages = <Map<String, String>>[
      {
        'role': 'system',
        'content': 'Bạn là trợ lý AI hữu ích cho ứng dụng bất động sản. Trả lời bằng tiếng Việt nếu người dùng dùng tiếng Việt, ngược lại dùng tiếng Anh. Có thể trả lời câu hỏi chung.'
      },
      ...history,
      {'role': 'user', 'content': prompt},
    ];
    final body = jsonEncode({
      'model': AIConfig.openaiModel,
      'messages': messages,
      'temperature': 0.7,
    });
    final headers = {
      'Authorization': 'Bearer ${AIConfig.openaiApiKey}',
      'Content-Type': 'application/json',
    };
    final res = await http.post(uri, headers: headers, body: body);
    if (res.statusCode == 200) {
      final data = jsonDecode(res.body);
      final choices = data['choices'] as List<dynamic>;
      if (choices.isNotEmpty) {
        final msg = choices.first['message'];
        return (msg['content'] as String).trim();
      }
      return _localReply(prompt);
    }
    return _localReply(prompt);
  }

  static String _localReply(String prompt) {
    final lower = prompt.toLowerCase();
    if (lower.contains('yên tĩnh')) {
      return 'Bạn nên lọc tiện ích "An ninh 24/7" và chọn khu vực xa đường lớn. Gợi ý: Quận Bình Thạnh, Phú Nhuận - nhiều khu dân cư yên tĩnh.';
    }
    if (lower.contains('thoáng mát') || lower.contains('mát mẻ')) {
      return 'Ưu tiên phòng có "Cửa sổ lớn", "Máy lạnh". Diện tích từ 25m² trở lên để đảm bảo thông thoáng.';
    }
    if (lower.contains('an ninh') || lower.contains('an toàn')) {
      return 'Lọc tiện ích "Bảo vệ 24/7" và "Hệ thống an ninh". Khu vực chung cư có bảo vệ thường an toàn hơn.';
    }

    // Hỗ trợ sinh viên
    if (lower.contains('sinh viên') || lower.contains('sv') || lower.contains('student')) {
      return 'Gợi ý cho sinh viên: Chọn phòng trọ gần trường (Q.Bình Thạnh, Q.Thủ Đức), giá 2-4 triệu, có Internet và chỗ để xe.';
    }
    if (lower.contains('đi làm') || lower.contains('nhân viên')) {
      return 'Nên chọn gần trung tâm hoặc có giao thông thuận tiện (metro, bus). Ưu tiên "Máy lạnh", "Internet", "Chỗ để xe".';
    }

    // Thông tin thủ tục
    if (lower.contains('cần gì') || lower.contains('chuẩn bị')) {
      return 'Khi thuê nhà cần: CMND/CCCD, Hợp đồng thuê (ghi rõ điều khoản), Đặt cọc 1-2 tháng tiền nhà, Kiểm tra hạ tầng trước khi ký.';
    }
    if (lower.contains('hợp đồng') || lower.contains('ký')) {
      return 'Hợp đồng thuê nên có: Thông tin 2 bên, Địa chỉ chính xác, Thời hạn & giá thuê, Điều khoản cọc & phạt, Quyền & nghĩa vụ mỗi bên.';
    }
    if (lower.contains('đặt cọc') || lower.contains('cọc tiền')) {
      return 'Thông thường đặt cọc 1-2 tháng tiền nhà. Nên yêu cầu phiếu thu có chữ ký và giữ lại để làm bằng chứng.';
    }

    // Gợi ý theo vị trí
    if (lower.contains('quận 1') || lower.contains('q1')) {
      return 'Quận 1: Trung tâm, giá cao (8-20 triệu/tháng). Phù hợp người làm việc trong trung tâm, ưu tiên tiện nghi đầy đủ.';
    }
    if (lower.contains('quận 7') || lower.contains('q7') || lower.contains('phú mỹ hưng')) {
      return 'Quận 7 / Phú Mỹ Hưng: Khu vực hiện đại, nhiều chung cư cao cấp, có hồ bơi, gym. Giá 5-15 triệu.';
    }
    if (lower.contains('thủ đức') || lower.contains('q.thủ đức')) {
      return 'Quận Thủ Đức: Giá hợp lý (3-7 triệu), gần ĐH Quốc Gia, ĐH Bách Khoa. Phù hợp sinh viên và người đi làm.';
    }
    if (lower.contains('bình thạnh') || lower.contains('q.bình thạnh')) {
      return 'Quận Bình Thạnh: Vị trí trung gian, giá trung bình (4-8 triệu), nhiều khu dân cư yên tĩnh, gần trung tâm.';
    }

    // Thanh toán & Membership
    if (lower.contains('thanh toán') || lower.contains('chuyển khoản')) {
      return 'Hỗ trợ thanh toán qua VietQR (chuyển khoản ngân hàng) và PayPal. Sau khi thanh toán, Admin sẽ duyệt trong 24h.';
    }
    if (lower.contains('hoàn tiền') || lower.contains('refund')) {
      return 'Liên hệ Admin qua mục "Báo cáo" nếu có sự cố thanh toán. Admin sẽ kiểm tra và xử lý hoàn tiền nếu cần.';
    }
    if (lower.contains('gói nâng cấp') || lower.contains('mua thêm')) {
      return 'Có 3 gói: Basic (20 tin/tháng), Pro (không giới hạn + đẩy tin), Vip (thêm banner + ưu tiên). Vào mục Thành viên để xem chi tiết.';
    }

    // Báo cáo & Khiếu nại
    if (lower.contains('lừa đảo') || lower.contains('scam')) {
      return 'Nếu phát hiện tin giả hoặc lừa đảo, bấm nút 🚩 trên bài đăng để báo cáo. Admin sẽ kiểm tra và gỡ bài trong 24h.';
    }
    if (lower.contains('tin giả') || lower.contains('bài sai')) {
      return 'Dùng nút báo cáo (🚩) trên bài đăng để thông báo cho Admin. Mô tả chi tiết vấn đề để xử lý nhanh hơn.';
    }

    // Xử lý lỗi
    if (lower.contains('lỗi') || lower.contains('bug') || lower.contains('không vào được')) {
      return 'Thử: (1) Tắt mở lại app, (2) Xóa cache app, (3) Cập nhật app phiên bản mới nhất. Nếu vẫn lỗi, liên hệ Admin.';
    }
    if (lower.contains('quên mật khẩu') || lower.contains('reset')) {
      return 'Vào màn hình Đăng nhập → "Quên mật khẩu" → Nhập email đã đăng ký → Kiểm tra hộp thư để reset.';
    }
    if (lower.contains('help') || lower.contains('hướng dẫn') || lower.contains('có thể làm gì') || lower.contains('help me')) {
      return 'Bạn có thể hỏi: Kiến trúc hệ thống, mô-đun, dữ liệu Firestore, bảo mật/quyền riêng tư, tìm kiếm & lọc, membership/thanh toán, báo cáo vi phạm, doanh thu, bản đồ (OSM/Mapbox), i18n & theme, triển khai/build, kiểm thử/CI, hiệu năng & accessibility.';
    }
    if (lower.contains('giá') || lower.contains('bao nhiêu')) {
      return 'Giá thuê căn hộ thường 3–15 triệu tuỳ khu và diện tích. Bạn muốn khu vực nào?';
    }
    if (lower.contains('hợp đồng') || lower.contains('cọc')) {
      return 'Thường cần đặt cọc 1–2 tháng. Hợp đồng nên có điều khoản rõ ràng và công chứng nếu thuê dài hạn.';
    }
    if (lower.contains('tìm') || lower.contains('thuê') || lower.contains('lọc')) {
      return 'Vào Trang chủ → thanh tìm kiếm và bộ lọc (giá, diện tích, tiện ích). Có thể lưu tìm kiếm và dùng sắp xếp “Mới nhất/giá tăng/giảm”.';
    }
    if (lower.contains('liên hệ') || lower.contains('gọi') || lower.contains('sđt')) {
      return 'Mở chi tiết bài đăng để xem số điện thoại/Email chủ nhà và liên hệ trực tiếp.';
    }
    if (lower.contains('dưới 5') || lower.contains('5 triệu')) {
      return 'Bộ lọc → đặt Giá tối đa = 5,000,000. Bạn có thể kết hợp tiện ích (máy lạnh, hồ bơi) để thu hẹp kết quả.';
    }
    if (lower.contains('hồ bơi')) {
      return 'Trong bộ lọc → bật tiện ích “Hồ bơi”. Khu vực quận 2, 7 thường có nhiều căn có hồ bơi.';
    }
    if (lower.contains('gần trung tâm')) {
      return 'Chọn khu vực Quận 1/3/Bình Thạnh hoặc bán kính mong muốn rồi sắp xếp “Mới nhất”.';
    }
    if (lower.contains('thanh toán') || lower.contains('membership') || lower.contains('nâng cấp')) {
      return 'Vào mục Thành viên để xem gói. Thanh toán có thể được duyệt trong Admin; theo dõi trạng thái ở phần thanh toán.';
    }
    if (lower.contains('báo cáo') || lower.contains('vi phạm')) {
      return 'Trong thẻ bài, dùng nút cờ để báo cáo vi phạm. Admin xem và xử lý tại trang Quản lý báo cáo.';
    }
    if (lower.contains('doanh thu') || lower.contains('revenue')) {
      return 'Trang Báo cáo & Thống kê có mục doanh thu: hôm nay, 7 ngày, 30 ngày; số giao dịch theo trạng thái. Dữ liệu từ payments.';
    }
    if (lower.contains('bản đồ') || lower.contains('map') || lower.contains('google map')) {
      return 'Ứng dụng hỗ trợ bản đồ Google Maps. Mở trang bản đồ từ menu để tìm kiếm quanh đây.';
    }
    if (lower.contains('i18n') || lower.contains('đa ngôn') || lower.contains('language') || lower.contains('việt') || lower.contains('english')) {
      return 'Đa ngôn ngữ vi/en dùng Flutter gen-l10n (app_vi.arb, app_en.arb). Đổi ngôn ngữ ở Cài đặt và trong Hồ sơ.';
    }
    if (lower.contains('theme') || lower.contains('dark') || lower.contains('chế độ tối')) {
      return 'Theme sáng/tối/hệ thống qua ThemeProvider. Chế độ tối đã tăng tương phản cho card/chip/input theo ColorScheme.';
    }
    if (lower.contains('kiến trúc') || lower.contains('architecture') || lower.contains('module')) {
      return 'Kiến trúc: Router; Providers (Auth/Post/Locale/Theme); Services (Firebase/Payment/Chat); Screens user/admin; Widgets; i18n/Theme cấu hình chung.';
    }
    if (lower.contains('cơ sở dữ liệu') || lower.contains('firestore') || lower.contains('collection')) {
      return 'Collection: users, posts, reviews, favorites, payments, recommend_events, reports. Stream + lọc client để tránh index phức hợp.';
    }
    if (lower.contains('bảo mật') || lower.contains('quyền riêng tư') || lower.contains('privacy') || lower.contains('security')) {
      return 'Không lưu khoá vào repo; Firestore Security Rules; hạn chế log PII; phân quyền admin rõ ràng; có báo cáo vi phạm.';
    }
    if (lower.contains('triển khai') || lower.contains('build') || lower.contains('release') || lower.contains('ci')) {
      return 'Build flutter cho android/ios/web. Nếu dùng AI thì truyền OPENAI_API_KEY qua --dart-define hoặc secrets CI. Khuyến nghị thêm workflow CI.';
    }
    if (lower.contains('kiểm thử') || lower.contains('test') || lower.contains('unit')) {
      return 'Nên thêm unit/widget/integration tests cho Providers và các màn chính; dùng flutter_test và mock Firebase.';
    }
    if (lower.contains('hiệu năng') || lower.contains('performance') || lower.contains('tối ưu')) {
      return 'Lazy-load ảnh, hạn chế rebuild với Provider, dùng ColorScheme; cân nhắc phân trang posts và cache.';
    }
    if (lower.contains('accessibility') || lower.contains('khả năng truy cập')) {
      return 'Tương phản tốt, cỡ chữ, hit target lớn, semantic labels cho screen readers.';
    }
    if (lower.contains('chatbot') || lower.contains('ai')) {
      return 'Chatbot có chế độ nội bộ (không cần AI key) và chế độ AI khi truyền OPENAI_API_KEY. Nội bộ trả lời theo FAQ dự án.';
    }
    return 'Mình là trợ lý nội bộ: bạn có thể hỏi về tìm kiếm, lọc, thanh toán, báo cáo, hoặc chức năng app. Cho mình biết cụ thể nhu cầu nhé!';
  }
}
