import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/auth_secret.dart';
import '../models/totp_generator.dart';

class SecretCard extends StatefulWidget {
  final AuthSecret secret;
  final VoidCallback onDelete;

  const SecretCard({super.key, required this.secret, required this.onDelete});

  @override
  State<SecretCard> createState() => _SecretCardState();
}

class _SecretCardState extends State<SecretCard> {
  String _currentCode = '';
  int _remainingSeconds = 0;

  @override
  void initState() {
    super.initState();
    _updateCode();
    _startTimer();
  }

  void _updateCode() {
    setState(() {
      _currentCode = TOTPGenerator.generateTOTP(
        widget.secret.secret,
        digits: widget.secret.digits,
        period: widget.secret.period,
      );
      _remainingSeconds = TOTPGenerator.getRemainingSeconds(
        period: widget.secret.period,
      );
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        _updateCode();
        _startTimer();
      }
    });
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _currentCode));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Code copied to clipboard')));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.secret.issuer,
                        style: Theme.of(context).textTheme.titleMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        widget.secret.name,
                        style: Theme.of(context).textTheme.bodyMedium,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete),
                  color: Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: _copyToClipboard,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _currentCode,
                      style: Theme.of(context).textTheme.headlineLarge
                          ?.copyWith(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                Column(
                  children: [
                    CircularProgressIndicator(
                      value: _remainingSeconds / widget.secret.period,
                      strokeWidth: 3,
                    ),
                    const SizedBox(height: 4),
                    Text('${_remainingSeconds}s'),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
