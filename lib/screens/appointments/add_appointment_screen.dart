import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class AddAppointmentScreen extends StatefulWidget {
  final Map<String, dynamic>? appointment;

  const AddAppointmentScreen({super.key, this.appointment});

  @override
  State<AddAppointmentScreen> createState() => _AddAppointmentScreenState();
}

class _AddAppointmentScreenState extends State<AddAppointmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _patient = TextEditingController();
  final _reason = TextEditingController();
  final _date = TextEditingController();
  final _time = TextEditingController();
  List _patients = [];
  int? _selectedPatientId;
  bool _saving = false;

  bool get _isEdit => widget.appointment != null;

  DateTime? _parseDate(String value) {
    try {
      return DateTime.parse(value);
    } catch (_) {
      return null;
    }
  }

  TimeOfDay? _parseTime(String value) {
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  void _prefillFromAppointment() {
    final appointment = widget.appointment;
    if (appointment == null) return;

    _selectedPatientId = appointment['patient_id'];
    _patient.text = appointment['patient']?['full_name'] ?? '';
    _date.text = appointment['date'] ?? '';
    _time.text = appointment['time'] ?? '';
    _reason.text = appointment['reason'] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _prefillFromAppointment();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    final data = await ApiService.get('patients');
    setState(() {
      _patients = data;
      if (_selectedPatientId != null) {
        final selected = _patients.cast<Map>().where(
            (p) => p['id'] == _selectedPatientId);
        if (selected.isNotEmpty) {
          _patient.text = selected.first['full_name'] ?? '';
        }
      }
    });
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
  }

  Future<void> _pickDate() async {
    final parsedDate = _parseDate(_date.text);
    final picked = await showDatePicker(
      context: context,
      initialDate: parsedDate ?? DateTime.now(),
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      _date.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _pickTime() async {
    final parsedTime = _parseTime(_time.text);
    final picked = await showTimePicker(
      context: context,
      initialTime: parsedTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      _time.text =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}:00';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final payload = {
      'patient_id': _selectedPatientId,
      'date': _date.text,
      'time': _time.text,
      'reason': _reason.text,
      'status': widget.appointment?['status'] ?? 'Scheduled',
    };

    final result = _isEdit
        ? await ApiService.put('appointments/${widget.appointment!['id']}', payload)
        : await ApiService.post('appointments', payload);

    if (result['message'] != null && result['message'].contains('already booked')) {
      setState(() => _saving = false);
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 48),
            title: const Text('Time Slot Unavailable',
                textAlign: TextAlign.center),
            content: const Text(
              'This time slot is already booked.\nPlease choose a different date or time.',
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK, Change Time',
                    style: TextStyle(color: Color(0xFF0077B6))),
              ),
            ],
          ),
        );
      }
    } else if (result['id'] != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEdit
              ? 'Appointment updated successfully!'
              : 'Appointment booked successfully!'),
          backgroundColor: Colors.green,
        ));
        Navigator.pop(context);
      }
    } else {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEdit
                ? 'Error updating appointment'
                : 'Error booking appointment'),
          ));
    }
  }

  @override
  void dispose() {
    _patient.dispose();
    _reason.dispose();
    _date.dispose();
    _time.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Appointment' : 'New Appointment',
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
              TextFormField(
                controller: _patient,
                readOnly: true,
                onTap: _pickPatient,
                decoration: InputDecoration(
                  labelText: 'Select Patient',
                  suffixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (_) => _selectedPatientId == null
                    ? 'Please select a patient'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _date,
                readOnly: true,
                onTap: _pickDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                  suffixIcon: const Icon(Icons.calendar_today),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _time,
                readOnly: true,
                onTap: _pickTime,
                decoration: InputDecoration(
                  labelText: 'Time',
                  suffixIcon: const Icon(Icons.access_time),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please select a time' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _reason,
                decoration: InputDecoration(
                  labelText: 'Reason for Visit',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                validator: (v) =>
                    v == null || v.isEmpty ? 'Please enter a reason' : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0077B6)),
                  child: _saving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(_isEdit ? 'Save Changes' : 'Book Appointment',
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