import 'package:flutter/material.dart';
import '../../services/telegram_service.dart';

class TelegramLinkingDialog extends StatefulWidget {
  final TelegramService telegramService;

  const TelegramLinkingDialog({super.key, required this.telegramService});

  @override
  _TelegramLinkingDialogState createState() => _TelegramLinkingDialogState();
}

class _TelegramLinkingDialogState extends State<TelegramLinkingDialog> {
  String _verificationCode = '';
  final _codeController = TextEditingController();
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _getVerificationCode();
  }

  Future<void> _getVerificationCode() async {
    try {
      final code = await widget.telegramService.getVerificationCode();
      setState(() {
        _verificationCode = code;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }

  Future<void> _linkAccount() async {
    if (_codeController.text.isEmpty) {
      setState(() => _errorMessage = 'Please enter your Telegram chat ID');
      return;
    }

    setState(() => _isLoading = true);

    try {
      await widget.telegramService.linkTelegramAccount(
        chatId: _codeController.text.trim(),
        verificationCode: _verificationCode,
      );

      Navigator.pop(context, true);
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.telegram, color: Colors.blue),
          SizedBox(width: 8),
          Text('Connect Telegram'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '📋 Step 1: Copy code',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(height: 12),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                border: Border.all(color: Colors.blue.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'Verification Code:',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8),
                  SelectableText(
                    _verificationCode.isEmpty
                        ? 'Generating...'
                        : _verificationCode,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                      color: Colors.blue.shade800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Text(
              '🤖 Step 2: Telegram',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '1. Search @rescuenet_bot\n2. Start bot\n3. Send code\n4. Return here',
                style: TextStyle(fontSize: 12),
              ),
            ),
            SizedBox(height: 16),
            Text(
              '✅ Step 3: Link',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            SizedBox(height: 8),
            TextField(
              controller: _codeController,
              decoration: InputDecoration(
                labelText: 'Chat ID',
                hintText: 'Paste chat ID here',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.key),
              ),
            ),
            if (_errorMessage.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 12),
                child: Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.red.shade700, fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _linkAccount,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
          child: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text('Link Account'),
        ),
      ],
    );
  }
}
