import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_patient_screen.dart';
import 'archived_patients_screen.dart';
import 'patient_detail_screen.dart';

class PatientListScreen extends StatefulWidget {
  const PatientListScreen({super.key});

  @override
  State<PatientListScreen> createState() => _PatientListScreenState();
}

class _PatientListScreenState extends State<PatientListScreen> {
  List _patients = [];
  List _filtered = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPatients();
  }

  Future<void> _loadPatients() async {
    try {
      final data = await ApiService.get('patients');
      setState(() {
        _patients = data;
        _filtered = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  void _search(String query) {
    setState(() {
      _filtered = _patients.where((p) {
        return p['full_name'].toLowerCase().contains(query.toLowerCase()) ||
            p['phone_number'].contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patients',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive, color: Colors.white),
            tooltip: 'Archived Patients',
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const ArchivedPatientsScreen(),
                ),
              );
              _loadPatients();
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0077B6),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddPatientScreen()));
          _loadPatients();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _search,
                    decoration: InputDecoration(
                      hintText: 'Search by name or phone...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadPatients,
                    child: _filtered.isEmpty
                        ? const Center(child: Text('No patients found'))
                        : ListView.builder(
                            itemCount: _filtered.length,
                            itemBuilder: (context, index) {
                              final patient = _filtered[index];
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
                                      '${patient['gender']} • ${patient['phone_number']}'),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () async {
                                    await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (_) => PatientDetailScreen(
                                                patientId: patient['id'])));
                                    _loadPatients();
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
    );
  }
}