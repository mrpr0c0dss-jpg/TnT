import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

class RoomCredentialsDialog extends StatelessWidget {
  final String tournamentTitle;
  final String roomId;
  final String roomPassword;
  final String mode;

  const RoomCredentialsDialog({
    super.key,
    required this.tournamentTitle,
    required this.roomId,
    required this.roomPassword,
    required this.mode,
  });

  void _copyToClipboard(BuildContext context, String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard: $text'),
        backgroundColor: AppTheme.emeraldGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderCard),
      ),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    children: [
                      Text('🔓', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Lobby Room Secret',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textDim, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              tournamentTitle,
              style: const TextStyle(color: AppTheme.fireOrange, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            const Divider(height: 20),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.emeraldGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.emeraldGreen.withOpacity(0.3)),
              ),
              child: const Row(
                children: [
                  Text('🟢', style: TextStyle(fontSize: 18)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Room credentials unlocked! Enter the custom lobby before match countdown closes.',
                      style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Room ID Box
            const Text('Room ID / Code:', style: TextStyle(fontSize: 12, color: AppTheme.textDim, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderCard),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    roomId,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.cyan, letterSpacing: 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: AppTheme.cyan),
                    onPressed: () => _copyToClipboard(context, roomId, 'Room ID'),
                    tooltip: 'Copy Room ID',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            // Room Password Box
            const Text('Room Password:', style: TextStyle(fontSize: 12, color: AppTheme.textDim, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.bgCard,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTheme.borderCard),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SelectableText(
                    roomPassword,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.fireOrange, letterSpacing: 1),
                  ),
                  IconButton(
                    icon: const Icon(Icons.copy, size: 18, color: AppTheme.fireOrange),
                    onPressed: () => _copyToClipboard(context, roomPassword, 'Room Password'),
                    tooltip: 'Copy Room Password',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '⚠️ Do not share room credentials with non-registered players. Sharing credentials causes immediate team disqualification.',
              style: TextStyle(color: AppTheme.textDim, fontSize: 11),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
                backgroundColor: AppTheme.bgCardHover,
                foregroundColor: AppTheme.textMain,
              ),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
    );
  }
}
