import 'destination.dart';

class LandmarkScanResult {
  final bool isBandungLandmark;
  final String landmarkName;
  final int confidencePercent;
  final String category;
  final String shortDescription;
  final String historyFact;
  final String interestingTrivia;
  final List<String> recommendedThingsToDo;
  final Destination? matchedDestination;

  const LandmarkScanResult({
    required this.isBandungLandmark,
    required this.landmarkName,
    required this.confidencePercent,
    required this.category,
    required this.shortDescription,
    required this.historyFact,
    required this.interestingTrivia,
    required this.recommendedThingsToDo,
    this.matchedDestination,
  });

  factory LandmarkScanResult.fromMap(
    Map<String, dynamic> map, {
    Destination? matchedDestination,
  }) {
    return LandmarkScanResult(
      isBandungLandmark: map['isBandungLandmark'] as bool? ?? true,
      landmarkName: map['landmarkName'] as String? ?? 'Objek Wisata Bandung',
      confidencePercent: (map['confidencePercent'] as num?)?.toInt() ?? 94,
      category: map['category'] as String? ?? 'Wisata Populer',
      shortDescription:
          map['shortDescription'] as String? ??
          'Objek wisata ikonik di kawasan Bandung Raya.',
      historyFact:
          map['historyFact'] as String? ??
          'Tempat ini memiliki nilai historis dan daya tarik arsitektur terkemuka di Kota Bandung.',
      interestingTrivia:
          map['interestingTrivia'] as String? ??
          'Destinasi favorit wisatawan lokal maupun mancanegara.',
      recommendedThingsToDo:
          (map['recommendedThingsToDo'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['Berfoto di spot terbaik', 'Mempelajari sejarah setempat', 'Mencoba kuliner sekitar'],
      matchedDestination: matchedDestination,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isBandungLandmark': isBandungLandmark,
      'landmarkName': landmarkName,
      'confidencePercent': confidencePercent,
      'category': category,
      'shortDescription': shortDescription,
      'historyFact': historyFact,
      'interestingTrivia': interestingTrivia,
      'recommendedThingsToDo': recommendedThingsToDo,
    };
  }
}
