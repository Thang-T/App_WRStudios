import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common/wr_logo.dart';
import '../../config/app_router.dart';
import '../../models/post.dart';

class AdminContentReportsScreen extends StatefulWidget {
  const AdminContentReportsScreen({super.key});

  @override
  State<AdminContentReportsScreen> createState() => _AdminContentReportsScreenState();
}

class _AdminContentReportsScreenState extends State<AdminContentReportsScreen> {
  final Map<String, Future<Post?>> _postFutures = {};

  Color _statusColor(String s) {
    switch (s) {
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  Future<Post?> _getPost(String postId) {
    return _postFutures.putIfAbsent(postId, () => FirebaseService.getPostById(postId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          WRLogo(size: 24, onTap: () => Navigator.pushNamed(context, AppRouter.home)),
          const SizedBox(width: 8),
          Text(AppLocalizations.of(context)!.manageContentReports),
        ]),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder(
          stream: FirebaseService.getAllReportsStream(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Lỗi tải báo cáo: ${snapshot.error}',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              );
            }
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final docs = snapshot.data!.docs;
            if (docs.isEmpty) {
              return Center(child: Text(AppLocalizations.of(context)!.noData));
            }
            return ListView.separated(
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final d = docs[i].data();
                final id = docs[i].id;
                final postId = (d['postId'] ?? '') as String;
                final userId = (d['reporterUserId'] ?? '') as String;
                final reason = (d['reason'] ?? '') as String;
                final details = (d['details'] ?? '') as String;
                final status = (d['status'] ?? 'open') as String;
                return InkWell(
                  onTap: postId.isEmpty ? null : () => Navigator.pushNamed(context, AppRouter.postDetail, arguments: postId),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(color: Theme.of(context).shadowColor.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('#$id', style: const TextStyle(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            if (postId.isEmpty)
                              Text('Post: $postId • User: $userId')
                            else
                              FutureBuilder<Post?>(
                                future: _getPost(postId),
                                builder: (context, snap) {
                                  final p = snap.data;
                                  if (snap.connectionState == ConnectionState.waiting) {
                                    return Text('Post: $postId • User: $userId');
                                  }
                                  if (p == null) {
                                    return Text('Post: $postId (không tồn tại) • User: $userId');
                                  }
                                  final price = p.price.toStringAsFixed(0);
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 56,
                                          height: 56,
                                          child: (p.images.isNotEmpty && (p.images.first.startsWith('http://') || p.images.first.startsWith('https://')))
                                              ? Image.network(p.images.first, fit: BoxFit.cover)
                                              : Container(
                                                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                                  child: Icon(Icons.image, color: Theme.of(context).colorScheme.onSurfaceVariant),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.title,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '$price VNĐ • ${p.city} • ${p.type}',
                                              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 4),
                            Text('Reason: $reason'),
                            if (details.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(details, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                            ]
                          ]),
                        ),
                        TextButton(
                          onPressed: postId.isEmpty ? null : () => Navigator.pushNamed(context, AppRouter.postDetail, arguments: postId),
                          child: const Text('Xem bài'),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(color: _statusColor(status).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(999)),
                          child: Text(status, style: TextStyle(color: _statusColor(status))),
                        ),
                        const SizedBox(width: 8),
                        TextButton(
                          onPressed: () => FirebaseService.updateReportStatus(reportId: id, status: 'resolved'),
                          child: Text(AppLocalizations.of(context)!.approve),
                        ),
                        TextButton(
                          onPressed: () => FirebaseService.updateReportStatus(reportId: id, status: 'rejected'),
                          child: Text(AppLocalizations.of(context)!.unapprove),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
