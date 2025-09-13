import 'sentence.dart';

class Evaluation {
  final String id;
  final String sentenceId;
  final String evaluatorId;
  final String? evaluatorName;
  final String? sentenceText;
  final String bestModel;
  final String? alternativeSolution;
  final String? notes;
  final int? evaluationTimeSeconds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Sentence?
  sentence; // Made nullable since we might not always have full sentence data

  Evaluation({
    required this.id,
    required this.sentenceId,
    required this.evaluatorId,
    this.evaluatorName,
    this.sentenceText,
    required this.bestModel,
    this.alternativeSolution,
    this.notes,
    this.evaluationTimeSeconds,
    required this.createdAt,
    required this.updatedAt,
    this.sentence,
  });

  factory Evaluation.fromJson(Map<String, dynamic> json) {
    try {
      // Handle sentence field - it can be either a string (UUID) or an object
      String sentenceId;
      Sentence? sentence;

      final sentenceField = json['sentence'];
      if (sentenceField is String) {
        // If sentence is just a UUID string
        sentenceId = sentenceField;
        sentence = null;
      } else if (sentenceField is Map<String, dynamic>) {
        // If sentence is a full object
        sentence = Sentence.fromJson(sentenceField);
        sentenceId = sentence.id;
      } else if (sentenceField == null) {
        // Handle case where sentence field is null
        sentenceId = _parseString(
          json['sentence_id'] ?? json['sentenceId'],
          'sentenceId',
        );
        sentence = null;
      } else {
        throw FormatException(
          'Invalid sentence field format: $sentenceField (type: ${sentenceField.runtimeType})',
        );
      }

      return Evaluation(
        id: _parseString(json['id'], 'id'),
        sentenceId: sentenceId,
        evaluatorId: _parseString(json['evaluator'], 'evaluator'),
        evaluatorName: _parseNullableString(json['evaluator_name']),
        sentenceText: _parseNullableString(json['sentence_text']),
        bestModel: _parseString(json['best_model'], 'best_model'),
        alternativeSolution: _parseNullableString(json['alternative_solution']),
        notes: _parseNullableString(json['notes']),
        evaluationTimeSeconds: _parseNullableInt(
          json['evaluation_time_seconds'],
        ),
        createdAt: _parseDateTime(json['created_at'], 'created_at'),
        updatedAt: _parseDateTime(json['updated_at'], 'updated_at'),
        sentence: sentence,
      );
    } catch (e) {
      print('Error parsing Evaluation from JSON: $e');
      print('JSON keys: ${json.keys.toList()}');
      print('Sentence field type: ${json['sentence']?.runtimeType}');
      print('Sentence field value: ${json['sentence']}');
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

  static int? _parseNullableInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.toInt();
      }
      return null;
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
      'best_model': bestModel,
      'alternative_solution': alternativeSolution,
      'notes': notes,
      'evaluation_time_seconds': evaluationTimeSeconds,
    };
  }

  Map<String, dynamic> toFullJson() {
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

  Evaluation copyWith({
    String? bestModel,
    String? alternativeSolution,
    String? notes,
    int? evaluationTimeSeconds,
  }) {
    return Evaluation(
      id: id,
      sentenceId: sentenceId,
      evaluatorId: evaluatorId,
      evaluatorName: evaluatorName,
      sentenceText: sentenceText,
      bestModel: bestModel ?? this.bestModel,
      alternativeSolution: alternativeSolution ?? this.alternativeSolution,
      notes: notes ?? this.notes,
      evaluationTimeSeconds:
          evaluationTimeSeconds ?? this.evaluationTimeSeconds,
      createdAt: createdAt,
      updatedAt: updatedAt,
      sentence: sentence,
    );
  }
}
