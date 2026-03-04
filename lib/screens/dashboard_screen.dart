import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'appointments/add_appointment_screen.dart';
import 'consultations/add_consultation_screen.dart';
import 'dashboard_charts_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _patientsSeen = 0;
  List _upcomingAppointments = [];
  bool _loading = true;

  Color _statusColor(String status) {
    switch (status) {
      case 'Completed':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      case 'No Show':
        return Colors.orange;
      default:
        return const Color(0xFF0077B6);
    }
  }

  Widget _legendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final data = await ApiService.get('dashboard');
      setState(() {
        _patientsSeen = data['patients_seen_today'];
        _upcomingAppointments = data['upcoming_appointments'];
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  DateTime _appointmentDateTime(Map apt) {
    final datePart = (apt['date'] ?? '').toString();
    final timePart = (apt['time'] ?? '').toString();
    final dateTimeString = '${datePart}T$timePart';
    return DateTime.tryParse(dateTimeString) ?? DateTime.now();
  }

  bool _isDueScheduled(Map apt) {
    if (apt['status'] != 'Scheduled') return false;
    return !_appointmentDateTime(apt).isAfter(DateTime.now());
  }

  Future<void> _endAppointment(Map apt) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddConsultationScreen(
          appointment: Map<String, dynamic>.from(apt),
        ),
      ),
    );
    _loadDashboard();
  }

  Future<void> _markNoShow(Map apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark No Show'),
        content: Text(
            'Mark appointment for ${apt['patient']['full_name'] ?? 'this patient'} as no show?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Mark No Show'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.put('appointments/${apt['id']}', {'status': 'No Show'});
    _loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 380;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isCompactWidth ? 'Dashboard' : 'CareClinic Dashboard',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.white),
            tooltip: 'Charts & Stats',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const DashboardChartsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Stats Card
                    Card(
                      elevation: 4,
                      color: const Color(0xFF0077B6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Row(
                          children: [
                            const Icon(Icons.people, color: Colors.white, size: 48),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Patients Seen Today',
                                    style: TextStyle(
                                        color: Colors.white70, fontSize: 14)),
                                Text('$_patientsSeen',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 48,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardChartsScreen(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.bar_chart,
                            color: Color(0xFF0077B6)),
                        label: const Text('View Dashboard Charts & Stats',
                            style: TextStyle(color: Color(0xFF0077B6))),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text('Upcoming Appointments',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: [
                          _legendItem('Scheduled', _statusColor('Scheduled')),
                          _legendItem('Completed', _statusColor('Completed')),
                          _legendItem('Cancelled', _statusColor('Cancelled')),
                          _legendItem('No Show', _statusColor('No Show')),
                        ],
                      ),
                    ),
                    _upcomingAppointments.isEmpty
                        ? const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: Text('No upcoming appointments'),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _upcomingAppointments.length,
                            itemBuilder: (context, index) {
                              final apt = _upcomingAppointments[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: const CircleAvatar(
                                    backgroundColor: Color(0xFF0077B6),
                                    child: Icon(Icons.calendar_today,
                                        color: Colors.white, size: 18),
                                  ),
                                  title: Text(
                                      apt['patient']['full_name'] ?? 'Unknown'),
                                  subtitle: Text(
                                      '${apt['date']} at ${apt['time']}\n${apt['reason']}'),
                                  trailing: Wrap(
                                    spacing: 6,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    children: [
                                      if (_isDueScheduled(apt)) ...[
                                        IconButton(
                                          icon: const Icon(Icons.check_circle,
                                              color: Colors.green),
                                          tooltip: 'End Appointment',
                                          onPressed: () => _endAppointment(apt),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.person_off,
                                              color: Colors.orange),
                                          tooltip: 'Record No Show',
                                          onPressed: () => _markNoShow(apt),
                                        ),
                                      ] else
                                        const Icon(Icons.edit,
                                            color: Color(0xFF0077B6), size: 18),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: _statusColor(apt['status'])
                                              .withValues(alpha: 0.1),
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          apt['status'],
                                          style: TextStyle(
                                            color: _statusColor(apt['status']),
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  onTap: () async {
                                    if (_isDueScheduled(apt)) {
                                      await _endAppointment(apt);
                                    } else {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddAppointmentScreen(
                                            appointment:
                                                Map<String, dynamic>.from(apt),
                                          ),
                                        ),
                                      );
                                      _loadDashboard();
                                    }
                                  },
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ),
    );
  }
}