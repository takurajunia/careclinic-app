import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ConsultationDetailScreen extends StatefulWidget {
  final int consultationId;
  const ConsultationDetailScreen({super.key, required this.consultationId});

  @override
  State<ConsultationDetailScreen> createState() =>
      _ConsultationDetailScreenState();
}

class _ConsultationDetailScreenState extends State<ConsultationDetailScreen> {
  Map? _consultation;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.get('consultations/${widget.consultationId}');
    setState(() {
      _consultation = data;
      _loading = false;
    });
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
                      fontWeight: FontWeight.bold, color: Colors.grey))),
          Expanded(child: Text(value ?? 'N/A')),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFF0077B6))),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompactWidth ? 'Consultation' : 'Consultation Details',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _section('Patient', [
                    _infoRow('Name',
                        _consultation!['patient']['full_name']),
                  ]),
                  _section('Vital Signs', [
                    _infoRow('Blood Pressure',
                        _consultation!['blood_pressure']),
                    _infoRow('Temperature',
                        '${_consultation!['temperature'] ?? 'N/A'} °C'),
                    _infoRow(
                        'Weight', '${_consultation!['weight'] ?? 'N/A'} kg'),
                    _infoRow(
                        'Pulse', '${_consultation!['pulse'] ?? 'N/A'} bpm'),
                  ]),
                  _section('Diagnosis & Treatment', [
                    _infoRow('Diagnosis', _consultation!['diagnosis']),
                    _infoRow('Treatment',
                        _consultation!['prescribed_treatment']),
                    _infoRow('Notes', _consultation!['notes']),
                  ]),
                  _section('Billing', [
                    _infoRow('Consultation Fee',
                        '\$${_consultation!['consultation_fee']}'),
                  ]),
                ],
              ),
            ),
    );
  }
}