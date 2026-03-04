import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ArchivedPatientsScreen extends StatefulWidget {
  const ArchivedPatientsScreen({super.key});

  @override
  State<ArchivedPatientsScreen> createState() => _ArchivedPatientsScreenState();
}

class _ArchivedPatientsScreenState extends State<ArchivedPatientsScreen> {
  List _archivedPatients = [];
  bool _loading = true;

  String _formatArchivedAt(dynamic archivedAt) {
    if (archivedAt == null) return 'Unknown date';
    final value = archivedAt.toString();
    if (value.length < 10) return value;
    final datePart = value.substring(0, 10);
    final parts = datePart.split('-');
    if (parts.length != 3) return datePart;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }

  @override
  void initState() {
    super.initState();
    _loadArchivedPatients();
  }

  Future<void> _loadArchivedPatients() async {
    try {
      final data = await ApiService.get('patients/archived');
      setState(() {
        _archivedPatients = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _restorePatient(Map patient) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restore Patient'),
        content: Text(
            'Restore ${patient['full_name'] ?? 'this patient'} to active patients?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Restore'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.put('patients/${patient['id']}/restore', {});
    _loadArchivedPatients();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Archived Patients',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadArchivedPatients,
              child: _archivedPatients.isEmpty
                  ? const Center(child: Text('No archived patients'))
                  : ListView.builder(
                      itemCount: _archivedPatients.length,
                      itemBuilder: (context, index) {
                        final patient = _archivedPatients[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: const Color(0xFF0077B6),
                              child: Text(
                                patient['full_name'][0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(patient['full_name']),
                            subtitle: Text(
                              '${patient['phone_number'] ?? ''}\nArchived: ${_formatArchivedAt(patient['archived_at'])}',
                            ),
                            isThreeLine: true,
                            trailing: TextButton.icon(
                              onPressed: () => _restorePatient(patient),
                              icon: const Icon(Icons.restore),
                              label: const Text('Restore'),
                            ),
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}
