import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import 'claim_detail_screen.dart';

class ClaimListScreen extends StatefulWidget {
  const ClaimListScreen({super.key});

  @override
  State<ClaimListScreen> createState() => _ClaimListScreenState();
}

class _ClaimListScreenState extends State<ClaimListScreen> {
  List _claims = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadClaims();
  }

  Future<void> _loadClaims() async {
    try {
      final data = await ApiService.get('claims');
      setState(() {
        _claims = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return Colors.green;
      case 'Rejected':
        return Colors.red;
      case 'Submitted':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claims',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF0077B6),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadClaims,
              child: _claims.isEmpty
                  ? const Center(child: Text('No claims generated yet'))
                  : ListView.builder(
                      itemCount: _claims.length,
                      itemBuilder: (context, index) {
                        final claim = _claims[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 4),
                          child: ListTile(
                            leading: const CircleAvatar(
                              backgroundColor: Color(0xFF0077B6),
                              child: Icon(Icons.receipt_long,
                                  color: Colors.white, size: 18),
                            ),
                            title: Text(
                                claim['patient']['full_name'] ?? 'Unknown'),
                            subtitle: Text(
                                '${claim['claim_number']}\nAmount: \$${claim['amount_claimed']}'),
                            isThreeLine: true,
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _statusColor(claim['status'])
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                claim['status'],
                                style: TextStyle(
                                    color: _statusColor(claim['status']),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold),
                              ),
                            ),
                            onTap: () async {
                              await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => ClaimDetailScreen(
                                          claimId: claim['id'])));
                              _loadClaims();
                            },
                          ),
                        );
                      },
                    ),
            ),
    );
  }
}