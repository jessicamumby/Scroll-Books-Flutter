import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';

class DailyGoalCard extends StatefulWidget {
  final int goal;
  final int passagesReadToday;
  final ValueChanged<int> onGoalChanged;

  const DailyGoalCard({
    super.key,
    required this.goal,
    required this.passagesReadToday,
    required this.onGoalChanged,
  });

  @override
  State<DailyGoalCard> createState() => _DailyGoalCardState();
}

class _DailyGoalCardState extends State<DailyGoalCard> {
  bool _isEditing = false;

  static const _goalOptions = [3, 5, 10, 15, 20, 30];

  double get _progress =>
      widget.goal > 0
          ? (widget.passagesReadToday / widget.goal).clamp(0.0, 1.0)
          : 0.0;

  int get _percent => (_progress * 100).round();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cream,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppTheme.tomato.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Today's Goal",
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.passagesReadToday} of ${widget.goal} passages',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 12,
                        color: AppTheme.inkLight,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => setState(() => _isEditing = !_isEditing),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.parchment,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.inkLight.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('✏️', style: TextStyle(fontSize: 12)),
                      const SizedBox(width: 4),
                      Text(
                        'Edit Goal',
                        style: GoogleFonts.playfairDisplay(
                          fontSize: 12,
                          color: AppTheme.inkMid,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress bar
          Container(
            height: 10,
            decoration: BoxDecoration(
              color: AppTheme.parchment,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: _progress,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(5),
                    gradient: const LinearGradient(
                      colors: [AppTheme.tomato, AppTheme.amber],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.amber.withValues(alpha: 0.35),
                        blurRadius: 6,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),

          // Percentage
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '$_percent% complete',
              style: GoogleFonts.playfairDisplay(
                fontSize: 11,
                color: AppTheme.inkLight,
              ),
            ),
          ),

          // Edit panel
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child: _isEditing
                ? _buildGoalPicker()
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalPicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PASSAGES PER DAY',
            style: AppTheme.monoLabel(fontSize: 10, color: AppTheme.inkLight),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: _goalOptions.map((value) {
              final isSelected = value == widget.goal;
              return GestureDetector(
                onTap: () {
                  widget.onGoalChanged(value);
                  setState(() => _isEditing = false);
                },
                child: Container(
                  width: 48,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected ? AppTheme.tomato : AppTheme.warmWhite,
                    borderRadius: BorderRadius.circular(10),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: AppTheme.inkLight.withValues(alpha: 0.20),
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.tomato.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      '$value',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : AppTheme.ink,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
