import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AddReceiptScreen extends StatefulWidget {
  const AddReceiptScreen({super.key});

  @override
  State<AddReceiptScreen> createState() => _AddReceiptScreenState();
}

class _AddReceiptScreenState extends State<AddReceiptScreen> {
  final _formKey = GlobalKey<FormState>();

  final _merchantNameController = TextEditingController();
  final _merchantAddressController = TextEditingController();
  final _icoController = TextEditingController();
  final _dicController = TextEditingController();
  final _icDphController = TextEditingController();
  final _cashRegisterCodeController = TextEditingController();
  final _receiptNumberController = TextEditingController();

  DateTime? _issuedAt;
  TimeOfDay? _issuedTime;

  final List<Map<String, TextEditingController>> _items = [];
  double _totalAmount = 0.0;

  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _addItem();
  }

  @override
  void dispose() {
    _merchantNameController.dispose();
    _merchantAddressController.dispose();
    _icoController.dispose();
    _dicController.dispose();
    _icDphController.dispose();
    _cashRegisterCodeController.dispose();
    _receiptNumberController.dispose();
    for (final item in _items) {
      item.values.forEach((c) => c.dispose());
    }
    super.dispose();
  }

  void _addItem() {
    final qtyCtrl = TextEditingController(text: '1');
    final unitCtrl = TextEditingController();
    final totalCtrl = TextEditingController();

    void recalcItem() {
      final qty = double.tryParse(qtyCtrl.text) ?? 0;
      final unit = double.tryParse(unitCtrl.text) ?? 0;
      final total = qty * unit;
      if (totalCtrl.text != total.toStringAsFixed(2)) {
        totalCtrl.text = total > 0 ? total.toStringAsFixed(2) : '';
      }
      _recalcTotal();
    }

    qtyCtrl.addListener(recalcItem);
    unitCtrl.addListener(recalcItem);
    totalCtrl.addListener(_recalcTotal);

    setState(() {
      _items.add({
        'description': TextEditingController(),
        'quantity': qtyCtrl,
        'unit_price': unitCtrl,
        'total_price': totalCtrl,
      });
    });
  }

  void _recalcTotal() {
    double sum = 0;
    for (final item in _items) {
      sum += double.tryParse(item['total_price']!.text) ?? 0;
    }
    setState(() => _totalAmount = sum);
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
      _recalcTotal();
    });
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    setState(() {
      _issuedAt = date;
      _issuedTime = time;
    });
  }

  String? _formatIssuedAt() {
    if (_issuedAt == null) return null;
    final date = _issuedAt!;
    final time = _issuedTime ?? const TimeOfDay(hour: 0, minute: 0);
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issuedAt == null) {
      setState(() => _errorMessage = 'Prosím vyplňte dátum a čas vyhotovenia');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final items = _items.map((item) => {
      'description': item['description']!.text,
      'quantity': double.tryParse(item['quantity']!.text) ?? 1,
      'unit_price': double.tryParse(item['unit_price']!.text) ?? 0,
      'total_price': double.tryParse(item['total_price']!.text) ?? 0,
    }).toList();

    final body = {
      'receipt': {
        'merchant_name': _merchantNameController.text,
        'merchant_address': _merchantAddressController.text.isEmpty ? null : _merchantAddressController.text,
        'ico': _icoController.text.isEmpty ? null : _icoController.text,
        'dic': _dicController.text.isEmpty ? null : _dicController.text,
        'ic_dph': _icDphController.text.isEmpty ? null : _icDphController.text,
        'cash_register_code': _cashRegisterCodeController.text.isEmpty ? null : _cashRegisterCodeController.text,
        'receipt_number': _receiptNumberController.text.isEmpty ? null : _receiptNumberController.text,
        'issued_at': _formatIssuedAt(),
        'total_amount': _totalAmount,
        'receipt_items_attributes': items,
      }
    };

    final result = await AuthService().createReceipt(body);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bloček úspešne pridaný!')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result['error'] ?? 'Chyba pri ukladaní');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nový bloček')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
              ),

            // ── Obchodník ────────────────────────────────────────
            const Text('Obchodník', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _merchantNameController,
              decoration: const InputDecoration(labelText: 'Názov obchodníka *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _merchantAddressController,
              decoration: const InputDecoration(labelText: 'Adresa', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _icoController, decoration: const InputDecoration(labelText: 'IČO', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _dicController, decoration: const InputDecoration(labelText: 'DIČ', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _icDphController,
              decoration: const InputDecoration(labelText: 'IČ DPH', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: TextFormField(controller: _cashRegisterCodeController, decoration: const InputDecoration(labelText: 'Kód pokladnice', border: OutlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(controller: _receiptNumberController, decoration: const InputDecoration(labelText: 'Poradové číslo', border: OutlineInputBorder()))),
              ],
            ),
            const SizedBox(height: 24),

            // ── Dátum a čas ──────────────────────────────────────
            const Text('Dátum a čas vyhotovenia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _issuedAt == null
                    ? 'Vybrať dátum a čas *'
                    : '${_issuedAt!.day}.${_issuedAt!.month}.${_issuedAt!.year}  ${_issuedTime?.format(context) ?? ''}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _pickDateTime,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 24),

            // ── Položky ──────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Položky', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Pridať položku'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            ..._items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Položka ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(index),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: item['description'],
                        decoration: const InputDecoration(labelText: 'Popis *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item['quantity'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Množstvo *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Povinné' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item['unit_price'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Jedn. cena (€) *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Povinné' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item['total_price'],
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Celkom (€)', border: OutlineInputBorder()),
                              readOnly: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            // ── Celková suma (automatická) ────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.indigo.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.indigo.shade200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Celková suma', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text(
                    '${_totalAmount.toStringAsFixed(2)} €',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.indigo),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Uložiť bloček', style: TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}