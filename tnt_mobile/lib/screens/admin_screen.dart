import 'package:flutter/material.dart';
import '../services/app_state.dart';
import '../theme/app_theme.dart';

class AdminScreen extends StatefulWidget {
  final AppState appState;

  const AdminScreen({super.key, required this.appState});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mock Admin Queues
  final List<Map<String, dynamic>> _orders = [
    {
      'id': 'ord_9901',
      'game': 'Free Fire MAX',
      'package': '520+52 Diamonds',
      'player_id': '192837465',
      'amount': 4.89,
      'status': 'DELIVERED',
      'payment': 'eSewa',
      'time': '10 mins ago',
    },
    {
      'id': 'ord_9902',
      'game': 'PUBG Mobile',
      'package': '660 UC',
      'player_id': '518392019',
      'amount': 9.49,
      'status': 'PENDING_DELIVERY',
      'payment': 'Wallet',
      'time': '25 mins ago',
    },
    {
      'id': 'ord_9903',
      'game': 'Mobile Legends',
      'package': 'Weekly Pass',
      'player_id': '8493021 (2041)',
      'amount': 1.99,
      'status': 'DELIVERED',
      'payment': 'Khalti',
      'time': '1 hour ago',
    },
  ];

  final List<Map<String, dynamic>> _pendingPayments = [
    {
      'id': 'pay_8801',
      'user': 'Phoenix_Ace',
      'amount': 25.00,
      'method': 'eSewa',
      'slip_no': 'TXN-ESEWA-8849201',
      'time': '5 mins ago',
    },
    {
      'id': 'pay_8802',
      'user': 'ViperStrike',
      'amount': 50.00,
      'method': 'Khalti',
      'slip_no': 'KHALTI-773910',
      'time': '18 mins ago',
    },
  ];

  final List<Map<String, dynamic>> _prizes = [
    {
      'id': 'prz_701',
      'tournament': 'Free Fire: Apex Champions Cup S4',
      'winner': 'Phoenix_Ace',
      'amount': 200.00,
      'mgr_approved': true,
      'finance_approved': false,
      'status': 'AWAITING_FINANCE_APPROVAL',
    },
    {
      'id': 'prz_702',
      'tournament': 'MLBB: Mystic Invitational',
      'winner': 'ViperStrike',
      'amount': 117.00,
      'mgr_approved': false,
      'finance_approved': false,
      'status': 'AWAITING_MGR_APPROVAL',
    },
  ];

