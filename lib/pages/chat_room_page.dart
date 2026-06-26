import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/services/auth_service.dart';
import 'package:purramedics/theme/app_theme.dart';

class ChatRoomPage extends StatefulWidget {
  final String chatId;
  final String chatUserName;
  final bool isVet;

  const ChatRoomPage({
    super.key,
    required this.chatId,
    required this.chatUserName,
    required this.isVet,
  });

  @override
  State<ChatRoomPage> createState() => _ChatRoomPageState();
}

class _ChatRoomPageState extends State<ChatRoomPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _firestoreService.markChatAsRead(widget.chatId, widget.isVet);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    _messageController.clear();

    final currentUser = _authService.currentUser;
    if (currentUser == null) return;

    await _firestoreService.sendMessage(
      senderId: currentUser.uid,
      senderName:
          currentUser.displayName ??
          (widget.isVet ? 'Vet' : widget.chatUserName),
      text: text,
      isVetSender: widget.isVet,
      chatId: widget.chatId,
      chatUserName: widget.chatUserName,
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('hh:mm a').format(timestamp.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          widget.isVet ? widget.chatUserName : 'Chat with Vet',
          style: AppTypography.titleLarge,
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        shape: const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _firestoreService.getMessagesStream(widget.chatId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          decoration: const BoxDecoration(
                            color: AppColors.primarySurface,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: AppColors.primary,
                            size: 32,
                          ),
                        ),
                        AppSpacing.vMd,
                        Text(
                          'No messages yet',
                          style: AppTypography.titleMedium,
                        ),
                        AppSpacing.vXs,
                        Text(
                          'Say hi to start the conversation',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final messages = snapshot.data!;

                return ListView.builder(
                  reverse: true,
                  itemCount: messages.length,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMine = message['isVetSender'] == widget.isVet;
                    final timestamp = message['timestamp'] as Timestamp?;

                    return Align(
                      alignment: isMine
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.md),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        constraints: BoxConstraints(
                          maxWidth: MediaQuery.of(context).size.width * 0.75,
                        ),
                        decoration: BoxDecoration(
                          color: isMine ? AppColors.primary : AppColors.surface,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18),
                            topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMine ? 18 : 4),
                            bottomRight: Radius.circular(isMine ? 4 : 18),
                          ),
                          boxShadow: AppShadows.sm,
                        ),
                        child: Column(
                          crossAxisAlignment: isMine
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              message['text'] ?? '',
                              style: AppTypography.bodyLarge.copyWith(
                                color: isMine
                                    ? AppColors.textInverse
                                    : AppColors.textPrimary,
                              ),
                            ),
                            AppSpacing.vXs,
                            Text(
                              _formatTime(timestamp),
                              style: AppTypography.labelSmall.copyWith(
                                color: isMine
                                    ? Colors.white.withOpacity(0.7)
                                    : AppColors.textTertiary,
                              ),
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
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.divider)),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) {
                        if (event is KeyDownEvent &&
                            event.logicalKey == LogicalKeyboardKey.enter &&
                            !HardwareKeyboard.instance.isShiftPressed) {
                          _sendMessage();
                        }
                      },
                      child: TextField(
                        controller: _messageController,
                        style: AppTypography.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textTertiary,
                          ),
                          filled: true,
                          fillColor: AppColors.surfaceAlt,
                          border: OutlineInputBorder(
                            borderRadius: AppRadii.rFull,
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        maxLines: null,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  AppSpacing.hSm,
                  Material(
                    color: AppColors.primary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _sendMessage,
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(
                          Icons.send_rounded,
                          color: AppColors.textInverse,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
