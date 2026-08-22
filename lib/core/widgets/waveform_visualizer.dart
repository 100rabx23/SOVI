import 'dart:math';
import 'package:flutter/material.dart';
import '../constants/colors.dart';

class WaveformVisualizer extends StatefulWidget {
  final double height;
  final bool isTransmitting;
  final bool isReceiving;
  final Color primaryColor;
  final Color secondaryColor;
  final int barCount;

  const WaveformVisualizer({
    super.key,
    this.height = 96.0,
    this.isTransmitting = false,
    this.isReceiving = false,
    this.primaryColor = SoviColors.primary,
    this.secondaryColor = SoviColors.secondaryContainer,
    this.barCount = 36,
  });

  @override
  State<WaveformVisualizer> createState() => _WaveformVisualizerState();
}

class _WaveformVisualizerState extends State<WaveformVisualizer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isTransmitting || widget.isReceiving;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final progress = _controller.value * 2 * pi;

        return SizedBox(
          height: widget.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount, (index) {
              double barHeightFactor;
              if (isActive) {
                final wave1 = sin(progress + index * 0.25);
                final wave2 = cos(progress * 1.5 + index * 0.4);
                final noise = _random.nextDouble() * 0.3;
                barHeightFactor = ((wave1 + wave2) * 0.25 + 0.5 + noise).clamp(0.1, 1.0);
              } else {
                barHeightFactor = (sin(progress + index * 0.1) * 0.1 + 0.15).clamp(0.08, 0.3);
              }

              final isGreenHighlight = isActive && (index % 7 == 0 || _random.nextDouble() > 0.85);
              final barColor = isGreenHighlight ? widget.secondaryColor : widget.primaryColor;

              return Container(
                width: 3.0,
                height: widget.height * barHeightFactor,
                margin: const EdgeInsets.symmetric(horizontal: 2.0),
                decoration: BoxDecoration(
                  color: barColor.withOpacity(isActive ? 0.85 : 0.4),
                  borderRadius: BorderRadius.circular(2.0),
                  boxShadow: isActive && isGreenHighlight
                      ? [
                          BoxShadow(
                            color: widget.secondaryColor.withOpacity(0.6),
                            blurRadius: 6,
                            spreadRadius: 1,
                          )
                        ]
                      : null,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
