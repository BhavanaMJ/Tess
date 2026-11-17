/// Model encapsulating the outcome of an executed Agent Plan.
class AgentExecutionResultModel {
  final String status; // success, failed
  final List<dynamic> results;
  final String? error;
  final DateTime executedAt;

  AgentExecutionResultModel({
    required this.status,
    this.results = const [],
    this.error,
    DateTime? executedAt,
  }) : executedAt = executedAt ?? DateTime.now().toUtc();

  factory AgentExecutionResultModel.fromJson(Map<String, dynamic> json) {
    return AgentExecutionResultModel(
      status: json['status']?.toString() ?? 'success',
      results: json['results'] is List ? json['results'] as List : [],
      error: json['error']?.toString(),
    );
  }

  factory AgentExecutionResultModel.failure(String errorMessage) {
    return AgentExecutionResultModel(
      status: 'failed',
      error: errorMessage,
    );
  }

  bool get isSuccess => status == 'success' && error == null;
}
