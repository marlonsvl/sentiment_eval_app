class Evaluation {
  final String id;
  final String sentenceId;
  final String evaluatorId;
  final String? evaluatorName;
  final String? sentenceText;
  final String bestModel;
  final String? alternativeSolution;
  final String? notes;
  final int? evaluationTimeSeconds; // Made nullable
  final DateTime createdAt;
  final DateTime updatedAt;

  Evaluation({
    required this.id,
    required this.sentenceId,
    required this.evaluatorId,
    this.evaluatorName,
    this.sentenceText,
    required this.bestModel,
    this.alternativeSolution,
    this.notes,
    this.evaluationTimeSeconds, // Can be null
    required this.createdAt,
    required this.updatedAt,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    try {
      return Evaluation(
        id: _parseString(json['id'], 'id'),
        sentenceId: _parseString(json['sentence'], 'sentence'),
        evaluatorId: _parseString(json['evaluator'], 'evaluator'),
        evaluatorName: _parseNullableString(json['evaluator_name']),
        sentenceText: _parseNullableString(json['sentence_text']),
        bestModel: _parseString(json['best_model'], 'best_model'),
        alternativeSolution: _parseNullableString(json['alternative_solution']),
        notes: _parseNullableString(json['notes']),
        evaluationTimeSeconds: _parseNullableInt(
          json['evaluation_time_seconds'],
        ), // Use nullable parser
        createdAt: _parseDateTime(json['created_at'], 'created_at'),
        updatedAt: _parseDateTime(json['updated_at'], 'updated_at'),
      );
    } catch (e) {
      throw FormatException(
        'Error parsing Evaluation from JSON: $e\nJSON: $json',
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

  static String? _parseNullableString(dynamic value) {
    if (value == null || value == '') return null;
    return value.toString();
  }

  static int _parseInt(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.toInt();
      }
      throw FormatException('Field $fieldName is not a valid integer: $value');
    }
    throw FormatException('Field $fieldName is not a valid integer: $value');
  }

  // New method for nullable integers
  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.toInt();
      }
      return null; // Return null instead of throwing error
    }
    return null;
  }

  static DateTime _parseDateTime(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is String) {
      final dateTime = DateTime.tryParse(value);
      if (dateTime != null) return dateTime;
      throw FormatException('Field $fieldName is not a valid DateTime: $value');
    }
    throw FormatException('Field $fieldName is not a valid DateTime: $value');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sentence': sentenceId,
      'evaluator': evaluatorId,
      'evaluator_name': evaluatorName,
      'sentence_text': sentenceText,
      'best_model': bestModel,
      'alternative_solution': alternativeSolution,
      'notes': notes,
      'evaluation_time_seconds': evaluationTimeSeconds,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
