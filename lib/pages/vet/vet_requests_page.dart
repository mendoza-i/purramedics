import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:purramedics/services/firestore_service.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/utils/responsive.dart';
import 'package:purramedics/widgets/widgets.dart';

class VetRequestsPage extends StatefulWidget {
  const VetRequestsPage({super.key});

  @override
  State<VetRequestsPage> createState() => _VetRequestsPageState();
}

class _VetRequestsPageState extends State<VetRequestsPage> {
  final _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Patient Requests', style: AppTypography.headlineLarge),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: Responsive.pagePadding(context),
            vertical: AppSpacing.lg,
          ),
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _firestoreService.getPetRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const EmptyState(
                  icon: Icons.mark_email_read_outlined,
                  title: 'No pending requests',
                  message: 'Owner requests will appear here',
                );
              }

              final requests = snapshot.data!;
              final pending = requests
                  .where((r) => r['status'] == 'Pending')
                  .toList();
              final resolved = requests
                  .where((r) => r['status'] != 'Pending')
                  .toList();

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: Responsive.contentMaxWidth(context),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (pending.isNotEmpty) ...[
                          Row(
                            children: [
                              Text(
                                'Needs Attention',
                                style: AppTypography.headlineSmall,
                              ),
                              AppSpacing.hSm,
                              AppBadge(
                                label: '${pending.length}',
                                tone: BadgeTone.warning,
                              ),
                            ],
                          ),
                          AppSpacing.vLg,
                          _buildGrid(pending, isPending: true),
                          AppSpacing.vXxxl,
                        ],
                        if (resolved.isNotEmpty) ...[
                          Text(
                            'Resolved',
                            style: AppTypography.headlineSmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          AppSpacing.vLg,
                          _buildGrid(resolved, isPending: false),
                          AppSpacing.vLg,
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildGrid(
    List<Map<String, dynamic>> items, {
    required bool isPending,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = Responsive.isWide(context)
            ? 3
            : (Responsive.isTablet(context) ? 2 : 1);
        final cardWidth =
            (constraints.maxWidth - (AppSpacing.lg * (cols - 1))) / cols - 0.1;
        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: items
              .map(
                (r) => SizedBox(
                  width: cardWidth,
                  child: _buildRequestCard(r, isPending: isPending),
                ),
              )
              .toList(),
        );
      },
    );
  }

  Widget _buildRequestCard(
    Map<String, dynamic> request, {
    required bool isPending,
  }) {
    final bool isDelete = request['requestType'] == 'Delete Request';
    final BadgeTone typeTone = isDelete ? BadgeTone.danger : BadgeTone.info;
    final String status = request['status'] ?? '';

    return Dismissible(
      key: Key(request['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: AppRadii.rLg,
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpacing.xl),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
      confirmDismiss: (_) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text('Delete request?', style: AppTypography.titleLarge),
            content: Text(
              'This removes the request from your dashboard permanently.',
              style: AppTypography.bodyMedium,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(
                  'Cancel',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(
                  'Delete',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.danger,
                  ),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await _firestoreService.deletePetRequest(request['id']);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Request deleted'),
              backgroundColor: AppColors.textPrimary,
            ),
          );
        }
      },
      child: AppCard(
        color: isPending ? AppColors.surface : AppColors.surfaceAlt,
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppBadge(
                  label: request['requestType'] ?? 'Request',
                  tone: typeTone,
                ),
                if (!isPending)
                  AppBadge(
                    label: status,
                    tone: status == 'Approved'
                        ? BadgeTone.success
                        : BadgeTone.neutral,
                  ),
              ],
            ),
            AppSpacing.vMd,
            Text(
              request['petName'] ?? 'Unknown pet',
              style: AppTypography.titleLarge,
            ),
            AppSpacing.vXs,
            Text(
              'Owner: ${request['ownerEmail'] ?? '—'}',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            AppSpacing.vMd,
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: AppRadii.rMd,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'REASON',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textTertiary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  AppSpacing.vXs,
                  Text(
                    request['reason'] ?? 'No reason provided.',
                    style: AppTypography.bodyMedium,
                  ),
                ],
              ),
            ),
            if (isPending) ...[
              AppSpacing.vLg,
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Decline',
                      onPressed: () =>
                          _showReplyDialog(request['id'], 'Declined'),
                      isExpanded: true,
                      size: AppButtonSize.small,
                    ),
                  ),
                  AppSpacing.hMd,
                  Expanded(
                    child: PrimaryButton(
                      label: 'Approve',
                      onPressed: () =>
                          _showReplyDialog(request['id'], 'Approved'),
                      isExpanded: true,
                      size: AppButtonSize.small,
                    ),
                  ),
                ],
              ),
            ] else if ((request['vetReply'] ?? '')
                .toString()
                .trim()
                .isNotEmpty) ...[
              AppSpacing.vMd,
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.infoSurface,
                  borderRadius: AppRadii.rMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR REPLY',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.info,
                        letterSpacing: 0.5,
                      ),
                    ),
                    AppSpacing.vXs,
                    Text(request['vetReply'], style: AppTypography.bodyMedium),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(String requestId, String newStatus) {
    final replyCtrl = TextEditingController();
    final isApprove = newStatus == 'Approved';
    final accent = isApprove ? AppColors.success : AppColors.danger;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isApprove ? 'Approve Request' : 'Decline Request',
          style: AppTypography.titleLarge.copyWith(color: accent),
        ),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isApprove
                    ? 'Add an optional message for the pet owner:'
                    : 'Explain why so the owner understands:',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              AppSpacing.vMd,
              KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.enter &&
                      !HardwareKeyboard.instance.isShiftPressed) {
                    _submitReply(requestId, newStatus, replyCtrl.text.trim());
                  }
                },
                child: AppTextField(
                  controller: replyCtrl,
                  hint: isApprove
                      ? 'Message (optional)…'
                      : 'Reason for declining…',
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) =>
                      _submitReply(requestId, newStatus, replyCtrl.text.trim()),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Cancel',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          PrimaryButton(
            label: 'Confirm $newStatus',
            onPressed: () =>
                _submitReply(requestId, newStatus, replyCtrl.text.trim()),
            backgroundColor: accent,
            size: AppButtonSize.small,
          ),
        ],
      ),
    );
  }

  void _submitReply(String requestId, String newStatus, String reply) async {
    Navigator.pop(context);
    await _firestoreService.updatePetRequestStatus(requestId, newStatus, reply);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request marked as $newStatus'),
          backgroundColor: newStatus == 'Approved'
              ? AppColors.success
              : AppColors.textPrimary,
        ),
      );
    }
  }
}
