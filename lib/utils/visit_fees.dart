const Map<String, int> kVisitFees = {
  'checkup': 500,
  'vaccination': 800,
  'grooming': 400,
  'surgery': 3000,
  'others': 500,
};

const int kDefaultFee = 500;

int feeFor(String visitType) {
  final key = visitType.trim().toLowerCase();
  return kVisitFees[key] ?? kDefaultFee;
}
