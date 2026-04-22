import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'add_invoice_screen.dart';
import 'invoice_detail_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  final Map<String, dynamic> user;

  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  late Map<String, dynamic> _user;

  @override
  void initState() {
    super.initState();
    _user = widget.user;
  }

  void _onUserUpdated(Map<String, dynamic> updatedUser) {
    setState(() => _user = updatedUser);
  }

  List<Widget> get _pages => [
    _DashboardPage(user: _user),
    _InvoicesPage(user: _user),
    const _ScannerPage(),
    const _StatisticsPage(),
    ProfileScreen(user: _user, onUserUpdated: _onUserUpdated),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Faktúry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásiť',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Row(
            children: [
              _navTab('Domov', Icons.home, 0),
              _navTab('Faktúry', Icons.receipt_long, 1),
              _navTab('Skener', Icons.qr_code_scanner, 2),
              _navTab('Štatistika', Icons.bar_chart, 3),
              _navTab('Profil', Icons.person, 4),
            ],
          ),
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }

  Widget _navTab(String label, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.indigo : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.indigo : Colors.grey),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected ? Colors.indigo : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DashboardPage extends StatelessWidget {
  final Map<String, dynamic> user;

  const _DashboardPage({required this.user});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.account_circle, size: 72, color: Colors.indigo),
          const SizedBox(height: 16),
          Text(
            'Vitaj, ${user['first_name']} ${user['last_name']}!',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(user['email'] ?? '', style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

class _InvoicesPage extends StatefulWidget {
  final Map<String, dynamic> user;

  const _InvoicesPage({required this.user});

  @override
  State<_InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<_InvoicesPage> {
  List<dynamic> _invoices = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  Future<void> _loadInvoices() async {
    setState(() => _isLoading = true);
    final invoices = await AuthService().getInvoices();
    setState(() {
      _invoices = invoices;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _invoices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('Zatiaľ žiadne faktúry', style: TextStyle(color: Colors.grey, fontSize: 16)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInvoices,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _invoices.length,
                    itemBuilder: (context, index) {
                      final invoice = _invoices[index];
                      final items = (invoice['items'] as List?) ?? [];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () async {
                            final updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => InvoiceDetailScreen(invoiceId: invoice['id']),
                              ),
                            );
                            if (updated == true) _loadInvoices();
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.receipt, color: Colors.indigo),
                                        const SizedBox(width: 8),
                                        Text(
                                          invoice['invoice_number'] ?? '',
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        ),
                                        if ((invoice['version'] ?? 1) > 1) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.indigo.shade100,
                                              borderRadius: BorderRadius.circular(10),
                                            ),
                                            child: Text(
                                              'v${invoice['version']}',
                                              style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '${invoice['total_vat_amount']} €',
                                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                                    ),
                                  ],
                                ),
                                const Divider(height: 16),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Vyhotovenie: ${invoice['issue_date'] ?? '-'}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Dodanie: ${invoice['delivery_date'] ?? '-'}',
                                        style: const TextStyle(color: Colors.grey, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                if (items.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  ...items.map((item) => Padding(
                                    padding: const EdgeInsets.only(bottom: 4),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            '• ${item['description']}',
                                            style: const TextStyle(fontSize: 13),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          '${item['quantity']} x ${item['unit_price']} € | DPH ${item['tax_rate']}%',
                                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  )),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddInvoiceScreen()),
          );
          if (result == true) _loadInvoices();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _StatisticsPage extends StatelessWidget {
  const _StatisticsPage();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Text('Štatistika', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

class _ScannerPage extends StatefulWidget {
  const _ScannerPage();

  @override
  State<_ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<_ScannerPage> {
  final MobileScannerController _controller = MobileScannerController();
  String? _scannedValue;
  bool _hasScanned = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_hasScanned) return;
    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue != null) {
      setState(() {
        _scannedValue = barcode!.rawValue;
        _hasScanned = true;
      });
      _controller.stop();
    }
  }

  void _reset() {
    setState(() {
      _scannedValue = null;
      _hasScanned = false;
    });
    _controller.start();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: _hasScanned
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.check_circle, size: 72, color: Colors.green),
                      const SizedBox(height: 16),
                      const Text('QR kód naskenovaný!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    MobileScanner(
                      controller: _controller,
                      onDetect: _onDetect,
                    ),
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.indigo, width: 3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Text(
                        'Namierte kameru na QR kód',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
        ),
        Expanded(
          flex: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Výsledok', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SingleChildScrollView(
                      child: Text(
                        _scannedValue ?? 'Zatiaľ nič nenaskenované...',
                        style: TextStyle(
                          color: _scannedValue != null ? Colors.black : Colors.grey,
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Skenovať znovu'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}