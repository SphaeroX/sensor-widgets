import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sensor_widgets/domain/models/influx_connection.dart';
import 'package:sensor_widgets/presentation/controllers/connections_controller.dart';
import 'package:sensor_widgets/l10n/generated/app_localizations.dart';

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
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? l10n.connectionTestSuccess
                  : l10n.connectionTestNoResponse,
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).connectionTestFailed('$e'),
            ),
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
            content: Text(
              AppLocalizations.of(context).connectionSaveFailed('$e'),
            ),
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
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? l10n.connectionEditTitle : l10n.connectionNewTitle,
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _handleSave,
            child: Text(l10n.commonSave),
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
              decoration: InputDecoration(
                labelText: l10n.connectionNameLabel,
                hintText: l10n.connectionNameHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.connectionNameRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _urlController,
              decoration: InputDecoration(
                labelText: l10n.connectionUrlLabel,
                hintText: 'https://influx.example.com:8086',
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.url,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.connectionUrlRequired;
                }
                final uri = Uri.tryParse(v.trim());
                if (uri == null ||
                    (!uri.isScheme('http') && !uri.isScheme('https'))) {
                  return l10n.connectionUrlScheme;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _databaseController,
              decoration: InputDecoration(
                labelText: l10n.connectionDatabaseLabel,
                hintText: l10n.connectionDatabaseHint,
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return l10n.connectionDatabaseRequired;
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _orgController,
              decoration: InputDecoration(
                labelText: l10n.connectionOrgLabel,
                hintText: l10n.connectionOrgHint,
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _tokenController,
              obscureText: _obscureToken,
              decoration: InputDecoration(
                labelText: l10n.connectionTokenLabel,
                hintText: isEditing
                    ? l10n.connectionTokenKeepHint
                    : l10n.connectionTokenRequiredHint,
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
                  return l10n.connectionTokenRequired;
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
              label: Text(l10n.connectionTestButton),
            ),
          ],
        ),
      ),
    );
  }
}
