import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/haptics/haptic_service.dart';

class GameCard extends StatefulWidget {
  const GameCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.accentColor,
    required this.route,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String description;
  final Color accentColor;
  final String route;
  final IconData icon;

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
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.96).animate(
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
    context.push(widget.route);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: () => _navigate(context),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: widget.accentColor.withAlpha(60),
                    width: 1.5,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      widget.accentColor.withAlpha(20),
                      Colors.black.withAlpha(180),
                    ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      // Icon with glow
                      Icon(
                        widget.icon,
                        color: widget.accentColor,
                        size: 40,
                        shadows: [
                          Shadow(
                            color: widget.accentColor.withAlpha(180),
                            blurRadius: 20,
                          ),
                        ],
                      ),
                      const Spacer(),
                      // Subtitle
                      Text(
                        widget.subtitle,
                        style: TextStyle(
                          color: widget.accentColor.withAlpha(180),
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Title
                      Text(
                        widget.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              color: widget.accentColor.withAlpha(80),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Description
                      Text(
                        widget.description,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
