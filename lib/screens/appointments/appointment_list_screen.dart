import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'add_appointment_screen.dart';
import '../consultations/add_consultation_screen.dart';

class AppointmentListScreen extends StatefulWidget {
  const AppointmentListScreen({super.key});

  @override
  State<AppointmentListScreen> createState() => _AppointmentListScreenState();
}

class _AppointmentListScreenState extends State<AppointmentListScreen> {
  List _appointments = [];
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();
  String _viewMode = 'daily';

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  DateTime _startOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  DateTime _endOfWeek(DateTime date) {
    return _startOfWeek(date).add(const Duration(days: 6));
  }

  @override
  void initState() {
    super.initState();
    _loadAppointments();
  }

  Future<void> _loadAppointments() async {
    setState(() => _loading = true);
    try {
      final endpoint = _viewMode == 'daily'
          ? 'appointments?date=${_formatDate(_selectedDate)}'
          : 'appointments?start_date=${_formatDate(_startOfWeek(_selectedDate))}&end_date=${_formatDate(_endOfWeek(_selectedDate))}';
      final data = await ApiService.get(endpoint);
      setState(() {
        _appointments = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _loadAppointments();
    }
  }

  String _displayDateLabel() {
    if (_viewMode == 'daily') {
      return _formatDate(_selectedDate);
    }

    final start = _startOfWeek(_selectedDate);
    final end = _endOfWeek(_selectedDate);
    return '${_formatDate(start)} to ${_formatDate(end)}';
  }

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
    _loadAppointments();
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
    _loadAppointments();
  }

  Future<void> _cancelAppointment(Map apt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cancel Appointment'),
        content: Text(
            'Are you sure you want to cancel this appointment for ${apt['patient']['full_name'] ?? 'this patient'}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    await ApiService.put('appointments/${apt['id']}', {'status': 'Cancelled'});
    _loadAppointments();
  }

  @override
  Widget build(BuildContext context) {
    final isCompactWidth = MediaQuery.of(context).size.width < 380;
    final viewLabel = _viewMode == 'daily' ? 'Daily' : 'Weekly';
    final appBarTitle = isCompactWidth
        ? 'Appointments • $viewLabel'
      : 'Appointments • $viewLabel View';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF0077B6),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0077B6),
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const AddAppointmentScreen()));
          _loadAppointments();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Daily'),
                    selected: _viewMode == 'daily',
                    onSelected: (selected) {
                      if (!selected || _viewMode == 'daily') return;
                      setState(() => _viewMode = 'daily');
                      _loadAppointments();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('Weekly'),
                    selected: _viewMode == 'weekly',
                    onSelected: (selected) {
                      if (!selected || _viewMode == 'weekly') return;
                      setState(() => _viewMode = 'weekly');
                      _loadAppointments();
                    },
                  ),
                ),
              ],
            ),
          ),
          // Date selector bar
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              color: const Color(0xFF0077B6).withValues(alpha: 0.1),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today,
                      size: 16, color: Color(0xFF0077B6)),
                  const SizedBox(width: 8),
                  Text(
                    _displayDateLabel(),
                    style: const TextStyle(
                        color: Color(0xFF0077B6), fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  const Text('Tap to change',
                      style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
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
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: _loadAppointments,
                    child: _appointments.isEmpty
                      ? Center(
                        child: Text(_viewMode == 'daily'
                          ? 'No appointments for this date'
                          : 'No appointments for this week'))
                        : ListView.builder(
                            itemCount: _appointments.length,
                            itemBuilder: (context, index) {
                              final apt = _appointments[index];
                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        _statusColor(apt['status']),
                                    child: Text(
                                      apt['time'].substring(0, 5),
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 11),
                                    ),
                                  ),
                                  title: Text(
                                      apt['patient']['full_name'] ?? 'Unknown'),
                                  subtitle: Text(apt['reason']),
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
                                      ] else ...[
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Color(0xFF0077B6)),
                                          tooltip: 'Edit Appointment',
                                          onPressed: apt['status'] == 'Scheduled'
                                              ? () async {
                                                  await Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                      builder: (_) =>
                                                          AddAppointmentScreen(
                                                        appointment: Map<String,
                                                            dynamic>.from(apt),
                                                      ),
                                                    ),
                                                  );
                                                  _loadAppointments();
                                                }
                                              : null,
                                        ),
                                        apt['status'] == 'Scheduled'
                                          ? IconButton(
                                              icon: const Icon(Icons.cancel,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                _cancelAppointment(apt),
                                            )
                                          : Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4),
                                              decoration: BoxDecoration(
                                                color:
                                                    _statusColor(apt['status'])
                                                        .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                              ),
                                              child: Text(apt['status'],
                                                  style: TextStyle(
                                                      color: _statusColor(
                                                          apt['status']),
                                                      fontSize: 12)),
                                            ),
                                      ],
                                    ],
                                  ),
                                  onTap: () async {
                                    if (_isDueScheduled(apt)) {
                                      await _endAppointment(apt);
                                    } else if (apt['status'] == 'Scheduled') {
                                      await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddAppointmentScreen(
                                            appointment:
                                                Map<String, dynamic>.from(apt),
                                          ),
                                        ),
                                      );
                                      _loadAppointments();
                                    }
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