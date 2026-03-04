import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_patient_screen.dart';

class PatientDetailScreen extends StatefulWidget {
  final int patientId;
  const PatientDetailScreen({super.key, required this.patientId});

  @override
  State<PatientDetailScreen> createState() => _PatientDetailScreenState();
}

class _PatientDetailScreenState extends State<PatientDetailScreen> {
  Map? _patient;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatient();
  }

  Future<void> _loadPatient() async {
    final data = await ApiService.get('patients/${widget.patientId}');
    setState(() {
      _patient = data;
      _loading = false;
    });
  }

  Future<void> _deleteOrArchive() async {
    final action = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Patient Action'),
        content: const Text('Do you want to archive or permanently delete this patient?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, 'archive'),
            child: const Text('Archive', style: TextStyle(color: Color(0xFF0077B6))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (action == 'delete') {
      await ApiService.delete('patients/${widget.patientId}');
      if (!mounted) return;
      Navigator.pop(context);
      return;
    }

    if (action == 'archive') {
      await ApiService.put('patients/${widget.patientId}/archive', {});
      if (!mounted) return;
      Navigator.pop(context);
    }
  }

  Widget _infoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompactWidth ? 'Patient' : 'Patient Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => AddPatientScreen(patient: _patient)));
              _loadPatient();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _deleteOrArchive,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: const Color(0xFF0077B6),
                    child: Text(
                      _patient!['full_name'][0].toUpperCase(),
                      style: const TextStyle(fontSize: 36, color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(_patient!['full_name'],
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          _infoRow('Date of Birth', _patient!['date_of_birth']),
                          _infoRow('Gender', _patient!['gender']),
                          _infoRow('National ID', _patient!['national_id']),
                          _infoRow('Phone', _patient!['phone_number']),
                          _infoRow('Address', _patient!['address']),
                          _infoRow('Medical Aid', _patient!['medical_aid_provider']),
                          _infoRow('Aid Number', _patient!['medical_aid_number']),
                          _infoRow('Allergies', _patient!['allergies']),
                          _infoRow('Chronic Conditions', _patient!['chronic_conditions']),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}