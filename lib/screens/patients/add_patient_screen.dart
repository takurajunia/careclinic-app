import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddPatientScreen extends StatefulWidget {
  final Map? patient;
  const AddPatientScreen({super.key, this.patient});

  @override
  State<AddPatientScreen> createState() => _AddPatientScreenState();
}

class _AddPatientScreenState extends State<AddPatientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _dob = TextEditingController();
  final _nationalId = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _medAidProvider = TextEditingController();
  final _medAidNumber = TextEditingController();
  final _allergies = TextEditingController();
  final _chronicConditions = TextEditingController();
  String _gender = 'Male';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.patient != null) {
      final p = widget.patient!;
      _fullName.text = p['full_name'] ?? '';
      _dob.text = p['date_of_birth'] ?? '';
      _nationalId.text = p['national_id'] ?? '';
      _phone.text = p['phone_number'] ?? '';
      _address.text = p['address'] ?? '';
      _medAidProvider.text = p['medical_aid_provider'] ?? '';
      _medAidNumber.text = p['medical_aid_number'] ?? '';
      _allergies.text = p['allergies'] ?? '';
      _chronicConditions.text = p['chronic_conditions'] ?? '';
      _gender = p['gender'] ?? 'Male';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'full_name': _fullName.text,
      'date_of_birth': _dob.text,
      'gender': _gender,
      'national_id': _nationalId.text,
      'phone_number': _phone.text,
      'address': _address.text,
      'medical_aid_provider': _medAidProvider.text,
      'medical_aid_number': _medAidNumber.text,
      'allergies': _allergies.text,
      'chronic_conditions': _chronicConditions.text,
    };

    try {
      if (widget.patient != null) {
        await ApiService.put('patients/${widget.patient!['id']}', data);
      } else {
        await ApiService.post('patients', data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving patient')));
    }
  }

  Widget _field(String label, TextEditingController controller,
      {bool required = false, TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.patient != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Patient' : 'New Patient',
            style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              _field('Full Name', _fullName, required: true),
              _field('Date of Birth (YYYY-MM-DD)', _dob, required: true),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: ['Male', 'Female', 'Other']
                    .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                    .toList(),
                onChanged: (v) => setState(() => _gender = v!),
              ),
              const SizedBox(height: 12),
              _field('National ID', _nationalId, required: true),
              _field('Phone Number', _phone,
                  required: true, keyboardType: TextInputType.phone),
              _field('Address', _address, required: true),
              _field('Medical Aid Provider', _medAidProvider),
              _field('Medical Aid Number', _medAidNumber),
              _field('Allergies', _allergies),
              _field('Chronic Conditions', _chronicConditions),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6)),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(isEdit ? 'Update Patient' : 'Register Patient',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}