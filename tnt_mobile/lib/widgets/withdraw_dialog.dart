import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class WithdrawDialog extends StatefulWidget {
  final AppState appState;

  const WithdrawDialog({super.key, required this.appState});

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final _amountController = TextEditingController(text: '10.00');
  final _accountController = TextEditingController();
  final _nameController = TextEditingController();
  String _selectedMethod = 'eSewa';
  bool _isLoading = false;
  String? _errorMessage;

  final List<String> _methods = ['eSewa', 'Khalti', 'Bank Transfer'];

  Future<void> _handleWithdraw() async {
    final amt = double.tryParse(_amountController.text.trim());
    if (amt == null || amt <= 0) {
      setState(() => _errorMessage = 'Please enter a valid amount');
      return;
    }

    if (amt > widget.appState.wallet.availableBalance) {
      setState(() => _errorMessage = 'Withdrawal amount exceeds available balance (${widget.appState.formatPrice(widget.appState.wallet.availableBalance)})');
      return;
    }

    if (_accountController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Please enter your account number / wallet ID');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await widget.appState.withdrawFunds(
        amt,
        _selectedMethod,
        '${_accountController.text.trim()} (${_nameController.text.trim()})',
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Withdrawal request for ${widget.appState.formatPrice(amt)} submitted to $_selectedMethod!'),
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
        constraints: const BoxConstraints(maxWidth: 420),
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
                        Text('↗️', style: TextStyle(fontSize: 20)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Withdraw Funds',
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
              Text(
                'Available Balance: ${widget.appState.formatPrice(widget.appState.wallet.availableBalance)}',
                style: const TextStyle(color: AppTheme.cyan, fontSize: 13, fontWeight: FontWeight.bold),
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
              TextField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Withdraw Amount (USD)',
                  prefixIcon: Icon(Icons.attach_money, size: 20, color: AppTheme.fireOrange),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: _selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payout Method',
                  prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 20, color: AppTheme.textDim),
                ),
                dropdownColor: AppTheme.bgSecondary,
                items: _methods.map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                onChanged: (v) => setState(() => _selectedMethod = v!),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _accountController,
                decoration: InputDecoration(
                  labelText: _selectedMethod == 'Bank Transfer' ? 'Bank Account Number' : '$_selectedMethod ID / Mobile No.',
                  prefixIcon: const Icon(Icons.phone_android, size: 20, color: AppTheme.textDim),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Holder Full Name',
                  prefixIcon: Icon(Icons.person_outline, size: 20, color: AppTheme.textDim),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleWithdraw,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(46),
                  backgroundColor: AppTheme.fireOrange,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Submit Payout Request'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
