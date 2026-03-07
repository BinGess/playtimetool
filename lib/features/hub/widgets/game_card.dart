import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/haptics/haptic_service.dart';
import '../../../shared/styles/game_ui_style.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.accentColor,
    required this.route,
    required this.icon,
    this.onTap,
    this.locked = false,
    this.lockBadgeText,
  });

  final String title;
  final Color accentColor;
  final String route;
  final IconData icon;
  final VoidCallback? onTap;
  final bool locked;
  final String? lockBadgeText;

  @override
  State<GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<GameCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  void _onTapDown(_) => _pressController.forward();
  void _onTapUp(_) => _pressController.reverse();
  void _onTapCancel() => _pressController.reverse();

  void _navigate(BuildContext context) {
    HapticService.lightImpact();
    if (widget.onTap != null) {
      widget.onTap!.call();
      return;
    }
    context.push(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    final secondaryColor = GameUiSurface.shiftHue(widget.accentColor, by: 46);
    final tertiaryColor = GameUiSurface.shiftHue(widget.accentColor, by: 92);

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => _navigate(context),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.accentColor.withAlpha(80),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    GameUiSurface.darkTone(widget.accentColor, lightness: 0.22),
                    GameUiSurface.darkTone(secondaryColor, lightness: 0.16),
                    const Color(0xFF05070E),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.accentColor.withAlpha(36),
                    blurRadius: 24,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    left: -12,
                    top: -18,
                    child: _GlowOrb(
                      size: 92,
                      color: widget.accentColor.withAlpha(72),
                    ),
                  ),
                  Positioned(
                    right: -26,
                    bottom: -16,
                    child: _GlowOrb(
                      size: 118,
                      color: tertiaryColor.withAlpha(52),
                    ),
                  ),
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withAlpha(12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.black.withAlpha(80),
                            border: Border.all(
                              color: widget.accentColor.withAlpha(120),
                            ),
                          ),
                          child: Icon(
                            widget.icon,
                            size: 24,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.2,
                            shadows: [
                              Shadow(
                                color: widget.accentColor.withAlpha(60),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            const Spacer(),
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: widget.accentColor.withAlpha(28),
                                border: Border.all(
                                  color: widget.accentColor.withAlpha(90),
                                ),
                              ),
                              child: const Icon(
                                Icons.arrow_forward_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: widget.locked
                        ? Container(
                            key: const Key('game-card-cover'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(180),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withAlpha(80),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.lock_outline,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                if (widget.lockBadgeText != null) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.lockBadgeText!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          )
                        : const SizedBox(
                            key: Key('game-card-cover'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlowOrb extends StatelessWidget {
  const _GlowOrb({
    required this.size,
    required this.color,
  });

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 36,
              spreadRadius: 12,
            ),
          ],
        ),
      ),
    );
  }
}
