/// Model representing vision intelligence output from authorized screen captures.
class ScreenAnalysisModel {
  final String query;
  final int width;
  final int height;
  final String analysis;
  final List<String> suggestions;
  final DateTime analyzedAt;

  ScreenAnalysisModel({
    required this.query,
    required this.width,
    required this.height,
    required this.analysis,
    this.suggestions = const [],
    DateTime? analyzedAt,
  }) : analyzedAt = analyzedAt ?? DateTime.now().toUtc();

  factory ScreenAnalysisModel.fromJson(Map<String, dynamic> json) {
    int w = 0;
    int h = 0;
    if (json['dimensions'] is Map) {
      w = json['dimensions']['width'] is int ? json['dimensions']['width'] as int : 0;
      h = json['dimensions']['height'] is int ? json['dimensions']['height'] as int : 0;
    }

    List<String> sugg = [];
    if (json['suggestions'] is List) {
      sugg = (json['suggestions'] as List).map((e) => e.toString()).toList();
    }

    return ScreenAnalysisModel(
      query: json['query']?.toString() ?? '',
      width: w,
      height: h,
      analysis: json['analysis']?.toString() ?? '',
      suggestions: sugg,
    );
  }

  String get resolutionDisplay => width > 0 && height > 0 ? '${width}x$height px' : 'Screen Capture';
}
