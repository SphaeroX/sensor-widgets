import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/controllers/connections_controller.dart';

/// Screen to create or edit an InfluxDB connection.
class ConnectionFormScreen extends ConsumerStatefulWidget {
  final InfluxConnection? connection;

  const ConnectionFormScreen({super.key, this.connection});

  @override
  ConsumerState<ConnectionFormScreen> createState() =>
      _ConnectionFormScreenState();
}

class _ConnectionFormScreenState extends ConsumerState<ConnectionFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _urlController;
  late final TextEditingController _databaseController;
  late final TextEditingController _orgController;
  late final TextEditingController _tokenController;

  bool _obscureToken = true;
  bool _isTesting = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final c = widget.connection;
    _nameController = TextEditingController(text: c?.name ?? '');
    _urlController = TextEditingController(text: c?.url ?? 'https://');
    _databaseController = TextEditingController(text: c?.database ?? '');
    _orgController = TextEditingController(text: c?.organization ?? '');
    _tokenController = TextEditingController();

    if (c != null) {
      ref.read(connectionsControllerProvider.notifier).getToken(c.id).then((t) {
        if (mounted && t != null) {
          _tokenController.text = t;
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _urlController.dispose();
    _databaseController.dispose();
    _orgController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  InfluxConnection _buildConnection() {
    final id =
        widget.connection?.id ??
        'conn_${DateTime.now().millisecondsSinceEpoch}';
    return InfluxConnection(
      id: id,
      name: _nameController.text.trim(),
      url: _urlController.text.trim(),
      database: _databaseController.text.trim(),
      organization: _orgController.text.trim().isEmpty
          ? null
          : _orgController.text.trim(),
    );
  }

  Future<void> _handleTest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isTesting = true);
    final conn = _buildConnection();
    final token = _tokenController.text.trim();

    try {
      final success = await ref
          .read(connectionsControllerProvider.notifier)
          .testConnection(connection: conn, token: token);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Connection successful!'
                  : 'Connection failed: no response',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTesting = false);
      }
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final conn = _buildConnection();
    final token = _tokenController.text.trim();

    try {
      await ref
          .read(connectionsControllerProvider.notifier)
          .saveConnection(conn, token: token.isNotEmpty ? token : null);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save connection: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.connection != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Connection' : 'New Connection'),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Connection Name',
                hintText: 'e.g. Home Server',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter a connection name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: const InputDecoration(
                labelText: 'Host URL',
                hintText: 'https://influx.example.com:8086',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter host URL';
                }
                final uri = Uri.tryParse(v.trim());
                if (uri == null ||
                    (!uri.isScheme('http') && !uri.isScheme('https'))) {
                  return 'URL must start with http:// or https://';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _databaseController,
              decoration: const InputDecoration(
                labelText: 'Database / Bucket',
                hintText: 'e.g. sensors',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Please enter database name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orgController,
              decoration: const InputDecoration(
                labelText: 'Organization (optional)',
                hintText: 'e.g. home-org',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: 'API Token',
                hintText: isEditing
                    ? '(Keep current token)'
                    : 'Required for auth',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureToken ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() => _obscureToken = !_obscureToken);
                  },
                ),
              ),
              validator: (v) {
                if (!isEditing && (v == null || v.trim().isEmpty)) {
                  return 'Please enter API token';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: _isTesting ? null : _handleTest,
              icon: _isTesting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.network_check),
              label: const Text('Test Connection'),
            ),
          ],
        ),
      ),
    );
  }
}
