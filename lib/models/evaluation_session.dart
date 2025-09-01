class EvaluationSession {
  final String id;
  final String evaluator;
  final String evaluatorName;
  final int totalSentences;
  final int completedSentences;
  final double completionPercentage;
  final DateTime startedAt;
  final DateTime lastActivity;
  final DateTime? completedAt;
  final bool isActive;

  EvaluationSession({
    required this.id,
    required this.evaluator,
    required this.evaluatorName,
    required this.totalSentences,
    required this.completedSentences,
    required this.completionPercentage,
    required this.startedAt,
    required this.lastActivity,
    this.completedAt,
    required this.isActive,
  });

  factory EvaluationSession.fromJson(Map<String, dynamic> json) {
    try {
      return EvaluationSession(
        id: _parseString(json['id'], 'id'),
        evaluator: _parseString(json['evaluator'], 'evaluator'),
        evaluatorName: _parseString(json['evaluator_name'], 'evaluator_name'),
        totalSentences: _parseInt(json['total_sentences'], 'total_sentences'),
        completedSentences: _parseInt(
          json['completed_sentences'],
          'completed_sentences',
        ),
        completionPercentage: _parseDouble(
          json['completion_percentage'],
          'completion_percentage',
        ),
        startedAt: _parseDateTime(json['started_at'], 'started_at'),
        lastActivity: _parseDateTime(json['last_activity'], 'last_activity'),
        completedAt: _parseNullableDateTime(json['completed_at']),
        isActive: _parseBool(json['is_active'], 'is_active'),
      );
    } catch (e) {
      throw FormatException(
        'Error parsing EvaluationSession from JSON: $e\nJSON: $json',
      );
    }
  }

  // Helper methods for safe parsing
  static String _parseString(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    return value.toString();
  }

  static int _parseInt(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is int) return value;
    if (value is String) return int.parse(value);
    if (value is double) return value.toInt();
    throw FormatException('Field $fieldName is not a valid integer: $value');
  }

  static double _parseDouble(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.parse(value);
    throw FormatException('Field $fieldName is not a valid double: $value');
  }

  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is String) {
      return DateTime.parse(value);
    }
    throw FormatException(
      'Field $fieldName is not a valid DateTime string: $value',
    );
  }

  static DateTime? _parseNullableDateTime(dynamic value) {
    if (value == null) return null;
    if (value is String) {
      return DateTime.parse(value);
    }
    throw FormatException(
      'DateTime field is not a valid DateTime string: $value',
    );
  }

  static bool _parseBool(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) return value != 0;
    throw FormatException('Field $fieldName is not a valid boolean: $value');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'evaluator': evaluator,
      'evaluator_name': evaluatorName,
      'total_sentences': totalSentences,
      'completed_sentences': completedSentences,
      'completion_percentage': completionPercentage,
      'started_at': startedAt.toIso8601String(),
      'last_activity': lastActivity.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  // Convenience getters
  String get sessionName => 'Session ${id.substring(0, 8)}...';
  double get progress => completionPercentage / 100.0;
  bool get isCompleted => completedAt != null;
  String get statusText {
    if (isCompleted) return 'Completed';
    if (isActive) return 'Active';
    return 'Paused';
  }

  String get formattedStartDate {
    return '${startedAt.day}/${startedAt.month}/${startedAt.year}';
  }
}
