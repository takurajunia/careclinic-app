import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class DashboardChartsScreen extends StatefulWidget {
  const DashboardChartsScreen({super.key});

  @override
  State<DashboardChartsScreen> createState() => _DashboardChartsScreenState();
}

class _DashboardChartsScreenState extends State<DashboardChartsScreen> {
  bool _loading = true;

  int _patientsSeenToday = 0;
  int _totalAppointments = 0;
  int _totalConsultations = 0;
  int _totalClaims = 0;

  int _scheduled = 0;
  int _completed = 0;
  int _cancelled = 0;
  int _noShow = 0;

  List<int> _last7DaysAppointments = List.filled(7, 0);

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _loading = true);
    try {
      final dashboard = await ApiService.get('dashboard');
      final appointments = await ApiService.get('appointments');
      final consultations = await ApiService.get('consultations');
      final claims = await ApiService.get('claims');

      final aptList = (appointments as List).cast<Map>();
      final consultationList = (consultations as List).cast<Map>();
      final claimList = (claims as List).cast<Map>();

      int scheduled = 0;
      int completed = 0;
      int cancelled = 0;
      int noShow = 0;

      for (final apt in aptList) {
        final status = (apt['status'] ?? '').toString();
        if (status == 'Completed') {
          completed++;
        } else if (status == 'Cancelled') {
          cancelled++;
        } else if (status == 'No Show') {
          noShow++;
        } else {
          scheduled++;
        }
      }

      setState(() {
        _patientsSeenToday = dashboard['patients_seen_today'] ?? 0;
        _totalAppointments = aptList.length;
        _totalConsultations = consultationList.length;
        _totalClaims = claimList.length;
        _scheduled = scheduled;
        _completed = completed;
        _cancelled = cancelled;
        _noShow = noShow;
        _last7DaysAppointments = _buildLast7DaysCounts(aptList);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  List<int> _buildLast7DaysCounts(List<Map> appointments) {
    final now = DateTime.now();
    final days = List.generate(
      7,
      (index) => DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: 6 - index)),
    );

    final counts = List.filled(7, 0);
    for (final apt in appointments) {
      final dateRaw = (apt['date'] ?? '').toString();
      final parsed = DateTime.tryParse(dateRaw);
      if (parsed == null) continue;
      final normalized = DateTime(parsed.year, parsed.month, parsed.day);
      final dayIndex = days.indexWhere((d) => d == normalized);
      if (dayIndex != -1) {
        counts[dayIndex]++;
      }
    }
    return counts;
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

  Widget _statCard(String label, int value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF0077B6)),
            const SizedBox(height: 8),
            Text('$value',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxCount = _last7DaysAppointments.isEmpty
        ? 1
        : math.max(1, _last7DaysAppointments.reduce(math.max));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Charts & Stats',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    childAspectRatio: 1.6,
                    children: [
                      _statCard('Patients Seen Today', _patientsSeenToday,
                          Icons.people),
                      _statCard('Total Appointments', _totalAppointments,
                          Icons.calendar_today),
                      _statCard('Consultations', _totalConsultations,
                          Icons.medical_services),
                      _statCard('Claims', _totalClaims, Icons.receipt_long),
                    ],
                  ),
                  const SizedBox(height: 18),
                  const Text('Appointment Status Distribution',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 34,
                        sections: [
                          PieChartSectionData(
                            color: _statusColor('Scheduled'),
                            value: _scheduled.toDouble(),
                            title: '$_scheduled',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            color: _statusColor('Completed'),
                            value: _completed.toDouble(),
                            title: '$_completed',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            color: _statusColor('Cancelled'),
                            value: _cancelled.toDouble(),
                            title: '$_cancelled',
                            radius: 50,
                          ),
                          PieChartSectionData(
                            color: _statusColor('No Show'),
                            value: _noShow.toDouble(),
                            title: '$_noShow',
                            radius: 50,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _legend('Scheduled', _statusColor('Scheduled')),
                      _legend('Completed', _statusColor('Completed')),
                      _legend('Cancelled', _statusColor('Cancelled')),
                      _legend('No Show', _statusColor('No Show')),
                    ],
                  ),
                  const SizedBox(height: 22),
                  const Text('Appointments (Last 7 Days)',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 220,
                    child: BarChart(
                      BarChartData(
                        maxY: maxCount.toDouble() + 1,
                        gridData: const FlGridData(show: true),
                        titlesData: FlTitlesData(
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: true),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const labels = [
                                  'D-6',
                                  'D-5',
                                  'D-4',
                                  'D-3',
                                  'D-2',
                                  'D-1',
                                  'Today'
                                ];
                                final index = value.toInt();
                                if (index < 0 || index >= labels.length) {
                                  return const SizedBox.shrink();
                                }
                                return Text(labels[index],
                                    style: const TextStyle(fontSize: 11));
                              },
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        barGroups: List.generate(
                          7,
                          (index) => BarChartGroupData(
                            x: index,
                            barRods: [
                              BarChartRodData(
                                toY: _last7DaysAppointments[index].toDouble(),
                                color: const Color(0xFF0077B6),
                                width: 16,
                                borderRadius: BorderRadius.circular(4),
                              )
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _legend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label),
      ],
    );
  }
}
