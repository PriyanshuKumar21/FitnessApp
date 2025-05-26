import 'package:flutter/material.dart';
import '../services/database_helper.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_card.dart';

class DbDebugScreen extends StatefulWidget {
  const DbDebugScreen({super.key});

  @override
  State<DbDebugScreen> createState() => _DbDebugScreenState();
}

class _DbDebugScreenState extends State<DbDebugScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  String _status = '';

  Future<void> _deleteDatabase() async {
    setState(() {
      _status = 'Deleting database...';
    });

    try {
      await _dbHelper.deleteDatabase();
      setState(() {
        _status = 'Database deleted successfully. Please restart the app.';
      });
    } catch (e) {
      setState(() {
        _status = 'Error deleting database: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Database Debug'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryColor.withOpacity(0.2),
              Colors.black,
            ],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GlassContainer(
                  borderRadius: 16,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Text(
                        'Database Management',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Warning: These actions can cause data loss. Use only for troubleshooting.',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _deleteDatabase,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Delete Database'),
                      ),
                      const SizedBox(height: 24),
                      if (_status.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _status,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 