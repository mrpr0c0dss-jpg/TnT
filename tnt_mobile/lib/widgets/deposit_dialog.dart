import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'tnt_image.dart';

class DepositDialog extends StatefulWidget {
  final AppState appState;

  const DepositDialog({super.key, required this.appState});

  @override
  State<DepositDialog> createState() => _DepositDialogState();
}

class _DepositDialogState extends State<DepositDialog> {
  final _amountController = TextEditingController(text: '25.00');
  final _txnIdController = TextEditingController();
  String _selectedMethod = 'eSewa';
  bool _isLoading = false;
  String? _errorMessage;

  final List<double> _presetUsd = [10.0, 25.0, 50.0, 100.0];

  final List<Map<String, String>> _methods = [
    {'name': 'eSewa', 'icon': 'assets/payment/esewa.webp', 'desc': 'Instant eSewa QR & ID Transfer'},
    {'name': 'Khalti', 'icon': 'assets/payment/khalti.webp', 'desc': 'Khalti Digital Wallet'},
    {'name': 'IME Pay', 'icon': 'assets/payment/imepay.webp', 'desc': 'Mobile Banking & IME Pay'},
    {'name': 'Card / Visa', 'icon': 'assets/payment/bank.jpeg', 'desc': 'Visa / Mastercard / Stripe'},
  ];

  Future<void> _handleDeposit() async {
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _errorMessage = 'Please enter a valid deposit amount');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.depositFunds(
        amt,
        _selectedMethod,
        referenceId: _txnIdController.text.trim().isNotEmpty ? _txnIdController.text.trim() : null,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully deposited ${widget.appState.formatPrice(amt)} to Escrow Wallet!'),
            backgroundColor: AppTheme.emeraldGreen,
          ),
        );
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 650),
        child: SingleChildScrollView(
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
                        Text('💳', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Deposit Funds',
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
                'Top up your double-entry escrow wallet to join tournaments and purchase diamond bundles.',
                style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
              const Divider(height: 24),
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.errorRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.errorRed.withOpacity(0.4)),
                  ),
                  child: Text(_errorMessage!, style: const TextStyle(color: AppTheme.errorRed, fontSize: 12)),
                ),
              const Text('Select Preset Amount:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              Row(
                children: _presetUsd.map((val) {
                  final isSelected = _amountController.text == val.toStringAsFixed(2);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _amountController.text = val.toStringAsFixed(2);
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? AppTheme.cyan.withOpacity(0.15) : AppTheme.bgCard,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: isSelected ? AppTheme.cyan : AppTheme.borderCard),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            widget.appState.formatPrice(val),
                            style: TextStyle(
                              color: isSelected ? AppTheme.cyan : AppTheme.textMain,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount (USD equivalent)',
                  prefixIcon: const Icon(Icons.attach_money, size: 20, color: AppTheme.cyan),
                  suffixText: widget.appState.selectedCountry.currency,
                ),
              ),
              const SizedBox(height: 16),
              const Text('Payment Gateway:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              Column(
                children: _methods.map((m) {
                  final isSelected = _selectedMethod == m['name'];
                  return InkWell(
                    onTap: () => setState(() => _selectedMethod = m['name']!),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.cyan.withOpacity(0.12) : AppTheme.bgCard,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppTheme.cyan : AppTheme.borderCard),
                      ),
                      child: Row(
                        children: [
                          TntImage(imagePath: m['icon']!, width: 26, height: 26, borderRadius: BorderRadius.circular(4)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  m['name']!,
                                  style: TextStyle(
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                                    color: isSelected ? AppTheme.cyan : AppTheme.textMain,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(m['desc']!, style: const TextStyle(color: AppTheme.textDim, fontSize: 10)),
                              ],
                            ),
                          ),
                          Radio<String>(
                            value: m['name']!,
                            groupValue: _selectedMethod,
                            activeColor: AppTheme.cyan,
                            onChanged: (v) => setState(() => _selectedMethod = v!),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              if (_selectedMethod == 'eSewa')
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.bgCardHover,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.borderSubtle),
                  ),
                  child: const Row(
                    children: [
                      Text('🟢', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'eSewa Merchant ID: 9801234567 • Auto-verified via instant webhook',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 10),
              TextField(
                controller: _txnIdController,
                decoration: const InputDecoration(
                  labelText: 'Transaction Reference / Slip No. (Optional)',
                  prefixIcon: Icon(Icons.receipt_long, size: 20, color: AppTheme.textDim),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleDeposit,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppTheme.mintGreen,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Confirm Deposit & Credit Wallet', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
