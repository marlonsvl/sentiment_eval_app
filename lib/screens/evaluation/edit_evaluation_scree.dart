// lib/screens/edit_evaluation_screen.dart

import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../models/evaluation.dart';

class EditEvaluationScreen extends StatefulWidget {
  final Evaluation evaluation;

  const EditEvaluationScreen({Key? key, required this.evaluation})
    : super(key: key);

  @override
  State<EditEvaluationScreen> createState() => _EditEvaluationScreenState();
}

class _EditEvaluationScreenState extends State<EditEvaluationScreen> {
  final ApiService _evaluationService = ApiService();
  final _alternativeSolutionController = TextEditingController();
  final _notesController = TextEditingController();

  String _selectedModel = '';
  bool _isLoading = false;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    _selectedModel = widget.evaluation.bestModel;
    _alternativeSolutionController.text =
        widget.evaluation.alternativeSolution ?? '';
    _notesController.text = widget.evaluation.notes ?? '';

    // Add listeners to detect changes
    _alternativeSolutionController.addListener(_onFieldChanged);
    _notesController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    final hasChanges =
        _selectedModel != widget.evaluation.bestModel ||
        _alternativeSolutionController.text !=
            (widget.evaluation.alternativeSolution ?? '') ||
        _notesController.text != (widget.evaluation.notes ?? '');

    if (hasChanges != _hasChanges) {
      setState(() {
        _hasChanges = hasChanges;
      });
    }
  }

  @override
  void dispose() {
    _alternativeSolutionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  // Replace your current _saveEvaluation method with this:

  Future<void> _saveEvaluation() async {
    if (!_hasChanges) {
      Navigator.pop(context);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new evaluation with all fields explicitly set
      final updatedEvaluation = Evaluation(
        id: widget.evaluation.id,
        sentenceId: widget.evaluation.sentenceId,
        evaluatorId: widget.evaluation.evaluatorId,
        evaluatorName: widget.evaluation.evaluatorName,
        sentenceText: widget.evaluation.sentenceText,
        bestModel: _selectedModel,
        // Alternative solution is only kept if model is "none", otherwise set to null
        alternativeSolution: _selectedModel == 'none'
            ? (_alternativeSolutionController.text.trim().isEmpty
                  ? null
                  : _alternativeSolutionController.text.trim())
            : null,
        // Notes are always updated based on the controller
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        evaluationTimeSeconds: widget.evaluation.evaluationTimeSeconds,
        createdAt: widget.evaluation.createdAt,
        updatedAt: widget.evaluation.updatedAt,
        sentence: widget.evaluation.sentence,
      );

      await _evaluationService.updateEvaluation(
        widget.evaluation.id,
        updatedEvaluation,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Evaluation updated successfully')),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating evaluation: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard Changes?'),
        content: const Text(
          'You have unsaved changes. Do you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Edit Evaluation'),
          backgroundColor: Colors.blue.shade700,
          foregroundColor: Colors.white,
          actions: [
            if (_hasChanges)
              TextButton(
                onPressed: _isLoading ? null : _saveEvaluation,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'SAVE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSentenceCard(),
              const SizedBox(height: 24),
              _buildModelPredictions(),
              const SizedBox(height: 24),
              _buildModelSelection(),
              const SizedBox(height: 24),
              _buildAlternativeSolution(),
              const SizedBox(height: 24),
              _buildNotesField(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSentenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.chat_bubble_outline, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  'Sentence ID: ${widget.evaluation.sentence?.sentenceId}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.evaluation.sentence!.text,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelPredictions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.psychology, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Model Predictions',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildPredictionItem(
              'GPT-4',
              widget.evaluation.sentence?.gpt4Prediction,
              Colors.green,
            ),
            _buildPredictionItem(
              'Gemini',
              widget.evaluation.sentence?.geminiPrediction,
              Colors.blue,
            ),
            _buildPredictionItem(
              'Perplexity',
              widget.evaluation.sentence?.perplexityPrediction,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPredictionItem(String model, String? prediction, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: color, width: 3)),
        color: color.withOpacity(0.1),
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            model,
            style: TextStyle(fontWeight: FontWeight.bold, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            prediction ?? 'No prediction available',
            style: TextStyle(
              color: prediction != null ? Colors.black87 : Colors.grey,
              fontStyle: prediction != null
                  ? FontStyle.normal
                  : FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModelSelection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.check_circle_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Select Best Model',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildModelRadioTile('gpt4', 'GPT-4', Colors.green),
            _buildModelRadioTile('gemini', 'Gemini Flash 2.5', Colors.blue),
            _buildModelRadioTile('perplexity', 'Perplexity', Colors.purple),
            _buildModelRadioTile(
              'none',
              'None (Alternative Solution)',
              Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModelRadioTile(String value, String title, Color color) {
    return RadioListTile<String>(
      value: value,
      groupValue: _selectedModel,
      onChanged: (String? newValue) {
        setState(() {
          _selectedModel = newValue ?? '';
        });
        _onFieldChanged();
      },
      title: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(title),
        ],
      ),
      contentPadding: EdgeInsets.zero,
    );
  }

  // Enhanced _buildAlternativeSolution method for better user experience

  Widget _buildAlternativeSolution() {
    final bool willBeClearedOnSave =
        _selectedModel != 'none' &&
        _alternativeSolutionController.text.trim().isNotEmpty;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  'Alternative Solution',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                if (_selectedModel == 'none') ...[
                  const SizedBox(width: 8),
                  const Text(
                    '*Required',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _selectedModel == 'none'
                  ? 'Provide your own solution if none of the models are correct'
                  : 'This field will be cleared when you select a model other than "None"',
              style: TextStyle(
                color: _selectedModel == 'none'
                    ? Colors.grey
                    : Colors.orange.shade700,
                fontSize: 12,
              ),
            ),
            if (willBeClearedOnSave) ...[
              const SizedBox(height: 4),
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
                      Icons.warning_amber,
                      size: 16,
                      color: Colors.orange.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'This alternative solution will be removed when you save',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontSize: 11,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _alternativeSolutionController,
              maxLines: 3,
              enabled: true, // Always keep enabled so user can see the content
              decoration: InputDecoration(
                hintText: 'Enter your alternative solution here...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
                errorText:
                    _selectedModel == 'none' &&
                        _alternativeSolutionController.text.trim().isEmpty
                    ? 'Alternative solution is required when selecting "None"'
                    : null,
                // Visual indication that field will be cleared
                suffixIcon: willBeClearedOnSave
                    ? Icon(Icons.clear, color: Colors.orange.shade700)
                    : null,
              ),
              style: TextStyle(
                color: willBeClearedOnSave
                    ? Colors.grey.shade600
                    : Colors.black87,
                decoration: willBeClearedOnSave
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesField() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.note, color: Colors.blue),
                SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Optional notes about your evaluation decision',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Enter any additional notes or reasoning...',
                border: const OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.blue.shade300),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    final bool isValid =
        _selectedModel.isNotEmpty &&
        (_selectedModel != 'none' ||
            _alternativeSolutionController.text.trim().isNotEmpty);

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: (isValid && _hasChanges && !_isLoading)
                ? _saveEvaluation
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade700,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(_hasChanges ? 'Save Changes' : 'No Changes'),
          ),
        ),
      ],
    );
  }
}
