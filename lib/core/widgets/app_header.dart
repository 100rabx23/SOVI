import 'package:flutter/material.dart';
import '../constants/colors.dart';
import '../constants/typography.dart';

class SoviHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final Widget? action;
  final bool isEngineReady;

  const SoviHeader({
    super.key,
    this.title = 'SOVI',
    this.showBackButton = false,
    this.onBackPressed,
    this.action,
    this.isEngineReady = true,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64.0 + MediaQuery.of(context).padding.top,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top,
        left: 16.0,
        right: 16.0,
      ),
      decoration: BoxDecoration(
        color: const Color(0xB31C2026), // Glass surface
        border: Border(
          bottom: BorderSide(
            color: SoviColors.outline.withOpacity(0.1),
            width: 1.0,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (showBackButton)
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: SoviColors.onSurfaceVariant),
                  onPressed: onBackPressed ?? () => Navigator.of(context).maybePop(),
                )
              else ...[
                // SOVI Brand Logo Icon
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: SoviColors.primary.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: SoviColors.primary.withOpacity(0.3),
                    ),
                  ),
                  child: const Icon(
                    Icons.sensors,
                    color: SoviColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Text(
                title.toUpperCase(),
                style: SoviTypography.headlineMd(color: SoviColors.onSurface).copyWith(
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          action ??
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: SoviColors.surfaceContainerHighest.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: SoviColors.outline.withOpacity(0.1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: isEngineReady ? SoviColors.secondaryContainer : SoviColors.error,
                        shape: BoxShape.circle,
                        boxShadow: isEngineReady
                            ? [
                                const BoxShadow(
                                  color: SoviColors.secondaryContainer,
                                  blurRadius: 6,
                                  spreadRadius: 1,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      isEngineReady ? 'ENGINE: READY' : 'ENGINE: OFF',
                      style: SoviTypography.labelMonoSm(color: SoviColors.secondaryContainer),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}
