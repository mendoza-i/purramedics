# 📊 Statistics Feature — Implementation Plan
### (Saved for Later — Resume When Ready)

---

## The Goal

Add a **real, academically defensible statistics module** to the Vet Dashboard that uses:
1. **Simple Linear Regression (SLR)** — predict next week's appointment demand
2. **Z-score Classification** — classify visit types as High Demand / Normal / Underutilized

This is the direct equivalent of what the friend's QR product scanner did (most sold / undersold / fine), but applied to a vet clinic context.

---

## What to Say at Your Defense

> *"We implemented Simple Linear Regression directly in Dart to model weekly appointment demand. The algorithm calculates the least-squares best-fit line from historical booking data stored in Firestore, producing a slope coefficient that indicates demand trajectory. Visit types are then classified using Z-score normalization — services beyond one standard deviation above the mean are flagged as High Demand, and those below one standard deviation are flagged as Underutilized — enabling data-driven clinical resource allocation."*

---

## Current Gap (Why Adviser Flagged It)

| Existing Widget | What it does | Is it real ML/stats? |
|---|---|---|
| Seasonal Forecast | Hardcoded `if month >= 6` rules + weather API | ❌ No model |
| Descriptive Analytics | Counts appointments per week, bar chart | ❌ Just counting |

Neither widget uses an actual statistical model — they are rule-based. The adviser wants a real algorithm.

---

## Part 1: Simple Linear Regression (SLR)

### The Concept
```
y = mx + b

x = week number  (1, 2, 3, 4...)
y = appointments that week
m = slope  (rate of demand growth)
b = intercept (baseline)
```

### What to show the user
- A **line chart** with:
  - Solid line = historical weekly appointment counts (from Firestore)
  - Dashed line = SLR predicted trend continuation
  - A labeled point = **"Predicted next week: ~X appointments"**
- A **trend badge**: 
  - `m > 0.5` → 🔴 Rapidly Growing Demand
  - `m > 0` → 🟡 Stable Upward Trend  
  - `m < 0` → 🟢 Demand Declining

### Dart Implementation (no library needed)
```dart
Map<String, double> simpleLinearRegression(List<double> x, List<double> y) {
  final n = x.length;
  final sumX = x.reduce((a, b) => a + b);
  final sumY = y.reduce((a, b) => a + b);
  final sumXY = List.generate(n, (i) => x[i] * y[i]).reduce((a, b) => a + b);
  final sumX2 = x.map((xi) => xi * xi).reduce((a, b) => a + b);

  final m = (n * sumXY - sumX * sumY) / (n * sumX2 - sumX * sumX);
  final b = (sumY - m * sumX) / n;

  return {'slope': m, 'intercept': b};
}

double predict(double weekNumber, double m, double b) => m * weekNumber + b;
```

### Data Source
Pull from Firestore `appointments` collection → group by ISO week number → count per week → feed into the SLR function.

---

## Part 2: Z-score Visit Type Classification

### The Concept
```
Z = (x - μ) / σ

x = count of a specific visit type (e.g. Checkup = 12)
μ = mean count across all visit types
σ = standard deviation

Z > 1.0  → HIGH DEMAND   (significantly above average)
Z between -1 and 1 → NORMAL
Z < -1.0  → UNDERUTILIZED (significantly below average)
```

### What to Show
A table/card for each visit type:

| Visit Type | Bookings | Z-Score | Classification |
|---|---|---|---|
| Checkup | 42 | +1.8 | 🔴 HIGH DEMAND |
| Vaccination | 28 | +0.3 | 🟡 NORMAL |
| Grooming | 6 | -1.1 | 🟢 UNDERUTILIZED |
| Surgery | 2 | -1.6 | 🟢 UNDERUTILIZED |

### Dart Implementation
```dart
List<Map<String, dynamic>> classifyVisitTypes(Map<String, int> typeCounts) {
  final values = typeCounts.values.map((v) => v.toDouble()).toList();
  final mean = values.reduce((a, b) => a + b) / values.length;
  final variance = values.map((v) => (v - mean) * (v - mean)).reduce((a, b) => a + b) / values.length;
  final stdDev = sqrt(variance);

  return typeCounts.entries.map((entry) {
    final z = stdDev == 0 ? 0.0 : (entry.value - mean) / stdDev;
    final label = z > 1.0 ? 'High Demand' : z < -1.0 ? 'Underutilized' : 'Normal';
    return {'type': entry.key, 'count': entry.value, 'z': z, 'label': label};
  }).toList();
}
```

---

## Files to Create / Edit When Resuming

| Action | File |
|---|---|
| **[NEW]** Statistics widget | `lib/pages/vet/widgets/demand_forecast_widget.dart` |
| **[EDIT]** Add widget to dashboard | `lib/pages/vet/vet_dashboard_page.dart` |
| **[EDIT]** Add Firestore helper to group appointments by week | `lib/services/firestore_service.dart` |

---

## Dependencies Needed
- `fl_chart` is already in the project (used by descriptive analytics) ✅
- `dart:math` for `sqrt()` — built-in, no install needed ✅

---

> 💡 **Resume note:** Once you have more real appointment data in Firestore (at least 4+ weeks worth), the SLR line will be much more visually convincing for the defense demo. Consider seeding some test data before the demo.
