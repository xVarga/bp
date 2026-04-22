import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/company_picker_widget.dart';

class AddInvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? invoice;

  const AddInvoiceScreen({super.key, this.invoice});

  @override
  State<AddInvoiceScreen> createState() => _AddInvoiceScreenState();
}

class _AddInvoiceScreenState extends State<AddInvoiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late final TextEditingController _invoiceNumberController;
  late final TextEditingController _totalVatController;
  late final TextEditingController _totalWithoutVatController;
  late final TextEditingController _totalWithVatController;
  DateTime? _issueDate;
  DateTime? _deliveryDate;

  Map<String, dynamic>? _supplier;
  Map<String, dynamic>? _customer;

  final List<Map<String, TextEditingController>> _items = [];

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEdit => widget.invoice != null;

  @override
  void initState() {
    super.initState();
    final inv = widget.invoice;

    _invoiceNumberController = TextEditingController(text: inv?['invoice_number'] ?? '');
    _totalVatController = TextEditingController(text: inv?['total_vat_amount']?.toString() ?? '');
    _totalWithoutVatController = TextEditingController(text: inv?['total_without_vat']?.toString() ?? '');
    _totalWithVatController = TextEditingController(text: inv?['total_with_vat']?.toString() ?? '');

    if (inv != null) {
      _supplier = inv['supplier'];
      _customer = inv['customer'];
      _issueDate = inv['issue_date'] != null ? DateTime.parse(inv['issue_date']) : null;
      _deliveryDate = inv['delivery_date'] != null ? DateTime.parse(inv['delivery_date']) : null;
      final existingItems = (inv['items'] as List?) ?? [];
      for (final item in existingItems) {
        _items.add(_buildItemControllers(
          description: item['description'] ?? '',
          quantity: item['quantity']?.toString() ?? '',
          unitPrice: item['unit_price']?.toString() ?? '',
          taxRate: item['tax_rate']?.toString() ?? '',
          totalWithoutVat: item['total_without_vat']?.toString() ?? '',
          vatAmount: item['vat_amount']?.toString() ?? '',
          totalWithVat: item['total_with_vat']?.toString() ?? '',
        ));
      }
    }

    if (_items.isEmpty) _addItem();
  }

  Map<String, TextEditingController> _buildItemControllers({
    String description = '',
    String quantity = '',
    String unitPrice = '',
    String taxRate = '',
    String totalWithoutVat = '',
    String vatAmount = '',
    String totalWithVat = '',
  }) {
    final controllers = {
      'description': TextEditingController(text: description),
      'quantity': TextEditingController(text: quantity),
      'unit_price': TextEditingController(text: unitPrice),
      'tax_rate': TextEditingController(text: taxRate),
      'total_without_vat': TextEditingController(text: totalWithoutVat),
      'vat_amount': TextEditingController(text: vatAmount),
      'total_with_vat': TextEditingController(text: totalWithVat),
    };

    void recalculate() {
      final qty = double.tryParse(controllers['quantity']!.text) ?? 0;
      final price = double.tryParse(controllers['unit_price']!.text) ?? 0;
      final rate = double.tryParse(controllers['tax_rate']!.text) ?? 0;

      final totalWithout = qty * price;
      final vat = totalWithout * rate / 100;
      final totalWith = totalWithout + vat;

      controllers['total_without_vat']!.text = totalWithout.toStringAsFixed(2);
      controllers['vat_amount']!.text = vat.toStringAsFixed(2);
      controllers['total_with_vat']!.text = totalWith.toStringAsFixed(2);

      _recalculateTotals();
    }

    controllers['quantity']!.addListener(recalculate);
    controllers['unit_price']!.addListener(recalculate);
    controllers['tax_rate']!.addListener(recalculate);

    return controllers;
  }

  void _recalculateTotals() {
    double totalVat = 0;
    double totalWithout = 0;
    double totalWith = 0;
    for (final item in _items) {
      totalVat += double.tryParse(item['vat_amount']!.text) ?? 0;
      totalWithout += double.tryParse(item['total_without_vat']!.text) ?? 0;
      totalWith += double.tryParse(item['total_with_vat']!.text) ?? 0;
    }
    if (mounted) {
      setState(() {
        _totalVatController.text = totalVat.toStringAsFixed(2);
        _totalWithoutVatController.text = totalWithout.toStringAsFixed(2);
        _totalWithVatController.text = totalWith.toStringAsFixed(2);
      });
    }
  }

  void _addItem() {
    setState(() => _items.add(_buildItemControllers()));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
    _recalculateTotals();
  }

  Future<void> _pickDate(bool isIssueDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isIssueDate
          ? (_issueDate ?? DateTime.now())
          : (_deliveryDate ?? _issueDate ?? DateTime.now()),
      firstDate: isIssueDate ? DateTime(2000) : (_issueDate ?? DateTime(2000)),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isIssueDate) {
          _issueDate = picked;
          _deliveryDate = picked;
        } else {
          _deliveryDate = picked;
        }
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_issueDate == null || _deliveryDate == null) {
      setState(() => _errorMessage = 'Prosím vyplňte oba dátumy');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final items = _items.map((item) => {
      'description': item['description']!.text,
      'quantity': double.tryParse(item['quantity']!.text) ?? 0,
      'unit_price': double.tryParse(item['unit_price']!.text) ?? 0,
      'tax_rate': double.tryParse(item['tax_rate']!.text) ?? 0,
      'vat_amount': double.tryParse(item['vat_amount']!.text) ?? 0,
      'total_without_vat': double.tryParse(item['total_without_vat']!.text) ?? 0,
      'total_with_vat': double.tryParse(item['total_with_vat']!.text) ?? 0,
    }).toList();

    final body = {
      'invoice': {
        'invoice_number': _invoiceNumberController.text,
        'issue_date': _issueDate!.toIso8601String().split('T')[0],
        'delivery_date': _deliveryDate!.toIso8601String().split('T')[0],
        'total_vat_amount': double.tryParse(_totalVatController.text) ?? 0,
        'total_without_vat': double.tryParse(_totalWithoutVatController.text) ?? 0,
        'total_with_vat': double.tryParse(_totalWithVatController.text) ?? 0,
        'supplier_id': _supplier?['id'],
        'customer_id': _customer?['id'],
        'invoice_items_attributes': items,
      }
    };

    final result = _isEdit
        ? await _authService.updateInvoice(widget.invoice!['id'], body)
        : await _authService.createInvoice(body);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isEdit ? 'Faktúra úspešne upravená!' : 'Faktúra úspešne pridaná!')),
      );
      Navigator.pop(context, true);
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Upraviť faktúru' : 'Nová faktúra')),
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

            CompanyPickerWidget(
              label: 'Dodávateľ',
              selectedCompany: _supplier,
              onChanged: (c) => setState(() => _supplier = c),
            ),
            const SizedBox(height: 16),
            CompanyPickerWidget(
              label: 'Odberateľ',
              selectedCompany: _customer,
              onChanged: (c) => setState(() => _customer = c),
            ),
            const SizedBox(height: 24),

            const Text('Základné informácie', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            TextFormField(
              controller: _invoiceNumberController,
              decoration: const InputDecoration(labelText: 'Číslo faktúry *', border: OutlineInputBorder()),
              validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(_issueDate == null
                  ? 'Dátum vyhotovenia *'
                  : 'Dátum vyhotovenia: ${_issueDate!.toLocal().toString().split(' ')[0]}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _pickDate(true),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(color: Colors.grey.shade400),
              ),
            ),
            const SizedBox(height: 12),

            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                _issueDate == null
                    ? 'Dátum dodania (najprv vyberte vyhotovenie)'
                    : _deliveryDate == null
                        ? 'Dátum dodania *'
                        : 'Dátum dodania: ${_deliveryDate!.toLocal().toString().split(' ')[0]}',
                style: TextStyle(
                  color: _issueDate == null ? Colors.grey.shade400 : null,
                ),
              ),
              trailing: Icon(
                Icons.calendar_today,
                color: _issueDate == null ? Colors.grey.shade400 : null,
              ),
              onTap: _issueDate == null ? null : () => _pickDate(false),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
                side: BorderSide(
                  color: _issueDate == null ? Colors.grey.shade300 : Colors.grey.shade400,
                ),
              ),
            ),
            const SizedBox(height: 24),

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
              final idx = entry.key;
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
                          Text('Položka ${idx + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          if (_items.length > 1)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeItem(idx),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: item['description'],
                        decoration: const InputDecoration(labelText: 'Popis tovaru/služby *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Povinné pole' : null,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item['quantity'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Množstvo *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Povinné' : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item['unit_price'],
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Jedn. cena bez DPH (€) *', border: OutlineInputBorder()),
                              validator: (v) => v == null || v.isEmpty ? 'Povinné' : null,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: item['tax_rate'],
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'Sadzba DPH (%) *', border: OutlineInputBorder()),
                        validator: (v) => v == null || v.isEmpty ? 'Povinné' : null,
                      ),
                      const Divider(height: 20),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: item['total_without_vat'],
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Celkom bez DPH (€)',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: item['vat_amount'],
                              readOnly: true,
                              decoration: const InputDecoration(
                                labelText: 'Výška DPH (€)',
                                border: OutlineInputBorder(),
                                filled: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: item['total_with_vat'],
                        readOnly: true,
                        decoration: const InputDecoration(
                          labelText: 'Celkom s DPH (€)',
                          border: OutlineInputBorder(),
                          filled: true,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),

            const SizedBox(height: 16),

            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Sumarizácia', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Celkom bez DPH:', style: TextStyle(color: Colors.grey)),
                        Text('${_totalWithoutVatController.text} €', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('DPH:', style: TextStyle(color: Colors.grey)),
                        Text('${_totalVatController.text} €', style: const TextStyle(fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Celkom s DPH:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(
                          '${_totalWithVatController.text} €',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : Text(_isEdit ? 'Uložiť zmeny' : 'Uložiť faktúru', style: const TextStyle(fontSize: 16)),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}