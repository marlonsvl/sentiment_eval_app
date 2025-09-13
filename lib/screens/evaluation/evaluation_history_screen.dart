// lib/screens/evaluation_history_screen.dart

import 'package:flutter/material.dart';
import '../../screens/evaluation/edit_evaluation_scree.dart';
import '../../services/api_service.dart';
import '../../models/evaluation.dart';

class EvaluationHistoryScreen extends StatefulWidget {
  const EvaluationHistoryScreen({Key? key}) : super(key: key);

  @override
  State<EvaluationHistoryScreen> createState() =>
      _EvaluationHistoryScreenState();
}

class _EvaluationHistoryScreenState extends State<EvaluationHistoryScreen> {
  final ApiService _evaluationService = ApiService();
  List<Evaluation> _evaluations = [];
  bool _isLoading = true;
  String? _error;
  int _currentPage = 1;
  bool _hasMoreData = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadEvaluations();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels ==
        _scrollController.position.maxScrollExtent) {
      if (_hasMoreData && !_isLoading) {
        _loadMoreEvaluations();
      }
    }
  }

  Future<void> _loadEvaluations() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final evaluations = await _evaluationService.getMyEvaluations(page: 1);

      setState(() {
        _evaluations = evaluations;
        _currentPage = 1;
        _hasMoreData = evaluations.length >= 20; // Assuming 20 is page size
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreEvaluations() async {
    try {
      final nextPage = _currentPage + 1;
      final newEvaluations = await _evaluationService.getMyEvaluations(
        page: nextPage,
      );

      setState(() {
        _evaluations.addAll(newEvaluations);
        _currentPage = nextPage;
        _hasMoreData = newEvaluations.length >= 20;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading more evaluations: $e')),
      );
    }
  }

  void _editEvaluation(Evaluation evaluation) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditEvaluationScreen(evaluation: evaluation),
      ),
    );

    if (result == true) {
      _loadEvaluations(); // Refresh the list
    }
  }

  void _deleteEvaluation(Evaluation evaluation) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Evaluation'),
        content: const Text('Are you sure you want to delete this evaluation?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _evaluationService.deleteEvaluation(evaluation.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation deleted successfully')),
        );
        _loadEvaluations(); // Refresh the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting evaluation: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Evaluations'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _loadEvaluations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _evaluations.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _evaluations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadEvaluations,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_evaluations.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assessment, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('No evaluations found', style: TextStyle(fontSize: 18)),
            SizedBox(height: 8),
            Text('Start evaluating sentences to see them here!'),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEvaluations,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _evaluations.length + (_hasMoreData ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _evaluations.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(),
              ),
            );
          }

          final evaluation = _evaluations[index];
          return _buildEvaluationCard(evaluation);
        },
      ),
    );
  }

  Widget _buildEvaluationCard(Evaluation evaluation) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Sentence ID: ${evaluation.sentence?.sentenceId}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'edit') {
                      _editEvaluation(evaluation);
                    } else if (value == 'delete') {
                      _deleteEvaluation(evaluation);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              evaluation.sentence!.reviewText,
              style: TextStyle(color: Colors.grey.shade700),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildModelChip(evaluation.bestModel),
                const Spacer(),
                Text(
                  _formatDate(evaluation.updatedAt),
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            if (evaluation.alternativeSolution?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Alternative: ${evaluation.alternativeSolution}',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (evaluation.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.note, size: 16, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Notes: ${evaluation.notes}',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildModelChip(String model) {
    Color color;
    String label;

    switch (model) {
      case 'gpt4':
        color = Colors.green;
        label = 'GPT-4';
        break;
      case 'gemini':
        color = Colors.blue;
        label = 'Gemini';
        break;
      case 'perplexity':
        color = Colors.purple;
        label = 'Perplexity';
        break;
      case 'none':
        color = Colors.orange;
        label = 'Alternative';
        break;
      default:
        color = Colors.grey;
        label = model.toUpperCase();
    }

    return Chip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
      backgroundColor: color,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
}
