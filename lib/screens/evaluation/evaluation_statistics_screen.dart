import 'package:flutter/material.dart';
import '../../models/sentence.dart';
import '../../services/api_service.dart';
import '../../models/evaluation.dart';

class EvaluationStatisticsScreen extends StatefulWidget {
  const EvaluationStatisticsScreen({super.key});

  @override
  State<EvaluationStatisticsScreen> createState() =>
      _EvaluationStatisticsScreenState();
}

class _EvaluationStatisticsScreenState
    extends State<EvaluationStatisticsScreen> {
  List<Evaluation> _evaluations = [];
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, int> _modelStats = {};
  int _totalEvaluations = 0;
  int _alternativeSolutions = 0;

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use singleton instance instead of Provider
      final apiService = ApiService();

      // Load all evaluated sentences for statistics
      // Note: You might want to implement pagination to handle large datasets
      final List<Sentence> allEvaluatedSentences = [];
      int currentPage = 1;
      const int pageSize = 100; // Load in batches to avoid memory issues

      while (true) {
        final sentences = await apiService.getSentences(
          page: currentPage,
          pageSize: pageSize,
          // If you've enhanced getSentences to support 'evaluated' filter:
          // evaluated: true,
        );

        if (sentences.isEmpty) {
          break; // No more sentences to load
        }

        // If getSentences doesn't support evaluated filter,
        // you'll need to filter here (not ideal for large datasets):
        // final evaluatedSentences = sentences.where((s) => s.isEvaluated).toList();
        // allEvaluatedSentences.addAll(evaluatedSentences);

        allEvaluatedSentences.addAll(sentences);

        // If we got fewer sentences than requested, we've reached the end
        if (sentences.length < pageSize) {
          break;
        }

        currentPage++;

        // Safety check to prevent infinite loops
        if (currentPage > 50) {
          // Adjust based on your expected data size
          print(
            'Warning: Loaded more than 5000 sentences, stopping to prevent memory issues',
          );
          break;
        }
      }

      _calculateStatistics(allEvaluatedSentences);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load statistics: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics(List sentences) {
    final modelStats = <String, int>{};
    int alternativeSolutions = 0;

    for (final sentence in sentences) {
      if (sentence.bestModel != null) {
        modelStats[sentence.bestModel!] =
            (modelStats[sentence.bestModel!] ?? 0) + 1;
      } else if (sentence.alternativeSolution != null) {
        alternativeSolutions++;
      }
    }

    setState(() {
      _modelStats = modelStats;
      _totalEvaluations = sentences.length;
      _alternativeSolutions = alternativeSolutions;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Evaluation Statistics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStatistics,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadStatistics,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overall statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Overall Statistics',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatItem(
                        'Total Evaluations',
                        _totalEvaluations.toString(),
                      ),
                      _buildStatItem(
                        'Alternative Solutions',
                        _alternativeSolutions.toString(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Model performance
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Model Performance',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ..._modelStats.entries.map(
                    (entry) =>
                        _buildModelPerformanceItem(entry.key, entry.value),
                  ),
                  if (_alternativeSolutions > 0)
                    _buildModelPerformanceItem(
                      'None (Alternative)',
                      _alternativeSolutions,
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
        Text(label, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildModelPerformanceItem(String modelName, int count) {
    final percentage = _totalEvaluations > 0
        ? (count / _totalEvaluations * 100).toStringAsFixed(1)
        : '0.0';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              _getModelDisplayName(modelName),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: LinearProgressIndicator(
              value: _totalEvaluations > 0 ? count / _totalEvaluations : 0,
              backgroundColor: Colors.grey[300],
            ),
          ),
          const SizedBox(width: 8),
          Text('$count ($percentage%)'),
        ],
      ),
    );
  }

  String _getModelDisplayName(String modelKey) {
    switch (modelKey) {
      case 'gpt4':
        return 'GPT-4';
      case 'gemini':
        return 'Gemini Flash 2.5';
      case 'perplexity':
        return 'Perplexity';
      case 'None (Alternative)':
        return 'Alternative Solution';
      default:
        return modelKey;
    }
  }
}
