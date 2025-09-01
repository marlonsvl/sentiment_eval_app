import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/sentence.dart';
import '../models/evaluation.dart';
import '../models/user.dart';
import '../models/evaluation_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl =
      'https://sentiment-eval-backend.onrender.com/api';

  static const String tokenKey = 'auth_token';

  // Singleton pattern
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  // Get stored token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }

  // Store token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  // Clear token
  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
  }

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders([
    Map<String, String>? additionalHeaders,
  ]) async {
    final token = await getToken();

    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Token $token';
    }

    if (additionalHeaders != null) {
      headers.addAll(additionalHeaders);
    }

    return headers;
  }

  // Handle HTTP responses
  dynamic _handleResponse(http.Response response) {
    switch (response.statusCode) {
      case 200:
      case 201:
        return json.decode(response.body);
      case 401:
        throw UnauthorizedException(
          'Authentication failed. Please login again.',
        );
      case 403:
        throw Exception('Access forbidden: ${response.body}');
      case 404:
        throw Exception('Resource not found: ${response.body}');
      case 500:
        throw Exception('Server error: ${response.body}');
      default:
        throw Exception('HTTP Error ${response.statusCode}: ${response.body}');
    }
  }

  // Login method
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login/'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'username': username, 'password': password}),
      );

      final data = _handleResponse(response);

      // Store token
      if (data['token'] != null) {
        await setToken(data['token']);
      }

      return data;
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Logout method
  Future<void> logout() async {
    try {
      final headers = await _getHeaders();
      await http.post(Uri.parse('$baseUrl/logout/'), headers: headers);
    } catch (e) {
      print('Logout error: $e');
    } finally {
      // Always clear token even if logout request fails
      await clearToken();
    }
  }

  // Updated getSessions method in ApiService
  Future<List<EvaluationSession>> getSessions({String? evaluatorId}) async {
    try {
      final queryParams = <String, String>{};
      if (evaluatorId != null) {
        queryParams['evaluator_id'] = evaluatorId;
      }

      final uri = Uri.parse(
        '$baseUrl/sessions/',
      ).replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);
      final data = _handleResponse(response);

      // Handle both paginated and non-paginated responses
      final List<dynamic> results = data is List
          ? data
          : (data['results'] ?? data);

      // Parse each session with error handling
      final List<EvaluationSession> sessions = [];
      for (int i = 0; i < results.length; i++) {
        try {
          final session = EvaluationSession.fromJson(
            results[i] as Map<String, dynamic>,
          );
          sessions.add(session);
        } catch (e) {
          print('Error parsing session at index $i: $e');
          print('Session data: ${results[i]}');
          // Continue parsing other sessions instead of failing completely
          continue;
        }
      }

      return sessions;
    } catch (e) {
      print('Error in getSessions: $e');
      rethrow;
    }
  }

  // Start a new session
  Future<EvaluationSession> startSession() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/sessions/start_session/'),
        headers: headers,
      );

      final data = _handleResponse(response);
      return EvaluationSession.fromJson(data);
    } catch (e) {
      print('Error starting session: $e');
      rethrow;
    }
  }

  // Get sentences
  /*Future<List<Sentence>> getSentences({
    String? reviewId,
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (reviewId != null) {
        queryParams['review__review_id'] = reviewId;
      }

      final uri = Uri.parse(
        '$baseUrl/sentences/',
      ).replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);
      final data = _handleResponse(response);

      final List<dynamic> results = data['results'] ?? data;
      return results.map((json) => Sentence.fromJson(json)).toList();
    } catch (e) {
      print('Error in getSentences: $e');
      rethrow;
    }
  }*/
  Future<List<Sentence>> getSentences({
    String? reviewId,
    int page = 1,
    int pageSize = 20,
    bool unevaluatedOnly = true, // New parameter
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      if (reviewId != null) {
        queryParams['review__review_id'] = reviewId;
      }

      if (unevaluatedOnly) {
        queryParams['unevaluated_only'] = 'true';
      }

      final uri = Uri.parse(
        '$baseUrl/sentences/',
      ).replace(queryParameters: queryParams);
      final headers = await _getHeaders();

      final response = await http.get(uri, headers: headers);
      final data = _handleResponse(response);

      final List<dynamic> results = data['results'] ?? data;
      print('Fetched ${results.length} sentences');
      return results.map((json) => Sentence.fromJson(json)).toList();
    } catch (e) {
      print('Error in getSentences: $e');
      rethrow;
    }
  }

  // New method specifically for unevaluated sentences
  Future<List<Sentence>> getUnevaluatedSentences({
    int page = 1,
    int pageSize = 100,
  }) async {
    try {
      final headers = await _getHeaders();
      final queryParams = <String, String>{
        'page': page.toString(),
        'page_size': pageSize.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/sentences/unevaluated/',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 204) {
        return []; // No unevaluated sentences
      }

      final data = _handleResponse(response);
      final List<dynamic> results = data['results'] ?? data;
      print('Fetched Unevaluated ${results.length} sentences');
      return results.map((json) => Sentence.fromJson(json)).toList();
    } catch (e) {
      print('Error getting unevaluated sentences: $e');
      rethrow;
    }
  }

  // Alternative: Get next unevaluated sentence (one at a time)
  Future<Sentence?> getNextUnevaluatedSentence() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sentences/next_unevaluated/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return null; // No more sentences to evaluate
      }

      final data = _handleResponse(response);
      return Sentence.fromJson(data);
    } catch (e) {
      print('Error getting next unevaluated sentence: $e');
      rethrow;
    }
  }

  // Get evaluation statistics
  Future<Map<String, dynamic>> getEvaluationStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/evaluations/my_stats/'),
        headers: headers,
      );
      print('Evaluation stats response: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      print('Error getting evaluation stats: $e');
      rethrow;
    }
  }

  // Get next sentence for evaluation
  Future<Sentence?> getNextSentenceForEvaluation() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/sentences/next_for_evaluation/'),
        headers: headers,
      );

      if (response.statusCode == 204) {
        return null; // No more sentences to evaluate
      }

      final data = _handleResponse(response);
      return Sentence.fromJson(data);
    } catch (e) {
      print('Error getting next sentence: $e');
      rethrow;
    }
  }

  // Submit evaluation
  /*Future<Evaluation> submitEvaluation({
    required String id,
    required String bestModel,
    required String evaluatorId,
    String? comments,
    String? alternativeSolution,
    int? evaluationTimeSeconds,
  }) async {
    try {
      final headers = await _getHeaders();

      final Map<String, dynamic> body = {
        'sentence': id,
        //'best_model': bestModel,
        'evaluator': evaluatorId,
      };

      if (comments != null && comments.isNotEmpty) {
        body['notes'] = comments;
      }

      if (alternativeSolution != null && alternativeSolution.isNotEmpty) {
        body['alternative_solution'] = alternativeSolution;
      } else {
        body['best_model'] = bestModel;
      }

      if (evaluationTimeSeconds != null) {
        body['evaluation_time_seconds'] = evaluationTimeSeconds;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/evaluations/'),
        headers: headers,
        body: json.encode(body),
      );

      final data = _handleResponse(response);

      // Add debug logging to see what the server returns
      print('Response data: $data');

      // Check for null values in critical fields
      print(
        'evaluation_time_seconds value: ${data['evaluation_time_seconds']}',
      );
      print(
        'evaluation_time_seconds type: ${data['evaluation_time_seconds'].runtimeType}',
      );

      return Evaluation.fromJson(data);
    } catch (e) {
      print('Error submitting evaluation: $e');
      rethrow;
    }
  }*/
  Future<Evaluation> submitEvaluation({
    required String id,
    required String bestModel,
    required String evaluatorId,
    String? comments,
    String? alternativeSolution,
    int? evaluationTimeSeconds,
  }) async {
    try {
      final headers = await _getHeaders();

      // Ensure evaluation_time_seconds is never null
      final int safeEvaluationTime = evaluationTimeSeconds ?? 0;

      final Map<String, dynamic> body = {
        'sentence': id,
        'evaluator': evaluatorId,
        'best_model': bestModel,
        'evaluation_time_seconds': safeEvaluationTime,
      };

      if (comments != null && comments.isNotEmpty) {
        body['notes'] = comments;
      }

      // Send alternative solution separately, NOT as best_model

      if (alternativeSolution != null && alternativeSolution.isNotEmpty) {
        body['alternative_solution'] = alternativeSolution;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/evaluations/'),
        headers: headers,
        body: json.encode(body),
      );

      final data = _handleResponse(response);

      debugPrint('✅ Evaluation submitted: $data');

      if (data['evaluation_time_seconds'] == null) {
        throw Exception("Server did not return evaluation_time_seconds");
      }

      return Evaluation.fromJson(data);
    } catch (e, stack) {
      debugPrint('❌ Error submitting evaluation: $e');
      debugPrint(stack.toString());
      rethrow;
    }
  }

  // Check if authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  // Get current user
  Future<User?> getCurrentUser() async {
    try {
      if (!(await isAuthenticated())) {
        return null;
      }

      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/current-user/'),
        headers: headers,
      );

      final data = _handleResponse(response);
      return User.fromJson(data);
    } catch (e) {
      print('Error getting current user: $e');
      // If unauthorized, clear token
      if (e is UnauthorizedException) {
        await clearToken();
      }
      return null;
    }
  }
}

// Custom exceptions
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);

  @override
  String toString() => 'UnauthorizedException: $message';
}
