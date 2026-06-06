import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class StudentPage extends StatefulWidget {
  const StudentPage({super.key});

  @override
  State<StudentPage> createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final ApiService api = ApiService();
  late Future<List<Project>> _projectsFuture;
  late Future<List<dynamic>> _schedulesFuture;
  final AuthService _auth = AuthService();
  String? _role;
  String? _username;
  bool _authorized = false;
  bool _loadingAccess = true;
  final TextEditingController _title1Ctl = TextEditingController();
  final TextEditingController _title2Ctl = TextEditingController();
  final TextEditingController _title3Ctl = TextEditingController();
  bool _submitting = false;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkAccess();
  }

  @override
  void dispose() {
    _title1Ctl.dispose();
    _title2Ctl.dispose();
    _title3Ctl.dispose();
    super.dispose();
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
      _authorized = (r == 'student' || r == 'admin');
      _projectsFuture = _authorized ? api.fetchProjects() : Future.value([]);
      _schedulesFuture = _authorized ? api.fetchSchedules() : Future.value([]);
      _loadingAccess = false;
    });
  }

  Future<void> _submitTitles() async {
    final t1 = _title1Ctl.text.trim();
    final t2 = _title2Ctl.text.trim();
    final t3 = _title3Ctl.text.trim();
    if (t1.isEmpty || t2.isEmpty || t3.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter all three titles')),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final futures = <Future>[];
      for (final t in [t1, t2, t3]) {
        final body = {
          'title': t,
          'description': '',
          'domain': '',
          'adviser': '',
          'status': 'Proposed',
        };
        futures.add(api.createProject(body));
      }
      await Future.wait(futures);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Submitted 3 titles')));
      _title1Ctl.clear();
      _title2Ctl.clear();
      _title3Ctl.clear();
      setState(() {
        _projectsFuture = api.fetchProjects();
      });
      await _projectsFuture;
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _refreshAll() async {
    setState(() {
      _projectsFuture = api.fetchProjects();
      _schedulesFuture = api.fetchSchedules();
    });
    await Future.wait([_projectsFuture, _schedulesFuture]);
  }

  Widget _buildSidebar(bool isInDrawer) {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.primaryContainer,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Student',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (_username != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Text(
                    '$_username — ${_role ?? ''}',
                    style: TextStyle(
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimary.withOpacity(0.9),
                    ),
                  ),
                ),
            ],
          ),
        ),
        ListTile(
          leading: Icon(
            Icons.dashboard,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Dashboard'),
          selected: _selectedIndex == 0,
          onTap: () {
            setState(() => _selectedIndex = 0);
            if (isInDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(
            Icons.upload_file,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Submit Titles'),
          selected: _selectedIndex == 1,
          onTap: () {
            setState(() => _selectedIndex = 1);
            if (isInDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(
            Icons.view_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('View Titles'),
          selected: _selectedIndex == 2,
          onTap: () {
            setState(() => _selectedIndex = 2);
            if (isInDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: const Icon(Icons.schedule),
          title: const Text('Schedules'),
          selected: _selectedIndex == 3,
          onTap: () {
            setState(() => _selectedIndex = 3);
            if (isInDrawer) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _submitCard() {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.hardEdge,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Submit Three Title Proposals',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title1Ctl,
                decoration: const InputDecoration(labelText: 'Title 1'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title2Ctl,
                decoration: const InputDecoration(labelText: 'Title 2'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _title3Ctl,
                decoration: const InputDecoration(labelText: 'Title 3'),
              ),
              const SizedBox(height: 12),
              _submitting
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitTitles,
                        child: const Text('Submit Titles'),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContentArea() {
    if (!_authorized) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Unauthorized — student access required'),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () =>
                  Navigator.pushReplacementNamed(context, '/login'),
              child: const Text('Login'),
            ),
          ],
        ),
      );
    }

    switch (_selectedIndex) {
      case 0: // Dashboard
        return FutureBuilder<List<Project>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final projects = snapshot.data ?? [];
            final myProjects = projects
                .where((p) => p.student == _username)
                .toList();
            final total = projects.length;
            final mine = myProjects.length;
            return ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'Welcome, ${_username ?? ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Total proposals in system: $total'),
                          Text('Your submitted proposals: $mine'),
                          const SizedBox(height: 12),
                          const Text(
                            'Recent proposals',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                ...projects
                    .take(5)
                    .map(
                      (p) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 6.0,
                        ),
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.hardEdge,
                          child: ListTile(
                            title: Text(
                              p.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text('${p.adviser} — ${p.domain}'),
                          ),
                        ),
                      ),
                    ),
              ],
            );
          },
        );

      case 1: // Submit Titles
        return ListView(children: [_submitCard()]);

      case 2: // View Titles
        return FutureBuilder<List<Project>>(
          future: _projectsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final projects = snapshot.data ?? [];
            final myProjects = projects
                .where((p) => p.student == _username)
                .toList();
            if (myProjects.isEmpty) {
              return const Center(child: Text('No submitted titles yet'));
            }
            return ListView(
              children: myProjects
                  .map(
                    (p) => Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      child: Card(
                        child: ListTile(
                          title: Text(
                            p.title,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text('${p.adviser} — ${p.domain}'),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        );

      case 3: // Schedules
        return FutureBuilder<List<dynamic>>(
          future: _schedulesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final schedules = snapshot.data ?? [];
            if (schedules.isEmpty) {
              return const Center(child: Text('No schedules'));
            }

            final Map<String, List<dynamic>> byStudent = {};
            for (var s in schedules) {
              final project = (s is Map && s['Project'] is Map)
                  ? s['Project'] as Map<String, dynamic>
                  : null;
              final studentName =
                  (project != null &&
                      (project['student'] ?? '').toString().trim().isNotEmpty)
                  ? project['student'] as String
                  : 'Unknown';
              byStudent.putIfAbsent(studentName, () => []).add(s);
            }

            final entries = byStudent.entries.toList()
              ..sort(
                (a, b) => a.key.toLowerCase().compareTo(b.key.toLowerCase()),
              );

            return ListView(
              padding: const EdgeInsets.all(12.0),
              children: entries.map((e) {
                final studentName = e.key;
                final list = e.value;
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0),
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$studentName (${list.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    children: list.map<Widget>((s) {
                      final project = (s is Map && s['Project'] is Map)
                          ? s['Project'] as Map<String, dynamic>
                          : null;
                      final title = project != null
                          ? (project['title'] ?? '')
                          : (s['projectId']?.toString() ?? 'Project');
                      final scheduledAtStr =
                          s['scheduledAt'] ?? s['scheduled_at'] ?? '';
                      DateTime? dt;
                      try {
                        dt =
                            scheduledAtStr != null &&
                                scheduledAtStr.toString().isNotEmpty
                            ? DateTime.parse(
                                scheduledAtStr.toString(),
                              ).toLocal()
                            : null;
                      } catch (e) {
                        dt = null;
                      }
                      final location = s['location'] ?? '';
                      final notes = s['notes'] ?? '';
                      return ListTile(
                        title: Text(title.toString()),
                        subtitle: Text(
                          '${dt != null ? dt.toString() : 'No date'} — ${location ?? ''}\n${notes ?? ''}',
                        ),
                        isThreeLine: true,
                      );
                    }).toList(),
                  ),
                );
              }).toList(),
            );
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSidebar = width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
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
      drawer: showSidebar ? null : Drawer(child: _buildSidebar(true)),
      body: _loadingAccess
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _refreshAll,
              child: showSidebar
                  ? Row(
                      children: [
                        Container(
                          width: 260,
                          color: Theme.of(context).canvasColor,
                          child: _buildSidebar(false),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(child: _buildContentArea()),
                      ],
                    )
                  : _buildContentArea(),
            ),
    );
  }
}
