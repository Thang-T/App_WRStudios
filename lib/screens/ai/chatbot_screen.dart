import 'package:flutter/material.dart';
import '../../widgets/common/wr_logo.dart';
import '../../config/app_router.dart';

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'text': 'Xin chào! Tôi là trợ lý ảo AI. Tôi có thể giúp gì cho bạn hôm nay?'}
  ];
  final ScrollController _scrollController = ScrollController();
  final List<String> _suggestions = const [
    'Tìm căn hộ dưới 5 triệu',
    'Căn hộ có hồ bơi',
    'Nhà gần trung tâm',
    'Thủ tục thuê nhà',
  ];

  void _sendMessage([String? preset]) {
    final text = (preset ?? _controller.text).trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
    });
    
    _scrollToBottom();

    // Simulate AI Response
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      
      String response = 'Xin lỗi, tôi chưa hiểu ý bạn. Bạn có thể hỏi về giá thuê, thủ tục pháp lý hoặc tìm căn hộ.';
      
      final lower = text.toLowerCase();
      if (lower.contains('giá') || lower.contains('bao nhiêu')) {
        response = 'Giá thuê căn hộ thường dao động từ 3 triệu đến 15 triệu tùy khu vực và diện tích. Bạn đang tìm khu vực nào?';
      } else if (lower.contains('hợp đồng') || lower.contains('cọc')) {
        response = 'Thông thường bạn cần đặt cọc 1-2 tháng tiền nhà. Hợp đồng nên được công chứng nếu thuê lâu dài.';
      } else if (lower.contains('tìm') || lower.contains('thuê')) {
        response = 'Bạn có thể sử dụng tính năng tìm kiếm nâng cao ở trang chủ để lọc theo giá, diện tích và tiện ích mong muốn.';
      } else if (lower.contains('liên hệ') || lower.contains('gọi')) {
        response = 'Bạn có thể xem số điện thoại của chủ nhà trong chi tiết bài đăng và gọi trực tiếp.';
      } else if (lower.contains('dưới 5') || lower.contains('5 triệu')) {
        response = 'Để tìm căn hộ dưới 5 triệu, vào Trang chủ > lọc Giá tối đa = 5,000,000. Bạn muốn khu vực nào?';
      } else if (lower.contains('hồ bơi')) {
        response = 'Bạn có thể bật tiện ích “Hồ bơi” trong bộ lọc. Ngoài ra có thể tham khảo khu vực quận 2, 7.';
      } else if (lower.contains('gần trung tâm')) {
        response = 'Khu trung tâm thường là Quận 1/3/Bình Thạnh. Hãy chọn thành phố/khu vực tương ứng và sắp xếp theo Mới nhất.';
      }

      setState(() {
        _messages.add({'role': 'bot', 'text': response});
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            WRLogo(size: 24, onTap: () => Navigator.pushNamed(context, AppRouter.home)),
            const SizedBox(width: 8),
            const Text('Chatbot Hỗ trợ'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _suggestions.map((s) => ActionChip(label: Text(s), onPressed: () => _sendMessage(s))).toList(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['role'] == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isUser ? Colors.blue : Colors.grey[200],
                      borderRadius: BorderRadius.circular(16).copyWith(
                        bottomRight: isUser ? Radius.zero : const Radius.circular(16),
                        bottomLeft: isUser ? const Radius.circular(16) : Radius.zero,
                      ),
                    ),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                    child: Text(
                      msg['text']!,
                      style: TextStyle(color: isUser ? Colors.white : Colors.black87),
                    ),
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Nhập câu hỏi...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Colors.blue,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
