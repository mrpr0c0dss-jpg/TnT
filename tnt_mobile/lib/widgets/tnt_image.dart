import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TntImage extends StatelessWidget {
  final String imagePath;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final String fallbackIcon;

  const TntImage({
    super.key,
    required this.imagePath,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = '🎮',
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    // Normalize path
    String cleanPath = imagePath.trim();
    if (cleanPath.startsWith('/assets/')) {
      cleanPath = cleanPath.substring(1); // turn /assets/... into assets/...
    }

    if (cleanPath.startsWith('http://') || cleanPath.startsWith('https://')) {
      content = Image.network(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: AppTheme.bgSecondary,
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.cyan),
              ),
            ),
          );
        },
      );
    } else if (cleanPath.startsWith('assets/')) {
      content = Image.asset(
        cleanPath,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _buildFallback(),
      );
    } else {
      content = _buildFallback();
    }

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: content,
      );
    }
    return content;
  }

  Widget _buildFallback() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppTheme.bgSecondary,
        borderRadius: borderRadius,
        border: Border.all(color: AppTheme.borderSubtle),
      ),
      child: Center(
        child: Text(
          fallbackIcon,
          style: TextStyle(fontSize: (height != null && height! < 40) ? 16 : 24),
        ),
      ),
    );
  }
}
