import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class CompanyPickerWidget extends StatefulWidget {
  final String label;
  final Map<String, dynamic>? selectedCompany;
  final Function(Map<String, dynamic>?) onChanged;

  const CompanyPickerWidget({
    super.key,
    required this.label,
    required this.selectedCompany,
    required this.onChanged,
  });

  @override
  State<CompanyPickerWidget> createState() => _CompanyPickerWidgetState();
}

class _CompanyPickerWidgetState extends State<CompanyPickerWidget> {
  final _authService = AuthService();
  List<dynamic> _companies = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCompanies();
  }

  Future<void> _loadCompanies() async {
    final companies = await _authService.getCompanies();
    setState(() {
      _companies = companies;
      _isLoading = false;
    });
  }

  void _showPicker() {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          height: 500,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vybrať ${widget.label}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showCompanyForm(null);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Nová firma'),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              if (_isLoading)
                const Expanded(child: Center(child: CircularProgressIndicator()))
              else if (_companies.isEmpty)
                const Expanded(
                  child: Center(
                    child: Text('Žiadne firmy', style: TextStyle(color: Colors.grey)),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _companies.length,
                    itemBuilder: (_, i) {
                      final c = _companies[i];
                      final isSelected = widget.selectedCompany?['id'] == c['id'];
                      return ListTile(
                        leading: Icon(
                          c['entity_type'] == 'person' ? Icons.person : Icons.business,
                        ),
                        title: Text(c['company_name'] ?? ''),
                        subtitle: Text(c['ico'] != null ? 'IČO: ${c['ico']}' : ''),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: Colors.indigo)
                            : const Icon(Icons.chevron_right),
                        onTap: () {
                          widget.onChanged(c);
                          Navigator.pop(context);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCompanyForm(Map<String, dynamic>? existing) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: SizedBox(
          width: 400,
          child: _CompanyFormDialog(
            existing: existing,
            onSaved: (company) async {
              await _loadCompanies();
              widget.onChanged(company);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selected = widget.selectedCompany;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        InkWell(
          onTap: _showPicker,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade400),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  selected == null
                      ? Icons.business
                      : selected['entity_type'] == 'person'
                          ? Icons.person
                          : Icons.business,
                  color: Colors.grey,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: selected == null
                      ? Text(
                          'Vybrať ${widget.label.toLowerCase()}...',
                          style: const TextStyle(color: Colors.grey),
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected['company_name'] ?? '',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            if (selected['street'] != null)
                              Text(
                                '${selected['street']}, ${selected['zip'] ?? ''} ${selected['country'] ?? ''}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                            if (selected['ico'] != null)
                              Text(
                                'IČO: ${selected['ico']}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
                          ],
                        ),
                ),
                if (selected != null) ...[
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.grey),
                    onPressed: () => _showCompanyForm(selected),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    onPressed: () => widget.onChanged(null),
                  ),
                ] else
                  const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompanyFormDialog extends StatefulWidget {
  final Map<String, dynamic>? existing;
  final Function(Map<String, dynamic>) onSaved;

  const _CompanyFormDialog({this.existing, required this.onSaved});

  @override
  State<_CompanyFormDialog> createState() => _CompanyFormDialogState();
}

class _CompanyFormDialogState extends State<_CompanyFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  late final TextEditingController _nameController;
  late final TextEditingController _firstNameController;
  late final TextEditingController _lastNameController;
  late final TextEditingController _streetController;
  late final TextEditingController _cityController;
  late final TextEditingController _zipController;
  late final TextEditingController _countryController;
  late final TextEditingController _icoController;
  late final TextEditingController _dicController;
  late final TextEditingController _icDphController;
  bool _isCompany = true;

  bool _isLoading = false;
  String? _errorMessage;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _isCompany = e?['entity_type'] != 'person';
    _nameController = TextEditingController(text: e?['company_name'] ?? '');
    _firstNameController = TextEditingController(text: e?['first_name'] ?? '');
    _lastNameController = TextEditingController(text: e?['last_name'] ?? '');
    _streetController = TextEditingController(text: e?['street'] ?? '');
    _cityController = TextEditingController(text: e?['city'] ?? '');
    _zipController = TextEditingController(text: e?['zip'] ?? '');
    _countryController = TextEditingController(text: e?['country'] ?? '');
    _icoController = TextEditingController(text: e?['ico'] ?? '');
    _dicController = TextEditingController(text: e?['dic'] ?? '');
    _icDphController = TextEditingController(text: e?['ic_dph'] ?? '');
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final body = {
      'company': {
        'entity_type': _isCompany ? 'company' : 'person',
        'company_name': _isCompany
            ? _nameController.text
            : '${_firstNameController.text} ${_lastNameController.text}',
        'first_name': _isCompany ? null : _firstNameController.text,
        'last_name': _isCompany ? null : _lastNameController.text,
        'street': _streetController.text,
        'city': _cityController.text,
        'zip': _zipController.text,
        'country': _countryController.text,
        'ico': _icoController.text,
        'dic': _dicController.text,
        'ic_dph': _icDphController.text,
      }
    };

    final result = _isEdit
        ? await _authService.updateCompany(widget.existing!['id'], body)
        : await _authService.createCompany(body);

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved(result['company']);
    } else {
      setState(() => _errorMessage = result['error']);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isEdit ? 'Upraviť' : 'Nová firma/osoba',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompany = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: _isCompany ? Colors.indigo : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.business, size: 16, color: _isCompany ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Firma',
                              style: TextStyle(
                                color: _isCompany ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _isCompany = false),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: !_isCompany ? Colors.indigo : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person, size: 16, color: !_isCompany ? Colors.white : Colors.grey),
                            const SizedBox(width: 6),
                            Text(
                              'Osoba',
                              style: TextStyle(
                                color: !_isCompany ? Colors.white : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(_errorMessage!, style: TextStyle(color: Colors.red.shade700)),
                ),
                const SizedBox(height: 12),
              ],
              if (_isCompany)
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Názov firmy *', border: OutlineInputBorder()),
                  validator: (v) => _isCompany && (v == null || v.isEmpty) ? 'Povinné pole' : null,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _firstNameController,
                        decoration: const InputDecoration(labelText: 'Meno *', border: OutlineInputBorder()),
                        validator: (v) => !_isCompany && (v == null || v.isEmpty) ? 'Povinné' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lastNameController,
                        decoration: const InputDecoration(labelText: 'Priezvisko *', border: OutlineInputBorder()),
                        validator: (v) => !_isCompany && (v == null || v.isEmpty) ? 'Povinné' : null,
                      ),
                    ),
                  ],
                ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _streetController,
                decoration: const InputDecoration(labelText: 'Ulica', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'Mesto', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _zipController,
                      decoration: const InputDecoration(labelText: 'PSČ', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _countryController,
                      decoration: const InputDecoration(labelText: 'Krajina', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _icoController,
                      decoration: const InputDecoration(labelText: 'IČO', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _dicController,
                      decoration: const InputDecoration(labelText: 'DIČ', border: OutlineInputBorder()),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _icDphController,
                decoration: const InputDecoration(labelText: 'IČ DPH', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(_isEdit ? 'Uložiť zmeny' : 'Vytvoriť', style: const TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}