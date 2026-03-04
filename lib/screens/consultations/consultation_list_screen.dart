import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_consultation_screen.dart';
import 'consultation_detail_screen.dart';

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key});

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  List _consultations = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadConsultations();
  }

  Future<void> _loadConsultations() async {
    try {
      final data = await ApiService.get('consultations');
      setState(() {
        _consultations = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Consultations',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0077B6),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddConsultationScreen()));
          _loadConsultations();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadConsultations,
              child: _consultations.isEmpty
                  ? const Center(child: Text('No consultations recorded yet'))
                  : ListView.builder(
                      itemCount: _consultations.length,
                      itemBuilder: (context, index) {
                        final c = _consultations[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0077B6),
                              child: Icon(Icons.medical_services,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text(c['patient']['full_name'] ?? 'Unknown'),
                            subtitle: Text(
                                '${c['diagnosis']}\nFee: \$${c['consultation_fee']}'),
                            isThreeLine: true,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          ConsultationDetailScreen(
                                              consultationId: c['id'])));
                              _loadConsultations();
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}