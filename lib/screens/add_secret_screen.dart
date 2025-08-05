import 'package:flutter/material.dart';
import '../models/auth_secret.dart';
import '../services/storage_service.dart';

class AddSecretScreen extends StatefulWidget {
  const AddSecretScreen({super.key});

  @override
  State<AddSecretScreen> createState() => _AddSecretScreenState();
}

class _AddSecretScreenState extends State<AddSecretScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _issuerController = TextEditingController();
  final _secretController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _issuerController.dispose();
    _secretController.dispose();
    super.dispose();
  }

  String? _validateSecret(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a secret';
    }

    // Remove spaces and convert to uppercase
    final cleanSecret = value.replaceAll(' ', '').toUpperCase();

    // Check if it's valid base32
    final base32Regex = RegExp(r'^[A-Z2-7]+$');
    if (!base32Regex.hasMatch(cleanSecret)) {
      return 'Invalid secret format';
    }

    return null;
  }

  Future<void> _saveSecret() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final secret = AuthSecret(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameController.text.trim(),
      issuer: _issuerController.text.trim(),
      secret: _secretController.text.replaceAll(' ', '').toUpperCase(),
    );

    try {
      await StorageService.saveSecret(secret);
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving secret: $e')));
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Secret'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _issuerController,
                decoration: const InputDecoration(
                  labelText: 'Issuer (e.g., Google, GitHub)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an issuer';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Account Name (e.g., john@example.com)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter an account name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _secretController,
                decoration: const InputDecoration(
                  labelText: 'Secret Key',
                  border: OutlineInputBorder(),
                  helperText: 'Enter the base32 secret key',
                ),
                validator: _validateSecret,
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveSecret,
                  child: _isLoading
                      ? const CircularProgressIndicator()
                      : const Text('Add Secret'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
