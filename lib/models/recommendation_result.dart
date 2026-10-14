import 'destination.dart';

class RecommendationResult {
  final Destination destination;
  final double score; // 0.0 to 100.0
  final List<String> reasons;
  final double totalEstimatedBudget;

  const RecommendationResult({
    required this.destination,
    required this.score,
    required this.reasons,
    required this.totalEstimatedBudget,
  });

  int get scorePercentage => score.round().clamp(0, 100);
}
