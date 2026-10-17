import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';
import 'tnt_image.dart';

class CheckoutDialog extends StatefulWidget {
  final AppState appState;
  final GameModel game;
  final TopUpPackageModel package;
  final Map<String, String> initialPlayerDetails;

  const CheckoutDialog({
    super.key,
    required this.appState,
    required this.game,
    required this.package,
    this.initialPlayerDetails = const {},
  });

  @override
  State<CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<CheckoutDialog> {
  final Map<String, TextEditingController> _controllers = {};
  String _selectedPaymentMethod = 'WALLET';
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    for (final field in widget.game.requiredFields) {
      _controllers[field.key] = TextEditingController(
        text: widget.initialPlayerDetails[field.key] ?? '',
      );
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool _validateFields() {
    for (final field in widget.game.requiredFields) {
      final val = _controllers[field.key]?.text.trim() ?? '';
      if (val.isEmpty) {
        setState(() => _errorMessage = 'Please enter ${field.label}');
        return false;
      }
      try {
        final reg = RegExp(field.regex);
        if (!reg.hasMatch(val)) {
          setState(() => _errorMessage = 'Invalid format for ${field.label}: ${field.hint}');
          return false;
        }
      } catch (_) {}
    }
    return true;
  }

  Future<void> _handleCheckout() async {
    if (!_validateFields()) return;

    if (_selectedPaymentMethod == 'WALLET' && widget.appState.wallet.availableBalance < widget.package.price) {
      setState(() => _errorMessage = 'Insufficient Escrow Wallet balance. Please deposit funds or choose eSewa/Khalti.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final playerDetails = <String, String>{};
    for (final entry in _controllers.entries) {
      playerDetails[entry.key] = entry.value.text.trim();
    }

    try {
      final res = await widget.appState.purchaseTopUp(
        gameId: widget.game.id,
        packageId: widget.package.id,
        playerDetails: playerDetails,
        paymentMethod: _selectedPaymentMethod,
        price: widget.package.price,
      );

      if (mounted) {
        Navigator.pop(context);
        _showSuccessDialog(res);
      }
    } catch (e) {
      setState(() => _errorMessage = e.toString().replaceAll('Exception:', '').trim());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> result) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppTheme.bgSecondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: AppTheme.mintGreen,
                child: Icon(Icons.check, color: Colors.black, size: 36),
              ),
              const SizedBox(height: 16),
              const Text(
                'Top-Up Dispatched!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                '${widget.package.name} (${widget.package.itemQuantity})',
                style: const TextStyle(fontSize: 14, color: AppTheme.fireOrange, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Game:', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        Text(widget.game.name, style: const TextStyle(color: AppTheme.textMain, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Receipt No:', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        Text(result['receipt'] ?? result['order_id'] ?? 'REC-SUCCESS', style: const TextStyle(color: AppTheme.cyan, fontSize: 12, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Status:', style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
                        const Text('INSTANT DELIVERY • SUCCESS', style: TextStyle(color: AppTheme.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                  backgroundColor: AppTheme.fireOrange,
                ),
                child: const Text('Done & Back to Store'),
              ),
            ],
          ),
        ),
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
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 680),
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
                        Text('🛒', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Confirm Top-Up Order',
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
              const Divider(height: 20),
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.bgCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderCard),
                ),
                child: Row(
                  children: [
                    TntImage(imagePath: widget.game.banner, width: 50, height: 50, borderRadius: BorderRadius.circular(8)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.game.name, style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 14)),
                          const SizedBox(height: 2),
                          Text(widget.package.name, style: const TextStyle(color: AppTheme.fireOrange, fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    Text(
                      widget.appState.formatPrice(widget.package.price, includeUsd: true),
                      style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cyan, fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
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
              // Dynamic Player Verification Fields
              const Text('Player Verification Details:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              ...widget.game.requiredFields.map((field) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: TextField(
                    controller: _controllers[field.key],
                    decoration: InputDecoration(
                      labelText: field.label,
                      hintText: field.hint,
                      prefixIcon: const Icon(Icons.tag, size: 20, color: AppTheme.cyan),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              const Text('Payment Method:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              const SizedBox(height: 8),
              // Wallet balance option
              InkWell(
                onTap: () => setState(() => _selectedPaymentMethod = 'WALLET'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'WALLET' ? AppTheme.cyan.withOpacity(0.12) : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedPaymentMethod == 'WALLET' ? AppTheme.cyan : AppTheme.borderCard),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.account_balance_wallet, color: AppTheme.cyan, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Escrow Wallet (1-Click Instant)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13)),
                            Text(
                              'Available: ${widget.appState.formatPrice(widget.appState.wallet.availableBalance)}',
                              style: const TextStyle(color: AppTheme.cyan, fontSize: 11),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'WALLET',
                        groupValue: _selectedPaymentMethod,
                        activeColor: AppTheme.cyan,
                        onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
              // eSewa option
              InkWell(
                onTap: () => setState(() => _selectedPaymentMethod = 'eSewa'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'eSewa' ? AppTheme.fireOrange.withOpacity(0.12) : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedPaymentMethod == 'eSewa' ? AppTheme.fireOrange : AppTheme.borderCard),
                  ),
                  child: Row(
                    children: [
                      TntImage(imagePath: 'assets/payment/esewa.webp', width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('eSewa Mobile Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13)),
                            Text('Instant direct eSewa checkout', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'eSewa',
                        groupValue: _selectedPaymentMethod,
                        activeColor: AppTheme.fireOrange,
                        onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
              // Khalti option
              InkWell(
                onTap: () => setState(() => _selectedPaymentMethod = 'Khalti'),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _selectedPaymentMethod == 'Khalti' ? AppTheme.purple.withOpacity(0.12) : AppTheme.bgCard,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _selectedPaymentMethod == 'Khalti' ? AppTheme.purple : AppTheme.borderCard),
                  ),
                  child: Row(
                    children: [
                      TntImage(imagePath: 'assets/payment/khalti.webp', width: 24, height: 24, borderRadius: BorderRadius.circular(4)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Khalti Digital Wallet', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13)),
                            Text('Direct Khalti wallet payment', style: TextStyle(color: AppTheme.textDim, fontSize: 11)),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: 'Khalti',
                        groupValue: _selectedPaymentMethod,
                        activeColor: AppTheme.purple,
                        onChanged: (v) => setState(() => _selectedPaymentMethod = v!),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleCheckout,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppTheme.fireOrange,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Pay ${widget.appState.formatPrice(widget.package.price)} & Deliver Now',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
