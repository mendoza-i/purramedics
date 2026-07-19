/// ============================================================================
/// LINEAR REGRESSION MODEL
/// ============================================================================
/// A statistical utility to predict future values based on historical data.
/// Specifically used in Purramedics to forecast patient traffic.
///
/// Formula used: Least Squares Method
/// y = mx + b
/// where 'm' is the slope, and 'b' is the intercept.
/// ============================================================================
class LinearRegression {
  final double slope;
  final double intercept;

  LinearRegression({required this.slope, required this.intercept});

  /// Calculates the slope and intercept given a set of x (e.g. days) and y (e.g. patient counts)
  static LinearRegression calculate(List<double> x, List<double> y) {
    if (x.isEmpty || y.isEmpty || x.length != y.length) {
      return LinearRegression(slope: 0, intercept: 0); // Fallback for invalid data
    }

    int n = x.length;
    double sumX = 0;
    double sumY = 0;
    double sumXY = 0;
    double sumXX = 0;

    for (int i = 0; i < n; i++) {
      sumX += x[i];
      sumY += y[i];
      sumXY += x[i] * y[i];
      sumXX += x[i] * x[i];
    }

    // Denominator check to prevent division by zero (e.g., if all x values are the same)
    double denominator = (n * sumXX) - (sumX * sumX);
    if (denominator == 0) {
      return LinearRegression(slope: 0, intercept: (sumY / n)); // Just return the average
    }

    // Calculate slope (m)
    double slope = ((n * sumXY) - (sumX * sumY)) / denominator;

    // Calculate intercept (b)
    double intercept = (sumY - (slope * sumX)) / n;

    return LinearRegression(slope: slope, intercept: intercept);
  }

  /// Predicts the y value for a given x value using y = mx + b
  double predict(double x) {
    return (slope * x) + intercept;
  }
}
