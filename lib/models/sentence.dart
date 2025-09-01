class Sentence {
  final String id;
  final String text;
  final String reviewText;
  final int reviewId;
  final String gpt4Prediction;
  final String geminiPrediction;
  final String perplexityPrediction;
  final bool isEvaluated;
  final String? bestModel;
  final String? alternativeSolution;

  Sentence({
    required this.id,
    required this.text,
    required this.reviewText,
    required this.reviewId,
    required this.gpt4Prediction,
    required this.geminiPrediction,
    required this.perplexityPrediction,
    this.isEvaluated = false,
    this.bestModel,
    this.alternativeSolution,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    try {
      return Sentence(
        id: _parseString(json['id'], 'id'),
        text: _parseString(json['review_sentence'], 'review_sentence'),
        reviewText: _parseString(json['review_text'] ?? '', 'review_text'),
        reviewId: _parseInt(json['review_id'], 'review_id'),
        gpt4Prediction: _parseString(
          json['gpt4_prediction'] ?? '',
          'gpt4_prediction',
        ),
        geminiPrediction: _parseString(
          json['gemini_prediction'] ?? '',
          'gemini_prediction',
        ),
        perplexityPrediction: _parseString(
          json['perplexity_prediction'] ?? '',
          'perplexity_prediction',
        ),
        isEvaluated: _parseBool(json['is_evaluated'] ?? false, 'is_evaluated'),
        bestModel: _parseNullableString(json['best_model']),
        alternativeSolution: _parseNullableString(json['alternative_solution']),
      );
    } catch (e) {
      throw FormatException(
        'Error parsing Sentence from JSON: $e\nJSON: $json',
      );
    }
  }

  // Helper methods for safe parsing
  static int _parseInt(dynamic value, String fieldName) {
    if (value == null) {
      throw FormatException('Field $fieldName is null');
    }
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      // Handle string numbers like "1.0" or "1"
      final doubleValue = double.tryParse(value);
      if (doubleValue != null) {
        return doubleValue.toInt();
      }
      throw FormatException('Field $fieldName is not a valid integer: $value');
    }
    throw FormatException('Field $fieldName is not a valid integer: $value');
  }

  static String _parseString(dynamic value, String fieldName) {
    if (value == null) {
      return ''; // Return empty string for null values
    }
    return value.toString();
  }

  static String? _parseNullableString(dynamic value) {
    if (value == null) return null;
    return value.toString();
  }

  static bool _parseBool(dynamic value, String fieldName) {
    if (value == null) {
      return false; // Default to false for null values
    }
    if (value is bool) return value;
    if (value is String) {
      return value.toLowerCase() == 'true';
    }
    if (value is int) return value != 0;
    return false; // Default to false for unexpected types
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'review_sentence': text,
      'review_text': reviewText,
      'review_id': reviewId,
      'gpt4_prediction': gpt4Prediction,
      'gemini_prediction': geminiPrediction,
      'perplexity_prediction': perplexityPrediction,
      'is_evaluated': isEvaluated,
      'best_model': bestModel,
      'alternative_solution': alternativeSolution,
    };
  }
}
