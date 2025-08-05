import 'package:flutter/material.dart';
import '../models/auth_secret.dart';
import '../services/storage_service.dart';
import '../widgets/secret_card.dart';
import 'add_secret_screen.dart';
import 'qr_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AuthSecret> _secrets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSecrets();
  }

  Future<void> _loadSecrets() async {
    setState(() => _isLoading = true);
    final secrets = await StorageService.getSecrets();
    setState(() {
      _secrets = secrets;
      _isLoading = false;
    });
  }

  Future<void> _deleteSecret(String id) async {
    await StorageService.deleteSecret(id);
    _loadSecrets();
  }

  void _showDeleteDialog(AuthSecret secret) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Secret'),
        content: Text('Are you sure you want to delete ${secret.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteSecret(secret.id);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showAddOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.qr_code_scanner),
            title: const Text('Scan QR Code'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const QRScannerScreen(),
                ),
              );
              if (result == true) {
                _loadSecrets();
              }
            },
          ),
          ListTile(
            leading: const Icon(Icons.edit),
            title: const Text('Enter Manually'),
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const AddSecretScreen(),
                ),
              );
              if (result == true) {
                _loadSecrets();
              }
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Authenticator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _secrets.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.security, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No secrets added yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the + button to add your first secret',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _secrets.length,
              itemBuilder: (context, index) {
                final secret = _secrets[index];
                return SecretCard(
                  secret: secret,
                  onDelete: () => _showDeleteDialog(secret),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddOptions(),
        tooltip: 'Add Secret',
        child: const Icon(Icons.add),
      ),
    );
  }
}
