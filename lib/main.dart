import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';
import 'screens/patients/patient_list_screen.dart';
import 'screens/appointments/appointment_list_screen.dart';
import 'screens/consultations/consultation_list_screen.dart';
import 'screens/claims/claim_list_screen.dart';

void main() {
  runApp(const CareclinicApp());
}

class CareclinicApp extends StatelessWidget {
  const CareclinicApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CareClinic',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0077B6)),
        useMaterial3: true,
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const PatientListScreen(),
    const AppointmentListScreen(),
    const ConsultationListScreen(),
    const ClaimListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF0077B6),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Patients'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Appointments'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Consultations'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Claims'),
        ],
      ),
    );
  }
}