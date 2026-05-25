import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:purramedics/AI Assistant/presentation/chat_provider.dart';
import 'package:purramedics/theme/app_theme.dart';
import 'package:purramedics/widgets/widgets.dart';

/// ============================================================================
/// SYMPTOMS PAGE (Digital Symptom Checker)
/// AI-backed symptom assessment + first-aid reference.
/// ============================================================================
class SymptomsPage extends StatefulWidget {
  const SymptomsPage({super.key});

  @override
  State<SymptomsPage> createState() => _SymptomsPageState();
}

class _SymptomsPageState extends State<SymptomsPage> {
  final List<String> symptoms = const [
    'Loss of appetite', 'Vomiting', 'Diarrhea', 'Lethargy',
    'Coughing', 'Limping', 'Scratching', 'Difficulty breathing',
  ];

  final List<String> selectedSymptoms = [];
  final TextEditingController descriptionController = TextEditingController();
  final ScrollController _mainScrollController = ScrollController();
  final GlobalKey _analysisKey = GlobalKey();
  bool _isGenerating = false;

  @override
  void dispose() {
    descriptionController.dispose();
    _mainScrollController.dispose();
    super.dispose();
  }

  void _toggleSymptom(String s) {
    setState(() {
      if (selectedSymptoms.contains(s)) {
        selectedSymptoms.remove(s);
        var t = descriptionController.text;
        t = t.replaceAll('$s, ', '').replaceAll(', $s', '').replaceAll(s, '');
        descriptionController.text = t;
      } else {
        selectedSymptoms.add(s);
        final t = descriptionController.text;
        descriptionController.text = t.isEmpty ? s : '$t, $s';
      }
      descriptionController.selection = TextSelection.fromPosition(
        TextPosition(offset: descriptionController.text.length),
      );
    });
  }

  String _buildPayload() {
    final selected = selectedSymptoms.join(', ');
    final details = descriptionController.text.trim();
    if (selected.isEmpty && details.isEmpty) return '';
    if (selected.isEmpty) return 'Details: $details';
    if (details.isEmpty) return 'Symptoms: $selected';
    return 'Symptoms: $selected\nDetails: $details';
  }

