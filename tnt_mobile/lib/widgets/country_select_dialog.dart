import 'package:flutter/material.dart';
import '../models/country_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class CountrySelectDialog extends StatelessWidget {
  final AppState appState;

  const CountrySelectDialog({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTheme.bgSecondary,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppTheme.borderCard),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 520),
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
                      Text('🌍', style: TextStyle(fontSize: 20)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Region & Currency',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textMain,
                          ),
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
            const Text(
              'Prices and payment gateways will automatically adapt to your chosen local currency.',
              style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
            const Divider(height: 24),
            Expanded(
              child: ListView.separated(
                itemCount: CountryModel.supportedCountries.length,
                separatorBuilder: (context, index) => const Divider(height: 1, color: AppTheme.borderSubtle),
                itemBuilder: (context, index) {
                  final c = CountryModel.supportedCountries[index];
                  final isSelected = c.code == appState.selectedCountry.code;

                  return InkWell(
                    onTap: () {
                      appState.switchCountry(c);
                      Navigator.pop(context);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.fireOrange.withOpacity(0.12) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: isSelected ? Border.all(color: AppTheme.fireOrange.withOpacity(0.4)) : null,
                      ),
                      child: Row(
                        children: [
                          Text(c.flag, style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  c.name,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppTheme.fireOrange : AppTheme.textMain,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  '${c.currency} (${c.symbol}) • Rate: \$1 = ${c.symbol}${c.rate}',
                                  style: const TextStyle(color: AppTheme.textDim, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            const Icon(Icons.check_circle, color: AppTheme.fireOrange, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
