import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdviserPage extends StatefulWidget {
  const AdviserPage({super.key});

  @override
  State<AdviserPage> createState() => _AdviserPageState();
}

class _AdviserPageState extends State<AdviserPage> {
  final ApiService api = ApiService();
  late Future<List<Project>> _projectsFuture;
  final AuthService _auth = AuthService();
  String? _role;
  String? _username;
  bool _authorized = false;
  bool _loadingAccess = true;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  Future<void> _checkAccess() async {
    final token = await _auth.getToken();
    if (token == null) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }
    final r = await _auth.getRole();
    final u = await _auth.getUsername();
    setState(() {
      _role = r;
      _username = u;
      _authorized = (r == 'adviser' || r == 'admin');
      _projectsFuture = _authorized ? api.fetchProjects() : Future.value([]);
      _loadingAccess = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Adviser Dashboard'),
        actions: [
          if (_username != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(child: Text('$_username — ${_role ?? ''}')),
            ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.logout();
              if (!mounted) return;
              Navigator.pushReplacementNamed(context, '/');
            },
          ),
        ],
      ),
      body: _loadingAccess
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _projectsFuture = api.fetchProjects();
                });
                await _projectsFuture;
              },
              child: _authorized
                  ? FutureBuilder<List<Project>>(
                      future: _projectsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        final projects = snapshot.data ?? [];
                        return ListView(
                          children: projects.map((p) {
                            return ListTile(
                              title: Text(p.title),
                              subtitle: Text('${p.student} — ${p.domain}'),
                            );
                          }).toList(),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('Unauthorized — adviser access required'),
                          const SizedBox(height: 8),
                          ElevatedButton(
                            onPressed: () => Navigator.pushReplacementNamed(
                              context,
                              '/login',
                            ),
                            child: const Text('Login'),
                          ),
                        ],
                      ),
                    ),
            ),
    );
  }
}
