import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sentiment_eval_app/services/auth_service.dart';
import '../../services/api_service.dart';
import '../../models/sentence.dart';

class SentenceEvaluationScreen extends StatefulWidget {
  final String? sessionId;

  const SentenceEvaluationScreen({super.key, this.sessionId});

  @override
  State<SentenceEvaluationScreen> createState() =>
      _SentenceEvaluationScreenState();
}

class _SentenceEvaluationScreenState extends State<SentenceEvaluationScreen> {
  List<Sentence> _sentences = [];
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _errorMessage;
  String? _selectedModel;
  final _alternativeController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadSentences();
  }

  Future<void> _loadSentences() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Use singleton instance instead of Provider
      final apiService = ApiService();

      // Call getSentences with correct parameters
      final sentences = await apiService.getSentences(
        page: 1, // Start from page 1
        pageSize: 50, // Set page size to 50 (equivalent to your limit)
        // reviewId: null, // Optional: specify if you need sentences from specific review
      );

      setState(() {
        _sentences = sentences;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load sentences: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Evaluation ${_currentIndex + 1}/${_sentences.length}'),
        actions: [
          if (_sentences.isNotEmpty)
            TextButton(
              onPressed: _isSubmitting ? null : _skipSentence,
              child: const Text('Skip', style: TextStyle(color: Colors.white)),
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
              onPressed: _loadSentences,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_sentences.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, size: 64, color: Colors.green),
            SizedBox(height: 16),
            Text('All sentences have been evaluated!'),
          ],
        ),
      );
    }

    final sentence = _sentences[_currentIndex];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (_currentIndex + 1) / _sentences.length,
            backgroundColor: Colors.grey[300],
          ),
          const SizedBox(height: 24),

          // Review context
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Review Context:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(sentence.reviewText),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sentence to evaluate
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Sentence to Evaluate:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(sentence.text, style: const TextStyle(fontSize: 16)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Model predictions
          const Text(
            'Model Predictions:',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _buildModelPrediction('GPT-4', sentence.gpt4Prediction, 'gpt4'),
          _buildModelPrediction(
            'Gemini Flash 2.5',
            sentence.geminiPrediction,
            'gemini',
          ),
          _buildModelPrediction(
            'Perplexity',
            sentence.perplexityPrediction,
            'perplexity',
          ),

          const SizedBox(height: 16),

          // None option
          RadioListTile<String?>(
            title: const Text('None of the above are correct'),
            value: 'none',
            groupValue: _selectedModel,
            onChanged: (value) {
              setState(() {
                _selectedModel = value;
              });
            },
          ),

          const SizedBox(height: 16),

          // Alternative solution (shown when 'none' is selected)
          if (_selectedModel == 'none') ...[
            const Text(
              'Alternative Solution:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _alternativeController,
              decoration: const InputDecoration(
                hintText: 'Provide the correct sentiment analysis...',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
          ],

          // Notes (optional)
          const Text(
            'Notes (optional):',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              hintText: 'Any additional comments...',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 24),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting || _selectedModel == null
                  ? null
                  : _submitEvaluation,
              child: _isSubmitting
                  ? const CircularProgressIndicator()
                  : const Text('Submit Evaluation'),
            ),
          ),
        ],
      ),
    );
  }

  /*Widget _buildModelPrediction(
    String modelName,
    String prediction,
    String modelKey,
  ) {
    final isSelected = _selectedModel == modelKey;
    return Card(
      color: isSelected ? Colors.green[50] : null,
      child: RadioListTile<String>(
        title: Text(
          modelName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Text(prediction),
        value: modelKey,
        groupValue: _selectedModel,
        onChanged: (value) {
          setState(() {
            _selectedModel = value;
          });
        },
      ),
    );
  }*/
  Widget _buildModelPrediction(
    String modelName,
    String prediction,
    String modelKey,
  ) {
    final isSelected = _selectedModel == modelKey;
    return Card(
      color: isSelected ? Colors.green[50] : null,
      child: RadioListTile<String>(
        title: Text(
          modelName,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: GestureDetector(
          onLongPress: () {
            Clipboard.setData(ClipboardData(text: prediction));
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Prediction copied to clipboard'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          child: SelectableText(
            prediction,
            style: TextStyle(color: Colors.blue[700]),
          ),
        ),
        value: modelKey,
        groupValue: _selectedModel,
        onChanged: (value) {
          setState(() {
            _selectedModel = value;
          });
        },
      ),
    );
  }

  Future<void> _submitEvaluation() async {
    if (_selectedModel == null) return;

    if (_selectedModel == 'none' &&
        _alternativeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an alternative solution'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Check if we have a valid sentence
    if (_sentences.isEmpty || _currentIndex >= _sentences.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No sentence selected for evaluation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Use singleton instance instead of Provider
      final apiService = ApiService();
      final sentence = _sentences[_currentIndex];
      // Prepare the best model value
      final bestModel = _selectedModel == 'none' ? 'none' : _selectedModel!;

      // Prepare comments (combine notes and alternative solution)
      String? comments;
      final notes = _notesController.text.trim();
      final alternative = _alternativeController.text.trim();
      print('Alternative: $alternative');
      if (_selectedModel == 'none' && alternative.isNotEmpty) {
        comments = 'Alternative solution: $alternative';
        if (notes.isNotEmpty) {
          comments += '\nNotes: $notes';
        }
      } else if (notes.isNotEmpty) {
        comments = notes;
      }

      final authService = Provider.of<AuthService>(context, listen: false);

      // Check if user is authenticated
      if (!authService.isAuthenticated) {
        setState(() {
          _errorMessage = 'Please login first';
          _isLoading = false;
        });
        return;
      }
      // Sync the token between AuthService and ApiService
      if (authService.token != null) {
        await apiService.setToken(authService.token!);
      }

      // Submit evaluation with correct parameters
      await apiService.submitEvaluation(
        id: sentence.id,
        bestModel: bestModel,
        comments: comments,
        alternativeSolution: alternative,
        evaluatorId: authService.currentUser!.id,
      );

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evaluation submitted successfully!'),
          backgroundColor: Colors.green,
        ),
      );

      // Move to next sentence or finish
      _moveToNextSentence();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit evaluation: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  void _moveToNextSentence() {
    setState(() {
      _selectedModel = null;
      _alternativeController.clear();
      _notesController.clear();

      if (_currentIndex < _sentences.length - 1) {
        _currentIndex++;
      } else {
        // All sentences completed
        _showCompletionDialog();
      }
    });
  }

  void _skipSentence() {
    if (_currentIndex < _sentences.length - 1) {
      setState(() {
        _currentIndex++;
        _selectedModel = null;
        _alternativeController.clear();
        _notesController.clear();
      });
    } else {
      Navigator.of(context).pop();
    }
  }

  void _showCompletionDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Evaluation Complete!'),
        content: const Text(
          'You have completed all available sentences for evaluation.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Return to home
            },
            child: const Text('Return to Home'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _alternativeController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
