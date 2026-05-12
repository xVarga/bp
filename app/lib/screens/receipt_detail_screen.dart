import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../utils/date_formatter.dart';


class ReceiptDetailScreen extends StatefulWidget {
  final int receiptId;

  const ReceiptDetailScreen({super.key, required this.receiptId});

  @override
  State<ReceiptDetailScreen> createState() => _ReceiptDetailScreenState();
}

class _ReceiptDetailScreenState extends State<ReceiptDetailScreen> {
  final _authService = AuthService();
  Map<String, dynamic>? _receipt;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadReceipt();
  }

  Future<void> _loadReceipt() async {
    setState(() => _isLoading = true);
    final result = await _authService.getReceipt(widget.receiptId);
    if (result['success'] == true) {
      setState(() {
        _receipt = result['receipt'];
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['error'];
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteReceipt() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Vymazať bloček'),
        content: const Text('Naozaj chcete vymazať tento bloček? Táto akcia je nevratná.'),
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
    final success = await _authService.deleteReceipt(_receipt!['id']);
    if (success && mounted) {
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_receipt != null ? _receipt!['merchant_name'] ?? 'Detail bločku' : 'Detail bločku'),
        actions: [
          if (_receipt != null)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: 'Vymazať bloček',
              onPressed: _deleteReceipt,
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : _buildDetail(),
    );
  }

  Widget _buildDetail() {
    final receipt = _receipt!;
    final items = (receipt['items'] as List?) ?? [];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Obchodník ───────────────────────────────────────────
        _sectionTitle('Obchodník'),
        _infoRow('Názov', receipt['merchant_name']),
        _infoRow('Adresa', receipt['merchant_address']),
        _infoRow('IČO', receipt['ico']),
        _infoRow('DIČ', receipt['dic']),
        _infoRow('IČ DPH', receipt['ic_dph']),
        _infoRow('Kód pokladnice', receipt['cash_register_code']),
        _infoRow('Poradové číslo', receipt['receipt_number']),
        const SizedBox(height: 24),

        // ── Dátum a čas ─────────────────────────────────────────
        _sectionTitle('Dátum a čas vyhotovenia'),
        _infoRow('Dátum a čas', formatDateTime(receipt['issued_at'])),
        const SizedBox(height: 24),

        // ── Položky ─────────────────────────────────────────────
        _sectionTitle('Položky (${items.length})'),
        const SizedBox(height: 8),
        ...items.asMap().entries.map((e) => _itemCard(e.key, e.value)),
        const SizedBox(height: 16),

        // ── Celková suma ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.teal.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.teal.shade200),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Celková suma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text(
                '${receipt['total_amount']} €',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.teal),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _sectionTitle(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );

  Widget _infoRow(String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Flexible(
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCard(int index, Map<String, dynamic> item) => Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Položka ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const Divider(),
          _infoRow('Popis', item['description']),
          _infoRow('Množstvo', item['quantity']?.toString()),
          _infoRow('Jednotková cena', '${item["unit_price"]} €'),
          _infoRow('Celkom', '${item["total_price"]} €'),
        ],
      ),
    ),
  );
}