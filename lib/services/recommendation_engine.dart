import '../models/destination.dart';
import '../models/recommendation_result.dart';
import '../models/travel_preference.dart';

class RecommendationEngine {
  // Mapping interests to related tags and keywords
  static final Map<String, List<String>> interestKeywordMap = {
    'Spot Foto': [
      'spot foto',
      'fotografi',
      'art deco',
      'pemandangan',
      'sunrise',
    ],
    'Santai': ['santai', 'suasana', 'sejuk', 'citylight', 'danau'],
    'Petualangan Alam': [
      'gunung berapi',
      'kawah',
      'hutan pinus',
      'trekking',
      'alam',
      'pegunungan',
    ],
    'Kuliner Legendaris': [
      'street food',
      'kuliner malam',
      'kuliner',
      'nasi timbel',
      'jajanan',
      'kafe',
    ],
    'Edukasi & Budaya': [
      'heritage',
      'museum',
      'budaya',
      'edukasi',
      'angklung',
      'fosil',
      'dinosaurus',
      'pertunjukan',
    ],
    'Ramah Anak & Keluarga': [
      'keluarga',
      'wahana',
      'kota mini',
      'indoor theme park',
      'roller coaster',
    ],
  };

  static List<String> get availableInterests =>
      interestKeywordMap.keys.toList();

  static List<RecommendationResult> getRecommendations({
    required List<Destination> destinations,
    required TravelPreference preference,
  }) {
    final results = <RecommendationResult>[];

    for (final dest in destinations) {
      double score = 0.0;
      final reasons = <String>[];

      // 1. Category Matching (Max 35 points)
      final categoryMatched =
          preference.preferredCategories.isEmpty ||
          preference.preferredCategories.contains('Semua') ||
          preference.preferredCategories.any(
            (c) => c.toLowerCase() == dest.category.toLowerCase(),
          );

      if (categoryMatched) {
        score += 35.0;
        reasons.add('Kategori ${dest.category} sesuai preferensi utama Anda');
      } else {
        score += 5.0; // Minimal baseline
      }

      // 2. Budget Matching (Max 25 points)
      if (dest.estimatedPrice <= 0) {
        score += 25.0;
        reasons.add('Tiket masuk gratis, sangat menghemat anggaran Anda');
      } else if (dest.estimatedPrice <= preference.maxBudgetPerPerson) {
        final ratio = dest.estimatedPrice / preference.maxBudgetPerPerson;
        // Higher score if it's well within budget
        final budgetScore = 25.0 - (ratio * 5.0);
        score += budgetScore.clamp(18.0, 25.0);
        reasons.add(
          'Estimasi tiket (Rp ${dest.estimatedPrice.toInt()}) sesuai anggaran (≤ Rp ${preference.maxBudgetPerPerson.toInt()})',
        );
      } else {
        // Exceeds budget, penalize score
        final overRatio =
            (dest.estimatedPrice - preference.maxBudgetPerPerson) /
            preference.maxBudgetPerPerson;
        score += (10.0 - (overRatio * 15.0)).clamp(0.0, 10.0);
      }

      // 3. User Interests & Tag Matching (Max 25 points)
      final matchedInterests = <String>[];
      final destTagsLower = dest.tags.map((t) => t.toLowerCase()).toList();

      for (final interest in preference.interests) {
        final keywords =
            interestKeywordMap[interest] ?? [interest.toLowerCase()];
        bool hasMatch = keywords.any(
          (kw) =>
              destTagsLower.any(
                (tag) => tag.contains(kw) || kw.contains(tag),
              ) ||
              dest.description.toLowerCase().contains(kw) ||
              dest.name.toLowerCase().contains(kw),
        );

        if (hasMatch) {
          matchedInterests.add(interest);
        }
      }

      if (matchedInterests.isNotEmpty) {
        final pointsPerMatch =
            25.0 /
            (preference.interests.isEmpty ? 1 : preference.interests.length);
        final interestScore = (matchedInterests.length * pointsPerMatch).clamp(
          10.0,
          25.0,
        );
        score += interestScore;
        reasons.add('Cocok dengan minat: ${matchedInterests.join(', ')}');
      }

      // 4. Rating & Quality Bonus (Max 15 points)
      // Scale rating 4.0 - 5.0 to 5 - 12 points
      final ratingPoints = ((dest.rating - 3.5) / 1.5 * 12.0).clamp(0.0, 12.0);
      final verifiedPoints = dest.isVerified ? 3.0 : 0.0;
      score += (ratingPoints + verifiedPoints);

      if (dest.rating >= 4.6) {
        reasons.add(
          'Rating tinggi (${dest.rating.toStringAsFixed(1)}★ dari ${dest.reviewCount} ulasan)',
        );
      }

      // Calculate total budget for the whole group
      final groupBudget = dest.estimatedPrice * preference.numberOfPeople;

      // Ensure clamped between 10% and 99%
      final finalScore = score.clamp(15.0, 99.0);

      results.add(
        RecommendationResult(
          destination: dest,
          score: finalScore,
          reasons: reasons,
          totalEstimatedBudget: groupBudget,
        ),
      );
    }

    // Sort descending by score percentage
    results.sort((a, b) => b.score.compareTo(a.score));

    return results;
  }
}
