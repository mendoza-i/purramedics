# Vet Analytics — Descriptive & Predictive

**Purpose**
- Summarize clinic activity and provide short-term risk advice for actionable decisions.

**Data Sources**
- Firestore appointment documents (streamed via `FirestoreService`).
- Open‑Meteo API for live weather (forecast + current conditions).

**Descriptive (What it does)**
- Input: `getAllAppointmentsStream()` or per-user streams.
- Windowing: Buckets appointments into a 7-day window starting Sunday (client local time).
- Aggregations: weekly counts, visit-type frequency, all-time busiest weekday, lifetime appointment count.
- Visualization: Smooth line chart (CustomPainter) + animated ratio bars.
- Key files: lib/pages/vet/widgets/descriptive_analytics_widget.dart, lib/pages/vet/analytics_details_page.dart

**Predictive / Heuristic (What it does)**
- Live fetch: calls Open‑Meteo for `temperature`, `apparent_temperature`, `weather_code`.
- Rule engine: maps WMO `weather_code` → description, uses temperature & month-based heuristics to set `_risk` and `_advice`.
- Fallback: month-based historical seasonal rules when live data is unavailable.
- Output: risk label, short prevention advice, monthly disease & supplies suggestions.
- Key file: lib/pages/vet/widgets/seasonal_forecast_widget.dart

**Limitations & Notes**
- Timezone: Uses `Timestamp.toDate()` vs `DateTime.now()` — may misalign across timezones.
- Missing data: Appointments without `createdAt` are ignored by analytics.
- Chart scaling: minimum ceiling applied (e.g., `maxVal < 5 => 5`) for low volumes.
- Hardcoded location: seasonal forecast uses a fixed lat/lon — update to clinic location for accuracy.
- Predictive part is deterministic heuristics (not ML).

**Quick wins / Next steps**
- Normalize timestamps/timezones on ingestion; ensure `createdAt` is always set.
- Persist aggregated metrics in Firestore for fast historical queries.
- If >6–12 months of history, consider a lightweight time-series model for forecasting.

**Suggested screenshots for slide**
- Vet Dashboard showing both cards: lib/pages/vet/vet_dashboard_page.dart
- Descriptive detail page line chart: lib/pages/vet/analytics_details_page.dart
- Predictive forecast card & popup: lib/pages/vet/widgets/seasonal_forecast_widget.dart

---
Generated: Vet Analytics slide source
