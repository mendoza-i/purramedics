class AiReport {
  final String triage;
  final String summary;
  final String actionPlan;
  final List<String> immediateHomeCare;
  final List<String> potentialCauses;

  AiReport({
    required this.triage,
    required this.summary,
    required this.actionPlan,
    required this.immediateHomeCare,
    required this.potentialCauses,
  });
}
