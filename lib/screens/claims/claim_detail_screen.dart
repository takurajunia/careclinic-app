import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class ClaimDetailScreen extends StatefulWidget {
  final int claimId;
  const ClaimDetailScreen({super.key, required this.claimId});

  @override
  State<ClaimDetailScreen> createState() => _ClaimDetailScreenState();
}

class _ClaimDetailScreenState extends State<ClaimDetailScreen> {
  Map? _claim;
  bool _loading = true;
  String _selectedStatus = 'Pending';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await ApiService.get('claims/${widget.claimId}');
    setState(() {
      _claim = data;
      _selectedStatus = data['status'];
      _loading = false;
    });
  }

  Future<void> _updateStatus() async {
    await ApiService.put('claims/${widget.claimId}', {'status': _selectedStatus});
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Claim status updated!'),
            backgroundColor: Colors.green));
    _load();
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
          isCompactWidth ? 'Claim' : 'Claim Details',
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
                  // Claim Form Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0077B6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        const Text('NATIONAL MEDICAL AID CLAIM FORM',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14)),
                        const SizedBox(height: 4),
                        Text('Claim #: ${_claim!['claim_number']}',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 12)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _section('Patient Information', [
                    _infoRow('Name', _claim!['patient']['full_name']),
                    _infoRow('Medical Aid', _claim!['medical_aid_provider']),
                    _infoRow('Aid Number', _claim!['medical_aid_number']),
                  ]),
                  _section('Claim Details', [
                    _infoRow('Date of Service', _claim!['date_of_service']),
                    _infoRow('Amount Claimed', '\$${_claim!['amount_claimed']}'),
                    _infoRow('Diagnosis',
                        _claim!['consultation']['diagnosis']),
                    _infoRow('Treatment',
                        _claim!['consultation']['prescribed_treatment']),
                  ]),
                  _section('Update Status', [
                    DropdownButtonFormField<String>(
                      initialValue: _selectedStatus,
                      decoration: InputDecoration(
                        labelText: 'Claim Status',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      items: ['Pending', 'Submitted', 'Approved', 'Rejected']
                          .map((s) =>
                              DropdownMenuItem(value: s, child: Text(s)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedStatus = v!),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _updateStatus,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0077B6)),
                        child: const Text('Update Status',
                            style: TextStyle(color: Colors.white)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }
}