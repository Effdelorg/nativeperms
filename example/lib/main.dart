import 'package:flutter/material.dart';
import 'package:nativeprems/nativeprems.dart';

void main() => runApp(const _App());

class _App extends StatelessWidget {
  const _App();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'nativeprems demo',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const _Home(),
    );
  }
}

class _Home extends StatefulWidget {
  const _Home();

  @override
  State<_Home> createState() => _HomeState();
}

class _HomeState extends State<_Home> {
  final Map<Permission, PermissionStatus?> _statuses =
      <Permission, PermissionStatus?>{
    for (final Permission p in Permission.values) p: null,
  };
  final Map<Permission, ServiceStatus?> _services =
      <Permission, ServiceStatus?>{};

  Future<void> _refresh(Permission p) async {
    final PermissionStatus s = await p.status;
    ServiceStatus? svc;
    if (p is PermissionWithService) {
      svc = await p.serviceStatus;
    }
    if (!mounted) return;
    setState(() {
      _statuses[p] = s;
      if (svc != null) _services[p] = svc;
    });
  }

  Future<void> _request(Permission p) async {
    final PermissionStatus s = await p.request();
    if (!mounted) return;
    setState(() => _statuses[p] = s);
  }

  Future<void> _refreshAll() async {
    for (final Permission p in Permission.values) {
      await _refresh(p);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshAll());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('nativeprems demo'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Open app settings',
            onPressed: () async {
              final ScaffoldMessengerState messenger =
                  ScaffoldMessenger.of(context);
              final bool ok = await openAppSettings();
              messenger.showSnackBar(
                SnackBar(content: Text('openAppSettings() => $ok')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh all',
            onPressed: _refreshAll,
          ),
        ],
      ),
      body: ListView.separated(
        itemCount: Permission.values.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (BuildContext context, int i) {
          final Permission p = Permission.values[i];
          final PermissionStatus? status = _statuses[p];
          final ServiceStatus? svc = _services[p];
          return ListTile(
            title: Text(p.toString()),
            subtitle: Text(<String>[
              'status: ${status ?? "—"}',
              if (p is PermissionWithService) 'service: ${svc ?? "—"}',
            ].join('   ')),
            trailing: Wrap(
              spacing: 4,
              children: <Widget>[
                IconButton(
                  icon: const Icon(Icons.refresh, size: 20),
                  tooltip: 'Re-check',
                  onPressed: () => _refresh(p),
                ),
                FilledButton.tonal(
                  onPressed: () => _request(p),
                  child: const Text('Request'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
