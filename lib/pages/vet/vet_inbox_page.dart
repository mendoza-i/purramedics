import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/pages/chat_room_page.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetInboxPage extends StatelessWidget {
  const VetInboxPage({super.key});

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final now = DateTime.now();
    final time = timestamp.toDate();
    if (now.day == time.day && now.month == time.month && now.year == time.year) {
      return DateFormat('h:mm a').format(time);
    }
    return DateFormat('MMM d').format(time);
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = FirestoreService();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Inbox', style: AppTypography.headlineLarge),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: firestoreService.getVetInboxStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const EmptyState(
                    icon: Icons.inbox_outlined,
                    title: 'No messages yet',
                    message: 'Client conversations will appear here',
                  );
                }

                final chats = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xxl,
                    horizontal: AppSpacing.lg,
                  ),
                  itemCount: chats.length,
                  itemBuilder: (context, index) {
                    final chat = chats[index];
                    final unreadCount = (chat['unreadByVet'] ?? 0) as int;
                    final hasUnread = unreadCount > 0;
                    final lastMessageTime = chat['lastMessageTime'] as Timestamp?;
                    final name = (chat['userName'] as String?) ?? 'Unknown user';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chatId: chat['id'],
                              chatUserName: name,
                              isVet: true,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: AppColors.primarySurface,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: AppTypography.titleMedium.copyWith(color: AppColors.primary),
                              ),
                            ),
                            AppSpacing.hMd,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: hasUnread
                                        ? AppTypography.titleSmall
                                        : AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w500),
                                  ),
                                  AppSpacing.vXs,
                                  Text(
                                    chat['lastMessage'] ?? '',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: hasUnread ? AppColors.textPrimary : AppColors.textTertiary,
                                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            AppSpacing.hSm,
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  _formatTime(lastMessageTime),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: hasUnread ? AppColors.primary : AppColors.textTertiary,
                                  ),
                                ),
                                if (hasUnread) ...[
                                  AppSpacing.vXs,
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary,
                                      borderRadius: AppRadii.rFull,
                                    ),
                                    child: Text(
                                      '$unreadCount',
                                      style: AppTypography.labelSmall.copyWith(color: AppColors.textInverse),
                                    ),
                                  ),
                                ],
                              ],
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
        ),
      ),
    );
  }
}
