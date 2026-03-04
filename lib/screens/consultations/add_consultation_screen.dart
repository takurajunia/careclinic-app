import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddConsultationScreen extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const AddConsultationScreen({super.key, this.appointment});

  @override
  State<AddConsultationScreen> createState() => _AddConsultationScreenState();
}

class _AddConsultationScreenState extends State<AddConsultationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _bloodPressure = TextEditingController();
  final _temperature = TextEditingController();
  final _weight = TextEditingController();
  final _pulse = TextEditingController();
  final _diagnosis = TextEditingController();
  final _treatment = TextEditingController();
  final _notes = TextEditingController();
  final _fee = TextEditingController();

  List _patients = [];
  List _appointments = [];
  int? _selectedPatientId;
  int? _selectedAppointmentId;
  bool _saving = false;

  bool get _isFromAppointment => widget.appointment != null;

  void _prefillFromAppointment() {
    final appointment = widget.appointment;
    if (appointment == null) return;

    _selectedPatientId = appointment['patient_id'];
    _selectedAppointmentId = appointment['id'];
    _patient.text = appointment['patient']?['full_name'] ?? '';
    _appointments = [appointment];
  }

  @override
  void initState() {
    super.initState();
    _prefillFromAppointment();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final data = await ApiService.get('patients');
    setState(() => _patients = data);
  }

  Future<void> _pickPatient() async {
    String query = '';

    final selectedId = await showDialog<int>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) {
          final filtered = _patients.cast<Map>().where((p) {
            final name = (p['full_name'] ?? '').toString().toLowerCase();
            return name.contains(query.toLowerCase());
          }).toList();

          return AlertDialog(
            title: const Text('Select Patient'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Search patient',
                      prefixIcon: Icon(Icons.search),
                    ),
                    onChanged: (value) =>
                        setDialogState(() => query = value),
                  ),
                  const SizedBox(height: 12),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? const Center(child: Text('No matching patients'))
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (context, index) {
                              final patient = filtered[index];
                              return ListTile(
                                title: Text(patient['full_name'] ?? 'Unknown'),
                                subtitle: Text(patient['phone_number'] ?? ''),
                                onTap: () =>
                                    Navigator.pop(context, patient['id']),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          );
        },
      ),
    );

    if (selectedId == null) return;

    final selected = _patients.cast<Map>().firstWhere(
      (p) => p['id'] == selectedId,
      orElse: () => {},
    );

    setState(() {
      _selectedPatientId = selectedId;
      _patient.text = selected['full_name'] ?? '';
    });

    _loadAppointments(selectedId);
  }

  Future<void> _loadAppointments(int patientId) async {
    final data = await ApiService.get('appointments');
    setState(() {
      _appointments = (data as List)
          .where((a) =>
              a['patient_id'] == patientId && a['status'] == 'Scheduled')
          .toList();
      _selectedAppointmentId = null;
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    try {
      await ApiService.post('consultations', {
        'patient_id': _selectedPatientId,
        'appointment_id': _selectedAppointmentId,
        'blood_pressure': _bloodPressure.text,
        'temperature': _temperature.text,
        'weight': _weight.text,
        'pulse': _pulse.text,
        'diagnosis': _diagnosis.text,
        'prescribed_treatment': _treatment.text,
        'notes': _notes.text,
        'consultation_fee': _fee.text,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Consultation saved & claim generated!'),
            backgroundColor: Colors.green));
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error saving consultation')));
    }
  }

  @override
  void dispose() {
    _patient.dispose();
    _bloodPressure.dispose();
    _temperature.dispose();
    _weight.dispose();
    _pulse.dispose();
    _diagnosis.dispose();
    _treatment.dispose();
    _notes.dispose();
    _fee.dispose();
    super.dispose();
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
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Required' : null
            : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Consultation',
            style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Patient & Appointment',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _patient,
                readOnly: true,
                onTap: _isFromAppointment ? null : _pickPatient,
                decoration: InputDecoration(
                  labelText: 'Select Patient',
                  suffixIcon: Icon(
                      _isFromAppointment ? Icons.lock : Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (_) => _selectedPatientId == null ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: _selectedAppointmentId,
                decoration: InputDecoration(
                  labelText: 'Select Appointment',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                items: _appointments
                    .map((a) => DropdownMenuItem<int>(
                        value: a['id'],
                        child: Text('${a['date']} at ${a['time'].substring(0, 5)}')))
                    .toList(),
                onChanged: _isFromAppointment
                  ? null
                  : (v) => setState(() => _selectedAppointmentId = v),
                validator: (v) => v == null ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text('Vital Signs',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _field('Blood Pressure (e.g. 120/80)', _bloodPressure),
              _field('Temperature (°C)', _temperature,
                  keyboardType: TextInputType.number),
              _field('Weight (kg)', _weight,
                  keyboardType: TextInputType.number),
              _field('Pulse (bpm)', _pulse,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 8),
              const Text('Consultation Notes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              _field('Diagnosis', _diagnosis, required: true),
              _field('Prescribed Treatment', _treatment, required: true),
              _field('Additional Notes', _notes),
              _field('Consultation Fee (USD)', _fee,
                  required: true, keyboardType: TextInputType.number),
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
                      : const Text('Save Consultation',
                          style:
                              TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}