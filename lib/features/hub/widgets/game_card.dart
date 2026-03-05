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
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.accentColor.withAlpha(50),
                  width: 1,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.accentColor.withAlpha(18),
                    Colors.black.withAlpha(200),
                  ],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon with glow
                    Icon(
                      widget.icon,
                      color: widget.accentColor,
                      size: 28,
                      shadows: [
                        Shadow(
                          color: widget.accentColor.withAlpha(150),
                          blurRadius: 16,
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Subtitle
                    Text(
                      widget.subtitle,
                      style: TextStyle(
                        color: widget.accentColor.withAlpha(160),
                        fontSize: 9,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Title
                    Text(
                      widget.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                        shadows: [
                          Shadow(
                            color: widget.accentColor.withAlpha(60),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Description
                    Text(
                      widget.description,
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
