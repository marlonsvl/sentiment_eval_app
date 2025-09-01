import 'package:flutter/material.dart';

class ModelPredictionCard extends StatelessWidget {
  final String modelName;
  final String prediction;
  final String modelKey;
  final String? selectedModel;
  final ValueChanged<String?> onChanged;
  final Color? accentColor;

  const ModelPredictionCard({
    super.key,
    required this.modelName,
    required this.prediction,
    required this.modelKey,
    required this.selectedModel,
    required this.onChanged,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedModel == modelKey;
    final color = accentColor ?? Colors.blue;

    return Card(
      elevation: isSelected ? 4 : 1,
      color: isSelected ? color.withOpacity(0.1) : null,
      child: InkWell(
        onTap: () => onChanged(modelKey),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: modelKey,
                groupValue: selectedModel,
                onChanged: onChanged,
                activeColor: color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      modelName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        color: isSelected ? color : null,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(prediction, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              if (isSelected) Icon(Icons.check_circle, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
