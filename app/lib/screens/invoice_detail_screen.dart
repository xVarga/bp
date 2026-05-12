import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'add_invoice_screen.dart';
import '../utils/date_formatter.dart';


class InvoiceDetailScreen extends StatefulWidget {
    final int invoiceId;

    const InvoiceDetailScreen({super.key, required this.invoiceId});

    @override
    State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
    }

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
    final _authService = AuthService();
    Map<String, dynamic>? _invoice;
    List<dynamic> _history = [];
    bool _isLoading = true;
    bool _showHistory = false;
    String? _errorMessage;

    @override
    void initState() {
        super.initState();
        _loadInvoice();
    }

    Future<void> _loadInvoice() async {
        setState(() => _isLoading = true);
        final result = await _authService.getInvoice(widget.invoiceId);
        if (result['success'] == true) {
        final history = await _authService.getInvoiceHistory(widget.invoiceId);
        setState(() {
            _invoice = result['invoice'];
            _history = history;
            _isLoading = false;
        });
        } else {
        setState(() {
            _errorMessage = result['error'];
            _isLoading = false;
        });
        }
    }

    Future<void> _deleteInvoice() async {
        final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
            title: const Text('Vymazať faktúru'),
            content: const Text(
            'Naozaj chcete vymazať celú faktúru aj s celou históriou verzií? Táto akcia je nevratná.',
            ),
            actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Zrušiť'),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Vymazať', style: TextStyle(color: Colors.white)),
            ),
            ],
        ),
        );

        if (confirm != true) return;
        final success = await _authService.deleteInvoice(_invoice!['id']);
        if (success && mounted) {
        Navigator.pop(context, true);
        }
    }

    Future<void> _cancelVersion(int id) async {
        final confirm = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
            title: const Text('Zrušiť verziu'),
            content: const Text('Táto verzia bude označená ako neplatná. Zostane viditeľná v histórii.'),
            actions: [
            TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Naspäť'),
            ),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Zrušiť verziu', style: TextStyle(color: Colors.white)),
            ),
            ],
        ),
    );

    if (confirm != true) return;
    await _authService.cancelInvoice(id);
    await _loadInvoice();
    }

    bool get _isLatestVersion {
        if (_invoice == null || _history.isEmpty) return true;
        final maxVersion = _history.map((v) => v['version'] as int).reduce((a, b) => a > b ? a : b);
        return _invoice!['version'] == maxVersion;
    }

    @override
    Widget build(BuildContext context) {
        return Scaffold(
        appBar: AppBar(
            title: Text(
            _invoice != null
                ? 'Faktúra ${_invoice!['invoice_number']}'
                : 'Detail faktúry',
            ),
            actions: [
            if (_invoice != null) ...[
                IconButton(
                icon: Icon(_showHistory ? Icons.description : Icons.history),
                tooltip: _showHistory ? 'Detail' : 'História verzií',
                onPressed: () => setState(() => _showHistory = !_showHistory),
                ),
                if (_isLatestVersion)
                IconButton(
                    icon: const Icon(Icons.edit),
                    tooltip: 'Upraviť',
                    onPressed: () async {
                    final updated = await Navigator.push(
                        context,
                        MaterialPageRoute(
                        builder: (_) => AddInvoiceScreen(invoice: _invoice!),
                        ),
                    );
                    if (updated == true) {
                        if (!mounted) return;
                        Navigator.pop(context, true);
                    }
                    },
                ),
                IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                tooltip: 'Vymazať faktúru',
                onPressed: _deleteInvoice,
                ),
            ],
            ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _errorMessage != null
                ? Center(
                    child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                    ),
                    )
                : _showHistory
                    ? _buildHistory()
                    : _buildDetail(),
        );
    }

    Widget _buildDetail() {
        final invoice = _invoice!;
        final items = (invoice['items'] as List?) ?? [];

        return ListView(
        padding: const EdgeInsets.all(16),
        children: [
            Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
            ),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                const Text('Verzia', style: TextStyle(color: Colors.indigo)),
                Text(
                    'v${invoice['version']}',
                    style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.indigo,
                    fontSize: 16,
                    ),
                ),
                ],
            ),
            ),
            const SizedBox(height: 16),

            _sectionTitle('Základné informácie'),
            _infoRow('Číslo faktúry', invoice['invoice_number']),
            _infoRow('Dátum vyhotovenia', formatDate(invoice['issue_date'])),
            _infoRow('Dátum dodania', formatDate(invoice['delivery_date'])),
            _infoRow('Celková suma bez DPH', '${invoice["total_without_vat"]} €'),
            _infoRow('DPH', '${invoice["total_vat_amount"]} €'),
            _infoRow('Celková suma s DPH', '${invoice["total_with_vat"]} €'),
            const SizedBox(height: 24),

            _sectionTitle('Položky (${items.length})'),
            const SizedBox(height: 8),
            ...items.asMap().entries.map((e) => _itemCard(e.key, e.value)),
        ],
        );
    }