  final List<Map<String, dynamic>> _aiKeys = [
    {'tool': 'ChatGPT Plus', 'code': 'OAI-PLUS-9921-X90', 'status': 'AVAILABLE'},
    {'tool': 'Claude 3.5 Pro', 'code': 'CLAUDE-PRO-8812-V12', 'status': 'AVAILABLE'},
    {'tool': 'Cursor Pro', 'code': 'CURSOR-DEV-7721-M88', 'status': 'ASSIGNED (Alex)'},
    {'tool': 'Midjourney Pro', 'code': 'MIDJ-PRO-6610-K44', 'status': 'AVAILABLE'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.appState.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.bgPrimary,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(88),
        child: Container(
          color: AppTheme.bgSecondary,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Row(
                    children: [
                      const Text('🛡️', style: TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      const Text(
                        'Operations & Risk Portal',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppTheme.fireOrange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.fireOrange.withOpacity(0.4)),
                        ),
                        child: Text(
                          user.role.toUpperCase(),
                          style: const TextStyle(color: AppTheme.fireOrange, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppTheme.fireOrange,
                  labelColor: AppTheme.fireOrange,
                  unselectedLabelColor: AppTheme.textDim,
                  labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  tabs: const [
                    Tab(text: '📊 KPIs'),
                    Tab(text: '💎 Orders'),
                    Tab(text: '💳 Slips'),
                    Tab(text: '🏆 Dual Payouts'),
                    Tab(text: '🤖 AI Keys'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildKpiView(),
          _buildOrdersView(),
          _buildPendingPaymentsView(),
          _buildDualPrizePayoutsView(),
          _buildAiKeyVaultView(),
        ],
      ),
    );
  }

  Widget _buildKpiView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Platform Financial & Risk Metrics', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: [
              _buildKpiCard('Gross Volume', widget.appState.formatPrice(12450.0), 'Total GMV', AppTheme.cyan),
              _buildKpiCard('Pending Orders', '${_orders.where((o) => o['status'] != 'DELIVERED').length}', 'Awaiting Dispatch', AppTheme.amberGold),
              _buildKpiCard('Pending Slips', '${_pendingPayments.length}', 'Manual Verification', AppTheme.fireOrange),
              _buildKpiCard('Dual Approvals', '${_prizes.length}', 'High-value signoff', AppTheme.purple),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.bgCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.borderCard),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('⚡', style: TextStyle(fontSize: 18)),
                    SizedBox(width: 8),
                    Text('HMAC Webhook Simulator', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Trigger simulated publisher payment webhook with SHA256 signature verification.',
                  style: TextStyle(fontSize: 11, color: AppTheme.textMuted),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Simulated payment webhook HMAC-SHA256 verified & processed!'),
                        backgroundColor: AppTheme.emeraldGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.bolt, size: 16),
                  label: const Text('Simulate Publisher Webhook'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGreen, foregroundColor: Colors.black),
                ),
              ],
            ),
          ),
          const SizedBox(height: 90),
        ],
      ),
    );
  }

  Widget _buildKpiCard(String title, String val, String sub, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderCard),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
          Text(val, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(sub, style: const TextStyle(fontSize: 9, color: AppTheme.textMuted)),
        ],
      ),
    );
  }

  Widget _buildOrdersView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 90),
      itemCount: _orders.length,
      itemBuilder: (context, index) {
        final o = _orders[index];
        final isDelivered = o['status'] == 'DELIVERED';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(o['id'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.cyan, fontSize: 13)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isDelivered ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.amberGold.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      o['status'],
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: isDelivered ? AppTheme.emeraldGreen : AppTheme.amberGold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text('${o['game']} • ${o['package']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
              Text('UID: ${o['player_id']} • Method: ${o['payment']} • Amount: ${widget.appState.formatPrice(o['amount'])}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
              if (!isDelivered) ...[
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() => o['status'] = 'DELIVERED');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Order ${o['id']} delivered!'), backgroundColor: AppTheme.emeraldGreen),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.fireOrange, padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),
                      child: const Text('⚡ Retry Dispatch', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPendingPaymentsView() {
    if (_pendingPayments.isEmpty) {
      return const Center(child: Text('No pending payment slips.', style: TextStyle(color: AppTheme.textDim)));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 90),
      itemCount: _pendingPayments.length,
      itemBuilder: (context, index) {
        final p = _pendingPayments[index];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderCard),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['user'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13)),
                  Text(widget.appState.formatPrice(p['amount']), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppTheme.cyan)),
                ],
              ),
              const SizedBox(height: 4),
              Text('Method: ${p['method']} • Slip: ${p['slip_no']}', style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
              const Divider(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () {
                      setState(() => _pendingPayments.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Slip rejected.')));
                    },
                    style: OutlinedButton.styleFrom(foregroundColor: AppTheme.errorRed, side: const BorderSide(color: AppTheme.errorRed)),
                    child: const Text('Reject', style: TextStyle(fontSize: 11)),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _pendingPayments.removeAt(index));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Payment approved & credited to user wallet!'), backgroundColor: AppTheme.emeraldGreen),
                      );
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppTheme.mintGreen, foregroundColor: Colors.black),
                    child: const Text('Approve Slip', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDualPrizePayoutsView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 90),
      itemCount: _prizes.length,
      itemBuilder: (context, index) {
        final p = _prizes[index];
        final mgrApproved = p['mgr_approved'] as bool;
        final finApproved = p['finance_approved'] as bool;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(p['winner'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 14)),
                  Text(widget.appState.formatPrice(p['amount']), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.fireOrange)),
                ],
              ),
              const SizedBox(height: 4),
              Text(p['tournament'], style: const TextStyle(fontSize: 11, color: AppTheme.textDim)),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildSignoffBadge('Manager 1st Signoff', mgrApproved),
                  const SizedBox(width: 8),
                  _buildSignoffBadge('Finance 2nd Signoff', finApproved),
                ],
              ),
              const Divider(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (!mgrApproved)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          p['mgr_approved'] = true;
                          p['status'] = 'AWAITING_FINANCE_APPROVAL';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Step 1 Tournament Manager approval signed!')),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.purple),
                      child: const Text('Manager Sign-Off', style: TextStyle(fontSize: 11)),
                    )
                  else if (!finApproved)
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          p['finance_approved'] = true;
                          p['status'] = 'DISBURSED_TO_WALLET';
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Step 2 Dual-Approval complete! Winnings credited to wallet.'), backgroundColor: AppTheme.emeraldGreen),
                        );
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppTheme.emeraldGreen),
                      child: const Text('Finance Dual-Approve', style: TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold)),
                    )
                  else
                    const Text('DISBURSED TO WALLET ✅', style: TextStyle(color: AppTheme.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSignoffBadge(String title, bool isDone) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isDone ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.bgSecondary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isDone ? AppTheme.emeraldGreen : AppTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isDone ? Icons.check_circle : Icons.radio_button_unchecked, size: 12, color: isDone ? AppTheme.emeraldGreen : AppTheme.textDim),
          const SizedBox(width: 4),
          Text(title, style: TextStyle(fontSize: 9, color: isDone ? AppTheme.emeraldGreen : AppTheme.textDim, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildAiKeyVaultView() {
    return ListView.builder(
      padding: const EdgeInsets.only(left: 14, right: 14, top: 14, bottom: 90),
      itemCount: _aiKeys.length,
      itemBuilder: (context, index) {
        final k = _aiKeys[index];
        final isAvailable = k['status'] == 'AVAILABLE';

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppTheme.bgCard,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderCard),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k['tool'], style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.textMain, fontSize: 13)),
                  const SizedBox(height: 2),
                  SelectableText(k['code'], style: const TextStyle(fontSize: 11, color: AppTheme.cyan, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isAvailable ? AppTheme.emeraldGreen.withOpacity(0.15) : AppTheme.bgSecondary,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  k['status'],
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: isAvailable ? AppTheme.emeraldGreen : AppTheme.textDim,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
