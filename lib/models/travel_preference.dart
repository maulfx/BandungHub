class TravelPreference {
  final List<String> preferredCategories;
  final double maxBudgetPerPerson;
  final int durationDays;
  final int numberOfPeople;
  final List<String> interests;

  const TravelPreference({
    this.preferredCategories = const ['Alam', 'Kuliner'],
    this.maxBudgetPerPerson = 50000.0,
    this.durationDays = 1,
    this.numberOfPeople = 2,
    this.interests = const ['Spot Foto', 'Santai'],
  });

  TravelPreference copyWith({
    List<String>? preferredCategories,
    double? maxBudgetPerPerson,
    int? durationDays,
    int? numberOfPeople,
    List<String>? interests,
  }) {
    return TravelPreference(
      preferredCategories: preferredCategories ?? this.preferredCategories,
      maxBudgetPerPerson: maxBudgetPerPerson ?? this.maxBudgetPerPerson,
      durationDays: durationDays ?? this.durationDays,
      numberOfPeople: numberOfPeople ?? this.numberOfPeople,
      interests: interests ?? this.interests,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'preferred_categories': preferredCategories.join(','),
      'max_budget_per_person': maxBudgetPerPerson,
      'duration_days': durationDays,
      'number_of_people': numberOfPeople,
      'interests': interests.join(','),
    };
  }

  factory TravelPreference.fromMap(Map<String, dynamic> map) {
    return TravelPreference(
      preferredCategories:
          (map['preferred_categories'] as String?)
              ?.split(',')
              .where((c) => c.trim().isNotEmpty)
              .toList() ??
          const ['Alam'],
      maxBudgetPerPerson:
          (map['max_budget_per_person'] as num?)?.toDouble() ?? 50000.0,
      durationDays: (map['duration_days'] as num?)?.toInt() ?? 1,
      numberOfPeople: (map['number_of_people'] as num?)?.toInt() ?? 2,
      interests:
          (map['interests'] as String?)
              ?.split(',')
              .where((i) => i.trim().isNotEmpty)
              .toList() ??
          const [],
    );
  }
}
