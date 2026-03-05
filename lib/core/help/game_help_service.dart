import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../l10n/app_localizations.dart';

class GameHelpService {
  static const _seenPrefix = 'game_help_seen_';

  static Future<bool> hasSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('$_seenPrefix$gameId') ?? false;
  }

  static Future<void> markSeen(String gameId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_seenPrefix$gameId', true);
  }

  static Future<bool> ensureFirstTimeShown({
    required BuildContext context,
    required String gameId,
    required String gameTitle,
    required String helpBody,
  }) async {
    final seen = await hasSeen(gameId);
    if (seen) return false;

    await showGameHelpDialog(
      context,
      gameTitle: gameTitle,
      helpBody: helpBody,
    );
    await markSeen(gameId);
    return true;
  }

  static Future<void> showGameHelpDialog(
    BuildContext context, {
    required String gameTitle,
    required String helpBody,
  }) async {
    final l10n = AppLocalizations.of(context);
    if (!context.mounted) return;

    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF101010),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0x33FFFFFF)),
        ),
        title: Text(
          '${l10n.t('gameHelpTitle')} · $gameTitle',
          style: const TextStyle(color: Colors.white, fontSize: 18),
        ),
        content: Text(
          helpBody,
          style: const TextStyle(
            color: Color(0xFFCCCCCC),
            fontSize: 14,
            height: 1.55,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              l10n.t('gameHelpGotIt'),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class GameHelpButton extends StatelessWidget {
  const GameHelpButton({
    super.key,
    required this.onTap,
    this.iconColor = Colors.white,
    this.borderColor = const Color(0x55FFFFFF),
  });

  final VoidCallback onTap;
  final Color iconColor;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor),
          color: const Color(0x22000000),
        ),
        child: Icon(Icons.question_mark, size: 18, color: iconColor),
      ),
    );
  }
}
