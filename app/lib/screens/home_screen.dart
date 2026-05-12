import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'add_invoice_screen.dart';
import 'add_receipt_screen.dart';
import 'invoice_detail_screen.dart';
import 'profile_screen.dart';
import 'receipt_detail_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/date_formatter.dart';


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
        title: const Text('Výdavky'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Odhlásiť',
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
            },
          ),
        ],
      ),
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.indigo,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Domov'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Záznamy'),
          BottomNavigationBarItem(icon: Icon(Icons.qr_code_scanner), label: 'Skener'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Štatistika'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profil'),
        ],
      ),
    );
  }

  /*Widget _navTab(String label, IconData icon, int index) {
    final isSelected = _selectedIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isSelected ? Colors.indigo : Colors.transparent, width: 2)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.indigo : Colors.grey),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, color: isSelected ? Colors.indigo : Colors.grey, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            ],
          ),
        ),
      ),
    );
  }*/
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
          Text('Vitaj, ${user['first_name']} ${user['last_name']}!', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
  List<dynamic> _receipts = [];
  bool _isLoading = true;
  String? _filter;
  int? _filterMonth;
  int? _filterYear;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final invoices = await AuthService().getInvoices();
    final receipts = await AuthService().getReceipts();
    setState(() {
      _invoices = invoices;
      _receipts = receipts;
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> get _combinedList {
    final List<Map<String, dynamic>> combined = [];
    if (_filter == null || _filter == 'invoices') {
      for (final inv in _invoices) {
        if (_matchesPeriod(inv['issue_date'])) {
          combined.add({...Map<String, dynamic>.from(inv), '_type': 'invoice'});
        }
      }
    }
    if (_filter == null || _filter == 'receipts') {
      for (final rec in _receipts) {
        if (_matchesPeriod(rec['issued_at'])) {
          combined.add({...Map<String, dynamic>.from(rec), '_type': 'receipt'});
        }
      }
    }
    return combined;
  }

  bool _matchesPeriod(String? dateStr) {
    if (_filterMonth == null && _filterYear == null) return true;
    final date = DateTime.tryParse(dateStr ?? '');
    if (date == null) return false;
    if (_filterYear != null && date.year != _filterYear) return false;
    if (_filterMonth != null && date.month != _filterMonth) return false;
    return true;
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Zobraziť', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              RadioListTile<String?>(
                title: const Text('Všetko'),
                secondary: const Icon(Icons.list, color: Colors.indigo),
                value: null,
                groupValue: _filter,
                onChanged: (v) { setState(() => _filter = v); Navigator.pop(ctx); },
              ),
              RadioListTile<String?>(
                title: const Text('Len faktúry'),
                secondary: const Icon(Icons.receipt_long, color: Colors.indigo),
                value: 'invoices',
                groupValue: _filter,
                onChanged: (v) { setState(() => _filter = v); Navigator.pop(ctx); },
              ),
              RadioListTile<String?>(
                title: const Text('Len bločky'),
                secondary: const Icon(Icons.store, color: Colors.teal),
                value: 'receipts',
                groupValue: _filter,
                onChanged: (v) { setState(() => _filter = v); Navigator.pop(ctx); },
              ),
              const Divider(),
              const Text('Obdobie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(labelText: 'Mesiac', border: OutlineInputBorder()),
                      value: _filterMonth,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Všetky')),
                        ...List.generate(12, (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(['Jan','Feb','Mar','Apr','Máj','Jún','Júl','Aug','Sep','Okt','Nov','Dec'][i]),
                        )),
                      ],
                      onChanged: (v) => setModalState(() => _filterMonth = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      decoration: const InputDecoration(labelText: 'Rok', border: OutlineInputBorder()),
                      value: _filterYear,
                      items: [
                        const DropdownMenuItem(value: null, child: Text('Všetky')),
                        ...List.generate(5, (i) => DropdownMenuItem(
                          value: DateTime.now().year - i,
                          child: Text('${DateTime.now().year - i}'),
                        )),
                      ],
                      onChanged: (v) => setModalState(() => _filterYear = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() { _filterMonth = null; _filterYear = null; });
                        Navigator.pop(ctx);
                      },
                      child: const Text('Vymazať obdobie'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {});
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white),
                      child: const Text('Použiť'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Pridať', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.receipt_long, color: Colors.indigo),
              title: const Text('Faktúra'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddInvoiceScreen()));
                if (result == true) _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.store, color: Colors.teal),
              title: const Text('Bloček'),
              onTap: () async {
                Navigator.pop(context);
                final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const AddReceiptScreen()));
                if (result == true) _loadData();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final combined = _combinedList;
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _filter == null ? 'Všetky záznamy' : _filter == 'invoices' ? 'Faktúry' : 'Bločky',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _showFilterSheet,
                    icon: const Icon(Icons.filter_list, size: 18),
                    label: const Text('Filter'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : combined.isEmpty
                  ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.receipt_long, size: 72, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('Zatiaľ žiadne záznamy', style: TextStyle(color: Colors.grey, fontSize: 16)),
                  ],
                ),
              )
                  : RefreshIndicator(
                onRefresh: _loadData,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  itemCount: combined.length,
                  itemBuilder: (context, index) {
                    final item = combined[index];
                    return item['_type'] == 'invoice' ? _buildInvoiceCard(item) : _buildReceiptCard(item);
                  },
                ),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton(onPressed: _showAddSheet, child: const Icon(Icons.add)),
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(Map<String, dynamic> invoice) {
    final items = (invoice['items'] as List?) ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push(context, MaterialPageRoute(builder: (_) => InvoiceDetailScreen(invoiceId: invoice['id'])));
          if (updated == true) _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.receipt, color: Colors.indigo),
                        const SizedBox(width: 8),
                        Flexible(child: Text(invoice['invoice_number'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                        if ((invoice['version'] ?? 1) > 1) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.indigo.shade100, borderRadius: BorderRadius.circular(10)),
                            child: Text('v${invoice['version']}', style: TextStyle(fontSize: 11, color: Colors.indigo.shade700, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${invoice['total_with_vat']} €', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Vyhotovenie: ${formatDate(invoice['issue_date'])}', style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  const Icon(Icons.local_shipping, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(child: Text('Dodanie: ${formatDate(invoice['delivery_date'])}', style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...items.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('• ${item['description']}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('${item['quantity']} x ${item['unit_price']} € | DPH ${item['tax_rate']}%', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReceiptCard(Map<String, dynamic> receipt) {
    final items = (receipt['items'] as List?) ?? [];
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final updated = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => ReceiptDetailScreen(receiptId: receipt['id'])),
          );
          if (updated == true) _loadData();
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        const Icon(Icons.store, color: Colors.teal),
                        const SizedBox(width: 8),
                        Flexible(child: Text(receipt['merchant_name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${receipt['total_amount']} €', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                ],
              ),
              const Divider(height: 16),
              Row(
                children: [
                  const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Flexible(child: Text(formatDateTime(receipt['issued_at']), style: const TextStyle(color: Colors.grey, fontSize: 13), overflow: TextOverflow.ellipsis)),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 8),
                ...items.take(3).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: Text('• ${item['description']}', style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
                      const SizedBox(width: 8),
                      Text('${item['total_price']} €', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                )),
                if (items.length > 3)
                  Text('+ ${items.length - 3} ďalších položiek', style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ],
          ),
        ),
      )
    );
  }
}

class _StatisticsPage extends StatefulWidget {
  const _StatisticsPage();

  @override
  State<_StatisticsPage> createState() => _StatisticsPageState();
}

enum _Period { weeks, months, quarters, years }

class _StatisticsPageState extends State<_StatisticsPage> {
  List<dynamic> _invoices = [];
  List<dynamic> _receipts = [];
  bool _isLoading = true;
  _Period _period = _Period.months;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final invoices = await AuthService().getInvoices();
    final receipts = await AuthService().getReceipts();
    setState(() {
      _invoices = invoices;
      _receipts = receipts;
      _isLoading = false;
    });
  }

  // ── Pomocné metódy ──────────────────────────────────────────

  DateTime? _parseDate(String? s) => s == null ? null : DateTime.tryParse(s);

  double _sumInvoices(bool Function(DateTime) filter) => _invoices.fold(0.0, (sum, inv) {
    final d = _parseDate(inv['issue_date']);
    if (d == null || !filter(d)) return sum;
    return sum + (double.tryParse(inv['total_with_vat']?.toString() ?? '0') ?? 0);
  });

  double _sumReceipts(bool Function(DateTime) filter) => _receipts.fold(0.0, (sum, rec) {
    final d = _parseDate(rec['issued_at']);
    if (d == null || !filter(d)) return sum;
    return sum + (double.tryParse(rec['total_amount']?.toString() ?? '0') ?? 0);
  });

  double _total(bool Function(DateTime) filter) => _sumInvoices(filter) + _sumReceipts(filter);

  // ── Aktuálne obdobie ────────────────────────────────────────

  double get _currentPeriodTotal {
    final now = DateTime.now();
    switch (_period) {
      case _Period.weeks:
        final start = now.subtract(Duration(days: now.weekday - 1));
        return _total((d) => d.isAfter(start.subtract(const Duration(days: 1))) && d.isBefore(now.add(const Duration(days: 1))));
      case _Period.months:
        return _total((d) => d.year == now.year && d.month == now.month);
      case _Period.quarters:
        final q = ((now.month - 1) ~/ 3);
        return _total((d) => d.year == now.year && ((d.month - 1) ~/ 3) == q);
      case _Period.years:
        return _total((d) => d.year == now.year);
    }
  }

  double get _thisMonthTotal {
    final now = DateTime.now();
    return _total((d) => d.year == now.year && d.month == now.month);
  }

  double get _thisYearTotal {
    final now = DateTime.now();
    return _total((d) => d.year == now.year);
  }

  int get _thisMonthCount {
    final now = DateTime.now();
    bool f(d) => d != null && d.year == now.year && d.month == now.month;
    return _invoices.where((i) => f(_parseDate(i['issue_date']))).length +
           _receipts.where((r) => f(_parseDate(r['issued_at']))).length;
  }

  // ── Obdobia pre grafy ───────────────────────────────────────

  List<Map<String, dynamic>> _getPeriods(int offset) {
    final now = DateTime.now();
    switch (_period) {
      case _Period.months:
        return List.generate(6, (i) {
          final dt = DateTime(now.year, now.month - offset + i);
          return {'label': _monthLabel(dt), 'year': dt.year, 'month': dt.month};
        });
      case _Period.quarters:
        return List.generate(6, (i) {
          final totalQ = (now.year * 4 + (now.month - 1) ~/ 3) - (offset + 1) + i;
          final year = totalQ ~/ 4;
          final q = totalQ % 4;
          return {'label': 'Q${q + 1} $year', 'year': year, 'quarter': q};
        });
      case _Period.years:
        return List.generate(6, (i) {
          final year = now.year - (offset + 1) + i;
          return {'label': '$year', 'year': year};
        });
      case _Period.weeks:
        return List.generate(6, (i) {
          final start = now.subtract(Duration(days: now.weekday - 1 + 7 * (offset - i)));
          final end = start.add(const Duration(days: 6));
          return {'label': 'T-${offset - i}', 'start': start, 'end': end};
        });
    }
  }

  double _periodTotal(Map<String, dynamic> p) {
    switch (_period) {
      case _Period.weeks:
        final start = p['start'] as DateTime;
        final end = p['end'] as DateTime;
        return _total((d) => !d.isBefore(start) && !d.isAfter(end));
      case _Period.months:
        return _total((d) => d.year == p['year'] && d.month == p['month']);
      case _Period.quarters:
        return _total((d) => d.year == p['year'] && ((d.month - 1) ~/ 3) == p['quarter']);
      case _Period.years:
        return _total((d) => d.year == p['year']);
    }
  }

  String _monthLabel(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'Máj', 'Jún', 'Júl', 'Aug', 'Sep', 'Okt', 'Nov', 'Dec'];
    return months[date.month - 1];
  }

  String get _periodLabel {
    switch (_period) {
      case _Period.weeks: return 'Týždenné výdavky';
      case _Period.months: return 'Mesačné výdavky';
      case _Period.quarters: return 'Kvartálne výdavky';
      case _Period.years: return 'Ročné výdavky';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final periodsChart1 = _getPeriods(5);
    final periodsChart2 = _getPeriods(6);
    final current = _currentPeriodTotal;

    // Pre graf 1 — absolútne hodnoty
    final maxVal = periodsChart1.map((p) => _periodTotal(p)).fold(0.0, (a, b) => a > b ? a : b);

    // Pre graf 2 — rozdiely oproti aktuálnemu
    final diffs = periodsChart2.map((p) => _periodTotal(p) - current).toList();
    final maxDiff = diffs.map((d) => d.abs()).fold(0.0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Summary karty ─────────────────────────────────────
          Row(
            children: [
              Expanded(child: _summaryCard('Tento mesiac', '${_thisMonthTotal.toStringAsFixed(2)} €', Icons.calendar_today, Colors.indigo)),
              const SizedBox(width: 12),
              Expanded(child: _summaryCard('Tento rok', '${_thisYearTotal.toStringAsFixed(2)} €', Icons.calendar_month, Colors.teal)),
            ],
          ),
          const SizedBox(height: 12),
          _summaryCard('Záznamy tento mesiac', '$_thisMonthCount', Icons.receipt_long, Colors.orange),
          const SizedBox(height: 24),

          // ── Filter ────────────────────────────────────────────
          Row(
            children: [
              _filterChip('Týždne', _Period.weeks),
              const SizedBox(width: 8),
              _filterChip('Mesiace', _Period.months),
              const SizedBox(width: 8),
              _filterChip('Kvartály', _Period.quarters),
              const SizedBox(width: 8),
              _filterChip('Roky', _Period.years),
            ],
          ),
          const SizedBox(height: 24),

          // ── Graf 1: Absolútne výdavky ─────────────────────────
          Text(_periodLabel, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(children: [
            _legendDot(Colors.indigo, 'Faktúry'),
            const SizedBox(width: 16),
            _legendDot(Colors.teal, 'Bločky'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(BarChartData(
              maxY: maxVal == 0 ? 100 : maxVal * 1.2,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final label = ri == 0 ? 'Faktúry' : 'Bločky';
                    return BarTooltipItem('$label\n${rod.toY.toStringAsFixed(2)} €', const TextStyle(color: Colors.white, fontSize: 12));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= periodsChart1.length) return const SizedBox();
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(periodsChart1[i]['label'], style: const TextStyle(fontSize: 10)));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) => Text('${value.toInt()} €', style: const TextStyle(fontSize: 9)),
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(drawVerticalLine: false, getDrawingHorizontalLine: (v) => FlLine(color: Colors.grey.shade200, strokeWidth: 1)),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(periodsChart1.length, (i) {
                final p = periodsChart1[i];
                final inv = _period == _Period.months
                    ? _sumInvoices((d) => d.year == p['year'] && d.month == p['month'])
                    : _period == _Period.years
                        ? _sumInvoices((d) => d.year == p['year'])
                        : _period == _Period.quarters
                            ? _sumInvoices((d) => d.year == p['year'] && ((d.month - 1) ~/ 3) == p['quarter'])
                            : _sumInvoices((d) => !d.isBefore(p['start']) && !d.isAfter(p['end']));
                final rec = _periodTotal(p) - inv;
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(toY: inv, color: Colors.indigo, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                  BarChartRodData(toY: rec, color: Colors.teal, width: 14, borderRadius: const BorderRadius.vertical(top: Radius.circular(4))),
                ], barsSpace: 4);
              }),
            )),
          ),
          const SizedBox(height: 32),

          // ── Graf 2: Porovnanie s aktuálnym ───────────────────
          Text('Porovnanie s aktuálnym obdobím', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Aktuálne: ${current.toStringAsFixed(2)} €', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
          const SizedBox(height: 4),
          Row(children: [
            _legendDot(Colors.green, 'Míňali ste menej'),
            const SizedBox(width: 16),
            _legendDot(Colors.red, 'Míňali ste viac'),
          ]),
          const SizedBox(height: 16),
          SizedBox(
            height: 250,
            child: BarChart(BarChartData(
              minY: maxDiff == 0 ? -100 : -maxDiff * 1.2,
              maxY: maxDiff == 0 ? 100 : maxDiff * 1.2,
              baselineY: 0,
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, gi, rod, ri) {
                    final diff = diffs[gi];
                    final sign = diff >= 0 ? '+' : '';
                    return BarTooltipItem('$sign${diff.toStringAsFixed(2)} €', const TextStyle(color: Colors.white, fontSize: 12));
                  },
                ),
              ),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final i = value.toInt();
                    if (i < 0 || i >= periodsChart2.length) return const SizedBox();
                    return Padding(padding: const EdgeInsets.only(top: 8), child: Text(periodsChart2[i]['label'], style: const TextStyle(fontSize: 10)));
                  },
                )),
                leftTitles: AxisTitles(sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 52,
                  getTitlesWidget: (value, meta) {
                    final sign = value >= 0 ? '+' : '';
                    return Text('$sign${value.toInt()} €', style: const TextStyle(fontSize: 9));
                  },
                )),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              gridData: FlGridData(
                drawVerticalLine: false,
                getDrawingHorizontalLine: (v) => FlLine(
                  color: v == 0 ? Colors.grey.shade500 : Colors.grey.shade200,
                  strokeWidth: v == 0 ? 1.5 : 1,
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: List.generate(periodsChart2.length, (i) {
                final diff = diffs[i];
                return BarChartGroupData(x: i, barRods: [
                  BarChartRodData(
                    toY: diff,
                    color: diff >= 0 ? Colors.green : Colors.red,
                    width: 20,
                    borderRadius: diff >= 0
                        ? const BorderRadius.vertical(top: Radius.circular(4))
                        : const BorderRadius.vertical(bottom: Radius.circular(4)),
                  ),
                ]);
              }),
            )),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _Period period) {
    final isSelected = _period == period;
    return GestureDetector(
      onTap: () => setState(() => _period = period),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.indigo : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey, fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      ),
    );
  }

  Widget _summaryCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: color, fontSize: 12)),
                Text(value, style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
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
  final TextEditingController _manualController = TextEditingController();
  String? _scannedValue;
  bool _hasScanned = false;
  bool _isLooking = false;
  Map<String, dynamic>? _receiptData;
  Map<String, dynamic>? _invoiceData;
  String? _errorMessage;
  String? _detectedType; // 'ekasa' or 'bysquare'

  @override
  void dispose() {
    _controller.dispose();
    _manualController.dispose();
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
      _processCode(barcode!.rawValue!);
    }
  }

  // eKasa UID starts with O- or 0-
  bool _isEkasa(String value) {
    return value.startsWith('O-') || value.startsWith('0-') || value.length < 50;
  }

  Future<void> _processCode(String value) async {
    if (_isEkasa(value)) {
      await _lookupEkasa(value);
    } else {
      await _decodeBysquare(value);
    }
  }

  Future<void> _lookupEkasa(String receiptId) async {
    setState(() {
      _isLooking = true;
      _receiptData = null;
      _invoiceData = null;
      _errorMessage = null;
      _detectedType = 'ekasa';
    });

    final result = await AuthService().findEkasaReceipt(receiptId);

    setState(() {
      _isLooking = false;
      if (result['returnValue'] == 0 && result['receipt'] != null) {
        _receiptData = result['receipt'];
      } else {
        _errorMessage = 'Bloček sa nenašiel v systéme eKasa.';
      }
    });
  }

  Future<void> _decodeBysquare(String payload) async {
    setState(() {
      _isLooking = true;
      _receiptData = null;
      _invoiceData = null;
      _errorMessage = null;
      _detectedType = 'bysquare';
    });

    final result = await AuthService().decodeBysquare(payload);

    setState(() {
      _isLooking = false;
      if (result['format'] == 'invoice' && result['document'] != null) {
        _invoiceData = result['document'];
      } else {
        _errorMessage = 'Nepodarilo sa dekódovať QR kód faktúry.';
      }
    });
  }

  void _reset() {
    setState(() {
      _scannedValue = null;
      _hasScanned = false;
      _receiptData = null;
      _invoiceData = null;
      _errorMessage = null;
      _detectedType = null;
      _manualController.clear();
    });
    _controller.start();
  }

  Future<void> _saveEkasaReceipt() async {
    if (_receiptData == null) return;
    final data = _receiptData!;
    final org = data['organization'] as Map<String, dynamic>?;

    final address = [
      data['unit']?['streetName'],
      data['unit']?['propertyRegistrationNumber'],
      data['unit']?['municipality'],
      data['unit']?['postalCode'],
    ].where((e) => e != null && e.toString().isNotEmpty).join(', ');

    final items = ((data['items'] as List?) ?? []).map((item) => {
      'description': item['name'],
      'quantity': item['quantity'],
      'unit_price': item['price'],
      'total_price': (item['quantity'] as num) * (item['price'] as num),
    }).toList();

    final body = {
      'receipt': {
        'merchant_name': org?['name'],
        'merchant_address': address,
        'ico': data['ico'],
        'dic': data['dic'],
        'ic_dph': data['icDph'],
        'cash_register_code': data['cashRegisterCode'],
        'receipt_number': data['receiptNumber']?.toString(),
        'issued_at': _parseEkasaDate(data['issueDate']),
        'total_amount': data['totalPrice'],
        'receipt_items_attributes': items,
      }
    };

    final result = await AuthService().createReceipt(body);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bloček bol uložený!')));
      _reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Chyba pri ukladaní')));
    }
  }

  Future<void> _saveBysquareInvoice() async {
    if (_invoiceData == null) return;
    final doc = _invoiceData!;
    final supplier = doc['supplierParty'] as Map<String, dynamic>?;
    final customer = doc['customerParty'] as Map<String, dynamic>?;
    final monetary = doc['monetarySummary'] as Map<String, dynamic>?;
    final taxSummaries = (doc['taxCategorySummaries'] as List?) ?? [];

    // Create supplier company first if exists
    int? supplierId;
    int? customerId;

    if (supplier != null) {
      final addr = supplier['postalAddress'] as Map<String, dynamic>?;
      final supplierResult = await AuthService().createCompany({
        'company': {
          'company_name': supplier['partyName'],
          'ico': supplier['companyTaxId'],
          'ic_dph': supplier['companyVatId'],
          'street': addr?['streetName'],
          'city': addr?['cityName'],
          'zip': addr?['postalZone'],
          'country': addr?['country'],
        }
      });
      if (supplierResult['success'] == true) {
        supplierId = supplierResult['company']['id'];
      }
    }

    if (customer != null) {
      final customerResult = await AuthService().createCompany({
        'company': {
          'company_name': customer['partyName'],
          'ico': customer['companyTaxId'],
          'ic_dph': customer['companyVatId'],
        }
      });
      if (customerResult['success'] == true) {
        customerId = customerResult['company']['id'];
      }
    }

    // Build invoice items from taxCategorySummaries
    final items = taxSummaries.map((tax) => {
      'description': doc['invoiceDescription'] ?? doc['singleInvoiceLine']?['itemName'] ?? 'Položka',
      'quantity': doc['singleInvoiceLine']?['invoicedQuantity'] ?? 1,
      'unit_price': doc['singleInvoiceLine']?['unitPriceTaxExclusiveAmount'] ?? tax['taxExclusiveAmount'],
      'tax_rate': tax['classifiedTaxCategory'],
      'vat_amount': tax['taxAmount'],
      'total_without_vat': tax['taxExclusiveAmount'],
      'total_with_vat': tax['taxInclusiveAmount'],
    }).toList();

    final body = {
      'invoice': {
        'invoice_number': doc['invoiceId'],
        'issue_date': doc['issueDate'],
        'delivery_date': doc['taxPointDate'] ?? doc['issueDate'],
        'currency': doc['localCurrencyCode'],
        'total_vat_amount': monetary?['taxAmount'],
        'total_without_vat': monetary?['taxExclusiveAmount'],
        'total_with_vat': monetary?['taxInclusiveAmount'],
        'supplier_id': supplierId,
        'customer_id': customerId,
        'invoice_items_attributes': items,
      }
    };

    final result = await AuthService().createInvoice(body);
    if (!mounted) return;

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faktúra bola uložená!')));
      _reset();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['error'] ?? 'Chyba pri ukladaní')));
    }
  }

  String? _parseEkasaDate(String? dateStr) {
    if (dateStr == null) return null;
    try {
      final parts = dateStr.split(' ');
      final dateParts = parts[0].split('.');
      return '${dateParts[2]}-${dateParts[1]}-${dateParts[0]} ${parts[1]}';
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // ── Kamera ──────────────────────────────────────────────
        Expanded(
          flex: 3,
          child: _hasScanned
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.check_circle, size: 72, color: Colors.green),
                  const SizedBox(height: 16),
                  const Text('QR kód naskenovaný!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ]))
              : Stack(children: [
                  MobileScanner(controller: _controller, onDetect: _onDetect),
                  Center(child: Container(width: 250, height: 250, decoration: BoxDecoration(border: Border.all(color: Colors.indigo, width: 3), borderRadius: BorderRadius.circular(12)))),
                  const Positioned(bottom: 16, left: 0, right: 0, child: Text('Namierte kameru na QR kód', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 14))),
                ]),
        ),

        // ── Dolná časť ──────────────────────────────────────────
        Expanded(
          flex: 3,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Manuálne zadanie
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _manualController,
                        decoration: InputDecoration(
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: () => _manualController.clear()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        final value = _manualController.text.trim();
                        if (value.isNotEmpty) {
                          setState(() { _scannedValue = value; _hasScanned = true; });
                          _controller.stop();
                          _processCode(value);
                        }
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16)),
                      child: const Text('Hľadať'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Výsledok
                if (_isLooking)
                  const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                else if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
                    child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                  )
                else if (_receiptData != null) ...[
                  const Text('Nájdený bloček (eKasa)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.teal.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.teal.shade200)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_receiptData!['organization']?['name'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Dátum: ${_receiptData!['issueDate'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      Text('Celkom: ${_receiptData!['totalPrice']} €', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal)),
                      Text('Počet položiek: ${(_receiptData!['items'] as List?)?.length ?? 0}', style: const TextStyle(color: Colors.grey)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveEkasaReceipt,
                      icon: const Icon(Icons.save),
                      label: const Text('Uložiť bloček'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ] else if (_invoiceData != null) ...[
                  const Text('Nájdená faktúra (By Square)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.indigo.shade200)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(_invoiceData!['supplierParty']?['partyName'] ?? '-', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text('Číslo: ${_invoiceData!['invoiceId'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      Text('Dátum: ${_invoiceData!['issueDate'] ?? '-'}', style: const TextStyle(color: Colors.grey)),
                      Text('Celkom: ${_invoiceData!['monetarySummary']?['taxInclusiveAmount']} €', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saveBysquareInvoice,
                      icon: const Icon(Icons.save),
                      label: const Text('Uložiť faktúru'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.indigo, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
                    ),
                  ),
                ],

                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _reset,
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Skenovať znovu'),
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
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