  void _showTrustInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadii.rLg),
        title: Text('How this works', style: AppTypography.headlineSmall),
        content: Text(
          'Purramedics uses an AI system trained on veterinary data to triage symptoms. '
          'It cross-references thousands of cases to give a preliminary assessment more accurate than generic web searches.\n\n'
          'Always consult a real vet for critical emergencies.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Understood', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }

  Future<void> _onGenerateReport() async {
    if (_isGenerating) return;
    final payload = _buildPayload();
    if (payload.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please select or describe symptoms'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _isGenerating = true);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_analysisKey.currentContext != null) {
        Scrollable.ensureVisible(
          _analysisKey.currentContext!,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
          alignment: 0.1, // Aligns slightly near the top
        );
      }
    });

    try {
      await context.read<ChatProvider>().sendMessage(payload);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
            setState(() {});
          },
          child: SingleChildScrollView(
            controller: _mainScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl, vertical: AppSpacing.xxl),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                AppSpacing.vXxl,
                _buildSymptomChips(),
                AppSpacing.vXxl,
                _buildNotesInput(),
                AppSpacing.vXxl,
                _buildAnalysisPanel(chat),
                AppSpacing.vHuge,
                _buildContactSection(),
                AppSpacing.vHuge,
                _buildFirstAidGrid(),
                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xxl,
            vertical: AppSpacing.lg,
          ),
          child: PrimaryButton(
            label: 'Generate Report',
            icon: Icons.auto_awesome_rounded,
            onPressed: _onGenerateReport,
            isLoading: _isGenerating,
          ).animate(onPlay: (c) => c.repeat(period: 3500.ms)).shimmer(
                duration: 1200.ms,
                color: Colors.white.withOpacity(0.25),
                angle: 0.8,
              ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppBadge(label: 'DIGITAL HEALTH CHECK', tone: BadgeTone.info),
        AppSpacing.vMd,
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text('Symptom Checker', style: AppTypography.displayMedium)),
            IconButton(
              onPressed: _showTrustInfo,
              icon: const Icon(Icons.info_outline_rounded, color: AppColors.textTertiary),
              tooltip: 'About this tool',
            ),
          ],
        ),
        Text(
          'Select signs below to generate a health report.',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildSymptomChips() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Common Symptoms'),
        AppSpacing.vMd,
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: symptoms.map((s) {
            final selected = selectedSymptoms.contains(s);
            return GestureDetector(
              onTap: () => _toggleSymptom(s),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: selected ? AppColors.primary : AppColors.surface,
                  borderRadius: AppRadii.rFull,
                  border: Border.all(color: selected ? AppColors.primary : AppColors.divider),
                  boxShadow: selected ? AppShadows.colored(AppColors.primary, opacity: 0.2) : null,
                ),
                child: Text(
                  s,
                  style: AppTypography.labelMedium.copyWith(
                    color: selected ? AppColors.textInverse : AppColors.textPrimary,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildNotesInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Observations & Notes'),
        AppSpacing.vMd,
        KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            if (event is KeyDownEvent &&
                event.logicalKey == LogicalKeyboardKey.enter &&
                !HardwareKeyboard.instance.isShiftPressed) {
              _onGenerateReport();
            }
          },
          child: AppTextField(
            controller: descriptionController,
            hint: 'Describe behavioral changes, duration, or other signs...',
            maxLines: 4,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => _onGenerateReport(),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalysisPanel(ChatProvider chat) {
    return Column(
      key: _analysisKey,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.monitor_heart_outlined, color: AppColors.textPrimary, size: 22),
            AppSpacing.hSm,
            Text(
              chat.lastReport != null ? 'Analysis Result' : 'Analysis Status',
              style: AppTypography.headlineSmall,
            ),
          ],
        ),
        AppSpacing.vMd,
        AppCard(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 120),
            child: _analysisContent(chat),
          ),
        ),
      ],
    );
  }

  Widget _analysisContent(ChatProvider chat) {
    if (chat.isLoading) {
      return Shimmer.fromColors(
        baseColor: AppColors.surfaceAlt,
        highlightColor: AppColors.divider,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 150, height: 20, color: AppColors.surface),
            AppSpacing.vMd,
            Container(width: double.infinity, height: 14, color: AppColors.surface),
            AppSpacing.vSm,
            Container(width: double.infinity, height: 14, color: AppColors.surface),
            AppSpacing.vSm,
            Container(width: 200, height: 14, color: AppColors.surface),
          ],
        ),
      );
    }

    final r = chat.lastReport;
    if (r != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _reportSection('🚨 Triage assessment', r.triage),
          if (r.summary.isNotEmpty) ...[
            AppSpacing.vSm,
            Text(r.summary, style: AppTypography.bodyMedium.copyWith(height: 1.6, color: AppColors.textSecondary)),
          ],
          const Divider(height: 32, color: AppColors.divider),
          _reportSection('🏥 Veterinary action plan', r.actionPlan),
          const Divider(height: 32, color: AppColors.divider),
          Text('💊 Immediate home care', style: AppTypography.titleSmall),
          AppSpacing.vSm,
          ...r.immediateHomeCare.map((s) => _bullet(s)),
          const Divider(height: 32, color: AppColors.divider),
          Text('🔍 Potential causes', style: AppTypography.titleSmall),
          AppSpacing.vSm,
          ...r.potentialCauses.map((s) => _bullet(s)),
        ],
      );
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconAvatar(
            icon: Icons.analytics_outlined,
            color: AppColors.textTertiary,
            background: AppColors.surfaceAlt,
            size: 56,
          ),
          AppSpacing.vMd,
          Text('Ready to analyze', style: AppTypography.titleMedium),
          AppSpacing.vXs,
          Text(
            'Select symptoms above and tap\nGenerate Report to start.',
            textAlign: TextAlign.center,
            style: AppTypography.bodyMedium.copyWith(color: AppColors.textTertiary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _reportSection(String title, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.titleSmall),
        AppSpacing.vSm,
        Text(body, style: AppTypography.bodyLarge),
      ],
    );
  }

  Widget _bullet(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: AppTypography.bodyLarge.copyWith(color: AppColors.primary)),
          Expanded(child: Text(text, style: AppTypography.bodyMedium)),
        ],
      ),
    );
  }

  Widget _buildContactSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Contact Us',
          subtitle: 'For non-emergencies or inquiries, please reach out',
        ),
        AppSpacing.vMd,
        StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('settings').doc('clinic_profile').snapshots(),
          builder: (context, snapshot) {
            final data = snapshot.data?.data() as Map<String, dynamic>?;
            final phone = data?['phone'] ?? '—';
            final email = data?['email'] ?? '—';
            final address = data?['address'] ?? '—';

            return Column(
              children: [
                _contactRow(
                  icon: Icons.phone_in_talk_outlined,
                  color: AppColors.info,
                  bg: AppColors.infoSurface,
                  label: 'Hotline',
                  value: phone,
                  onTap: () => launchUrl(Uri.parse('tel:$phone')),
                ),
                AppSpacing.vMd,
                _contactRow(
                  icon: Icons.email_outlined,
                  color: AppColors.success,
                  bg: AppColors.successSurface,
                  label: 'Email Support',
                  value: email,
                  onTap: () => launchUrl(Uri.parse('mailto:$email')),
                ),
                AppSpacing.vMd,
                _contactRow(
                  icon: Icons.location_on_outlined,
                  color: AppColors.warning,
                  bg: AppColors.warningSurface,
                  label: 'Visit Us',
                  value: address,
                  onTap: () => launchUrl(Uri.parse('https://maps.google.com/?q=${Uri.encodeComponent(address)}')),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _contactRow({
    required IconData icon,
    required Color color,
    required Color bg,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          IconAvatar(icon: icon, color: color, background: bg, circle: true),
          AppSpacing.hMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.labelMedium.copyWith(color: AppColors.textTertiary)),
                AppSpacing.vXs,
                Text(value, style: AppTypography.titleSmall),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textTertiary),
        ],
      ),
    );
  }

  Widget _buildFirstAidGrid() {
    final tiles = [
      _GuideTile('CPR Guide', Icons.favorite_outline, AppColors.danger, AppColors.dangerSurface, _cprContent(), 'American Red Cross', 'https://www.redcross.org/take-a-class/cpr/performing-cpr/pet-cpr'),
      _GuideTile('Choking', Icons.air, AppColors.info, AppColors.infoSurface, _chokingContent(), 'American Red Cross', 'https://www.redcross.org/take-a-class/resources/learn-pet-first-aid/dog/choking'),
      _GuideTile('Bleeding', Icons.bloodtype_outlined, AppColors.warning, AppColors.warningSurface, _bleedingContent(), 'Veterinary Partner', 'https://veterinarypartner.vin.com/default.aspx?pid=19239&id=4951317'),
      _GuideTile('Poisoning', Icons.science_outlined, AppColors.secondaryDark, AppColors.secondarySurface, _poisoningContent(), 'Animal Poisons Helpline', 'https://www.animalpoisons.com.au/emergency-instructions/'),
      _GuideTile('Heatstroke', Icons.wb_sunny_outlined, AppColors.secondary, AppColors.secondarySurface, _heatstrokeContent(), 'American Red Cross', 'https://www.redcross.org/take-a-class/resources/learn-pet-first-aid/dog/heatstroke'),
      _GuideTile('Seizures', Icons.bolt_outlined, AppColors.primary, AppColors.primarySurface, _seizuresContent(), 'Veterinary Partner', 'https://veterinarypartner.vin.com/default.aspx?pid=19239&id=4951440'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(title: 'Quick First Aid'),
        AppSpacing.vMd,
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 700 ? 3 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: AppSpacing.md,
              mainAxisSpacing: AppSpacing.md,
              childAspectRatio: 1.1,
              children: tiles.map(_guideCard).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _guideCard(_GuideTile t) {
    return GestureDetector(
      onTap: () => _showGuideSheet(t),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: t.bg,
          borderRadius: AppRadii.rLg,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(t.icon, color: t.accent, size: 40),
            AppSpacing.vSm,
            Text(
              t.title,
              textAlign: TextAlign.center,
              style: AppTypography.titleSmall.copyWith(color: t.accent),
            ),
          ],
        ),
      ),
    );
  }

  void _showGuideSheet(_GuideTile t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, controller) => Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              AppSpacing.vMd,
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: AppRadii.rFull,
                ),
              ),
              AppSpacing.vLg,
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                child: Row(
                  children: [
                    IconAvatar(icon: t.icon, color: t.accent, background: t.bg, size: 52),
                    AppSpacing.hMd,
                    Expanded(child: Text(t.title, style: AppTypography.displaySmall)),
                  ],
                ),
              ),
              const Divider(height: 32, color: AppColors.divider),
              Expanded(
                child: SingleChildScrollView(
                  controller: controller,
                  padding: const EdgeInsets.fromLTRB(AppSpacing.xxl, 0, AppSpacing.xxl, AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STEP-BY-STEP GUIDE',
                        style: AppTypography.labelSmall.copyWith(color: AppColors.textTertiary),
                      ),
                      AppSpacing.vMd,
                      t.content,
                      AppSpacing.vXl,
                      const Divider(color: AppColors.divider),
                      AppSpacing.vSm,
                      Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 14, color: AppColors.textTertiary),
                          AppSpacing.hXs,
                          Text('Source: ${t.source}', style: AppTypography.bodySmall.copyWith(color: AppColors.textTertiary)),
                        ],
                      ),
                      AppSpacing.vXs,
                      GestureDetector(
                        onTap: () async {
                          if (!await launchUrl(Uri.parse(t.url), mode: LaunchMode.externalApplication)) {
                            debugPrint('Could not launch ${t.url}');
                          }
                        },
                        child: Text(
                          'Read full guide →',
                          style: AppTypography.labelLarge.copyWith(color: t.accent),
                        ),
                      ),
                      AppSpacing.vXxxl,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs + 2),
        child: Text(text, style: AppTypography.bodyLarge.copyWith(height: 1.6)),
      );

  Widget _cprContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. CHECK FOR RESPONSIVENESS: Call your pet\'s name, tap their shoulder. If no response, begin CPR immediately.'),
        _step('2. POSITION: Lay pet on their right side on a firm surface. Ensure airway is clear.'),
        _step('3. CHEST COMPRESSIONS: For dogs, push down 1/3 of chest width at 100–120 per minute. For cats, use thumb and fingers around the chest.'),
        _step('4. RESCUE BREATHS: After 30 compressions, hold mouth shut, breathe into nose once every 5 seconds.'),
        _step('5. CONTINUE: Keep the 30:2 ratio until breathing resumes or you reach a vet.'),
      ]);

  Widget _chokingContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. STAY CALM: Your pet is panicking. Keeping calm reduces their stress.'),
        _step('2. LOOK INSIDE: Open the mouth gently and look for visible obstruction. Only remove if clearly reachable — don\'t push deeper.'),
        _step('3. HEIMLICH FOR DOGS: Stand behind them, make a fist below the ribcage, thrust upward 3–5 times firmly.'),
        _step('4. FOR CATS: Hold face-down, supporting head. Apply 5 firm back blows between shoulder blades.'),
        _step('5. VET IMMEDIATELY: Even if the object dislodges, go to a vet to rule out internal damage.'),
      ]);

  Widget _bleedingContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. APPLY PRESSURE: Press a clean cloth or gauze firmly against the wound. Hold for at least 3 minutes without lifting.'),
        _step('2. DO NOT REMOVE CLOTH: If blood soaks through, add another layer on top. Removing the cloth disrupts clot formation.'),
        _step('3. ELEVATE: If possible, raise the injured limb above heart level to reduce blood flow.'),
        _step('4. TOURNIQUET (LIMBS ONLY): As a last resort for severe limb bleeding, apply a tight band above the wound. Note the time applied.'),
        _step('5. RUSH TO VET: All significant bleeding requires immediate veterinary attention.'),
      ]);

  Widget _poisoningContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. DO NOT INDUCE VOMITING: Unless specifically instructed by a poison control hotline — some toxins cause more damage coming back up.'),
        _step('2. IDENTIFY THE SUBSTANCE: If safe, keep the packaging or photograph what was ingested.'),
        _step('3. CALL POISON CONTROL: Contact Animal Poison Control immediately.'),
        _step('4. WATCH FOR SYMPTOMS: Drooling, vomiting, seizures, pale gums, or difficulty breathing signal a critical emergency.'),
        _step('5. RUSH TO VET: Bring the substance/packaging. Time is critical with toxin exposure.'),
      ]);

  Widget _heatstrokeContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. MOVE TO SHADE: Get your pet out of the heat immediately.'),
        _step('2. COOL WATER (NOT ICE): Wet the coat with room-temp water — especially neck, armpits, and groin. Ice water can cause shock.'),
        _step('3. FAN THEM: Use a fan or manual fanning to accelerate cooling while wetting.'),
        _step('4. OFFER WATER: If conscious, let them drink small amounts of cool water. Never force it.'),
        _step('5. VET IMMEDIATELY: Heatstroke causes organ damage within minutes.'),
      ]);

  Widget _seizuresContent() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _step('1. DO NOT RESTRAIN: Never hold your pet down or grab their tongue. Pets do not swallow their tongues.'),
        _step('2. CLEAR THE AREA: Move furniture, stairs, or sharp objects away.'),
        _step('3. TIME IT: If a seizure lasts more than 3–5 minutes, it is life-threatening (status epilepticus).'),
        _step('4. KEEP QUIET & DARK: Turn off loud TVs and dim the lights.'),
        _step('5. AFTERCARE: They will be disoriented and blind (post-ictal). Comfort them gently.'),
      ]);
}

class _GuideTile {
  final String title;
  final IconData icon;
  final Color accent;
  final Color bg;
  final Widget content;
  final String source;
  final String url;
  const _GuideTile(this.title, this.icon, this.accent, this.bg, this.content, this.source, this.url);
}
