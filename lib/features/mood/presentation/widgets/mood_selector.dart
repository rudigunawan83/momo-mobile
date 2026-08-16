/// Mood Selector Widget
import 'package:flutter/material.dart';
import '../../../../../core/theme/momo_design_system.dart';
import '../../domain/models/mood_models.dart';

class MoodSelectorWidget extends StatefulWidget {
  final String? selectedMood;
  final Function(String mood, double intensity) onMoodSelected;

  const MoodSelectorWidget({
    Key? key,
    this.selectedMood,
    required this.onMoodSelected,
  }) : super(key: key);

  @override
  State<MoodSelectorWidget> createState() => _MoodSelectorWidgetState();
}

class _MoodSelectorWidgetState extends State<MoodSelectorWidget> {
  String? _selected;
  double _intensity = 0.5;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedMood;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Emoji grid
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: MoodType.selectable.map((mood) {
            final isSelected = _selected == mood;
            final color = Color(MoodType.colorValue(mood));
            return GestureDetector(
              onTap: () {
                setState(() => _selected = mood);
                widget.onMoodSelected(mood, _intensity);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: isSelected ? 52 : 44,
                height: isSelected ? 52 : 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? color.withOpacity(0.15)
                      : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? color : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    MoodType.emoji(mood),
                    style: TextStyle(
                      fontSize: isSelected ? 28 : 24,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),

        if (_selected != null) ...[
          const SizedBox(height: MomoSpacing.md),
          // Mood label
          Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Text(
                MoodType.label(_selected!),
                key: ValueKey(_selected),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(MoodType.colorValue(_selected!)),
                ),
              ),
            ),
          ),

          const SizedBox(height: MomoSpacing.md),

          // Intensity slider
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: MomoSpacing.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Intensitas',
                      style: TextStyle(
                        fontSize: 12,
                        color: MomoColors.textGray,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      _intensityLabel(_intensity),
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(MoodType.colorValue(_selected!)),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: Color(MoodType.colorValue(_selected!)),
                  thumbColor: Color(MoodType.colorValue(_selected!)),
                  inactiveTrackColor:
                      Color(MoodType.colorValue(_selected!)).withOpacity(0.2),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: _intensity,
                  min: 0.1,
                  max: 1.0,
                  divisions: 9,
                  onChanged: (value) {
                    setState(() => _intensity = value);
                    widget.onMoodSelected(_selected!, value);
                  },
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  String _intensityLabel(double intensity) {
    if (intensity <= 0.3) return 'Sedikit';
    if (intensity <= 0.6) return 'Sedang';
    if (intensity <= 0.8) return 'Cukup';
    return 'Sangat';
  }
}

/// Mini mood display chip
class MoodChip extends StatelessWidget {
  final String mood;
  final bool showLabel;

  const MoodChip({Key? key, required this.mood, this.showLabel = true})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    final color = Color(MoodType.colorValue(mood));
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MomoSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(MomoRadius.pill),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(MoodType.emoji(mood), style: const TextStyle(fontSize: 14)),
          if (showLabel) ...[
            const SizedBox(width: 4),
            Text(
              MoodType.label(mood),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