Widget _buildHistory() {
        if (_history.isEmpty) {
        return const Center(
            child: Text('Žiadna história', style: TextStyle(color: Colors.grey)),
        );
        }

        return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _history.length,
        itemBuilder: (context, index) {
            final v = _history[index];
            final isCurrent = v['id'] == _invoice!['id'];
            return Card(
            margin: const EdgeInsets.only(bottom: 12),
            color: isCurrent ? Colors.indigo.shade50 : (v['is_cancelled'] == true ? Colors.red.shade50 : null),
            child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: isCurrent
                    ? null
                    : () async {
                        final result = await _authService.getInvoice(v['id']);
                        if (result['success'] == true && mounted) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                            builder: (_) => InvoiceDetailScreen(invoiceId: v['id']),
                            ),
                        );
                        }
                    },
                child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                    children: [
                    Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                        color: isCurrent ? Colors.indigo : Colors.grey.shade200,
                        shape: BoxShape.circle,
                        ),
                        child: Center(
                        child: Text(
                            'v${v['version']}',
                            style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrent ? Colors.white : Colors.grey.shade700,
                            fontSize: 12,
                            ),
                        ),
                        ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            Row(
                            children: [
                                Text(
                                'Verzia ${v['version']}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                if (isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                    color: Colors.indigo,
                                    borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                    'aktuálna',
                                    style: TextStyle(color: Colors.white, fontSize: 11),
                                    ),
                                ),
                                ],
                            ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                            'Vyhotovenie: ${formatDate(v['issue_date'])} | DPH: ${v['total_vat_amount']} €',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                        ],
                        ),
                    ),
                    if (!isCurrent)
                        v['is_cancelled'] == true
                            ? const Icon(Icons.cancel, color: Colors.red)
                            : IconButton(
                                icon: const Icon(Icons.block, color: Colors.orange),
                                tooltip: 'Zrušiť verziu',
                                onPressed: () => _cancelVersion(v['id']),
                            ),
                    ],
                ),
                ),
            ),
            );
        },
        );
    }

    Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
        title,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
    );

    Widget _infoRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
            Text(label, style: const TextStyle(color: Colors.grey)),
            Text(
            value?.toString() ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w500),
            ),
        ],
        ),
    );

    /*Widget _boolRow(String label, dynamic value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
        children: [
            Icon(
            value == true ? Icons.check_box : Icons.check_box_outline_blank,
            size: 20,
            color: value == true ? Colors.indigo : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(label),
        ],
        ),
    );*/

    Widget _itemCard(int index, Map<String, dynamic> item) => Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Text(
                'Položka ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Divider(),
            _infoRow('Popis', item['description']),
            _infoRow('Množstvo', item['quantity']?.toString()),
            _infoRow('Jednotková cena', '${item["unit_price"]} €'),
            _infoRow('Základ dane', '${item["total_without_vat"]} €'),
            _infoRow('Sadzba DPH', '${item["tax_rate"]} %'),
            _infoRow('Celkom s DPH', '${item["total_with_vat"]} €'),
            ],
        ),
        ),
    );
}