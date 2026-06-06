import 'package:flutter/material.dart';
import '../models/project.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  final ApiService api = ApiService();
  late Future<List<Project>> _projectsFuture;
  final AuthService _auth = AuthService();
  String? _role;
  String? _username;
  bool _authorized = false;
  bool _loadingAccess = true;
  bool _classifying = false;
  bool _creating = false;
  final bool _scheduling = false;
  late Future<List<dynamic>> _usersFuture;
  int _selectedIndex = 0;

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
      _authorized = (r == 'admin');
      _projectsFuture = _authorized ? api.fetchProjects() : Future.value([]);
      _usersFuture = _authorized ? api.fetchUsers() : Future.value([]);
      _loadingAccess = false;
    });
  }

  Future<void> _refresh() async {
    setState(() {
      _projectsFuture = api.fetchProjects();
      _usersFuture = api.fetchUsers();
    });
    await _projectsFuture;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _showAddDialog() {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();
    final studentCtl = TextEditingController();
    final adviserCtl = TextEditingController();
    final domainCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtl,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              TextField(
                controller: descCtl,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              TextField(
                controller: studentCtl,
                decoration: const InputDecoration(labelText: 'Student'),
              ),
              TextField(
                controller: adviserCtl,
                decoration: const InputDecoration(labelText: 'Adviser'),
              ),
              TextField(
                controller: domainCtl,
                decoration: const InputDecoration(labelText: 'Domain'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _classifying
                ? null
                : () async {
                    if (titleCtl.text.trim().isEmpty &&
                        descCtl.text.trim().isEmpty) {
                      return;
                    }
                    setState(() => _classifying = true);
                    try {
                      final suggested = await api.classifyProject({
                        'title': titleCtl.text,
                        'description': descCtl.text,
                      });
                      domainCtl.text = suggested;
                    } catch (e) {
                      // ignore
                    } finally {
                      setState(() => _classifying = false);
                    }
                  },
            child: _classifying
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Suggest Domain'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: _creating
                ? null
                : () async {
                    if (titleCtl.text.trim().isEmpty) return;
                    setState(() => _creating = true);
                    final body = {
                      'title': titleCtl.text,
                      'description': descCtl.text,
                      'student': studentCtl.text,
                      'adviser': adviserCtl.text,
                      'domain': domainCtl.text,
                      'status': 'Proposed',
                    };
                    try {
                      await api.createProject(body);
                      Navigator.pop(ctx);
                      await _refresh();
                    } catch (e) {
                      // ignore in simple prototype
                      Navigator.pop(ctx);
                    } finally {
                      setState(() => _creating = false);
                    }
                  },
            child: _creating
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _showUserDialog(dynamic u) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(u['username'] ?? 'User'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${u['id'] ?? ''}'),
            const SizedBox(height: 6),
            Text('Username: ${u['username'] ?? ''}'),
            const SizedBox(height: 6),
            Text('Role: ${u['role'] ?? ''}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(Project p) {
    final locationCtl = TextEditingController();
    final notesCtl = TextEditingController();
    DateTime? scheduledAt;
    showDialog(
      context: context,
      builder: (ctx) {
        bool isSaving = false;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Schedule: ${p.title}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          scheduledAt == null
                              ? 'No date/time selected'
                              : scheduledAt!.toLocal().toString(),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final date = await showDatePicker(
                            context: ctx,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (date == null) return;
                          final time = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time == null) return;
                          final dt = DateTime(
                            date.year,
                            date.month,
                            date.day,
                            time.hour,
                            time.minute,
                          );
                          setState(() => scheduledAt = dt);
                        },
                        child: const Text('Pick'),
                      ),
                    ],
                  ),
                  TextField(
                    controller: locationCtl,
                    decoration: const InputDecoration(labelText: 'Location'),
                  ),
                  TextField(
                    controller: notesCtl,
                    decoration: const InputDecoration(labelText: 'Notes'),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (scheduledAt == null || isSaving)
                      ? null
                      : () async {
                          setState(() => isSaving = true);
                          try {
                            final body = {
                              'projectId': p.id,
                              'scheduledAt': scheduledAt!
                                  .toUtc()
                                  .toIso8601String(),
                              'location': locationCtl.text,
                              'notes': notesCtl.text,
                            };
                            await api.createSchedule(body);
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Scheduled "${p.title}" on ${scheduledAt!.toLocal()} at ${locationCtl.text}',
                                ),
                              ),
                            );
                            await _refresh();
                          } catch (e) {
                            if (!mounted) return;
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Failed to save schedule: $e'),
                              ),
                            );
                          } finally {
                            // dialog closed at this point
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showScheduleForStudentDialog(
    String studentName,
    List<Project> projects,
  ) {
    showDialog(
      context: context,
      builder: (ctx) {
        Project? selected = projects.isNotEmpty ? projects[0] : null;
        return StatefulBuilder(
          builder: (ctx, setState) {
            return AlertDialog(
              title: Text('Schedule for $studentName'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (projects.isEmpty) const Text('No titles available'),
                  if (projects.isNotEmpty)
                    DropdownButton<Project>(
                      value: selected,
                      isExpanded: true,
                      items: projects
                          .map(
                            (p) => DropdownMenuItem<Project>(
                              value: p,
                              child: Text(p.title),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => selected = v),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: (selected == null)
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _showScheduleDialog(selected!);
                        },
                  child: const Text('Schedule'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final showSidebar = width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        flexibleSpace: Container(
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
        ),
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
              onRefresh: _refresh,
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
      floatingActionButton: _authorized
          ? FloatingActionButton(
              onPressed: _showAddDialog,
              backgroundColor: Theme.of(context).colorScheme.secondary,
              foregroundColor: Theme.of(context).colorScheme.onSecondary,
              child: const Icon(Icons.add),
            )
          : null,
    );
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
                'Admin',
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
          selected: _selectedIndex == 2,
          onTap: () {
            setState(() => _selectedIndex = 2);
            if (isInDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(
            Icons.people,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('Users'),
          selected: _selectedIndex == 0,
          onTap: () {
            setState(() {
              _selectedIndex = 0;
              _usersFuture = api.fetchUsers();
            });
            if (isInDrawer) Navigator.pop(context);
          },
        ),
        ListTile(
          leading: Icon(
            Icons.view_list,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: const Text('All Titles'),
          selected: _selectedIndex == 1,
          onTap: () {
            setState(() {
              _selectedIndex = 1;
              _projectsFuture = api.fetchProjects();
            });
            if (isInDrawer) Navigator.pop(context);
          },
        ),
      ],
    );
  }

  Widget _projectTile(Project p) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.work,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text(
          p.title,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text('${p.domain} • Adviser: ${p.adviser}'),
        trailing: ElevatedButton.icon(
          onPressed: () => _showScheduleDialog(p),
          icon: const Icon(Icons.schedule, size: 18),
          label: const Text('Schedule'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
            const Text('Unauthorized — admin access required'),
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
      case 0: // Users
        return FutureBuilder<List<dynamic>>(
          future: _usersFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            final users = snapshot.data ?? [];
            if (users.isEmpty) {
              return const Center(child: Text('No users found'));
            }
            return SingleChildScrollView(
              padding: const EdgeInsets.all(12.0),
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('ID')),
                  DataColumn(label: Text('Username')),
                  DataColumn(label: Text('Role')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: users
                    .map(
                      (u) => DataRow(
                        cells: [
                          DataCell(Text('${u['id'] ?? ''}')),
                          DataCell(Text(u['username'] ?? '')),
                          DataCell(Text(u['role'] ?? '')),
                          DataCell(
                            Row(
                              children: [
                                TextButton(
                                  onPressed: () => _showUserDialog(u),
                                  child: const Text('View'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                    .toList(),
              ),
            );
          },
        );

      case 1: // All Titles
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
            if (projects.isEmpty) {
              return const Center(child: Text('No projects found'));
            }

            final Map<String, List<Project>> byStudent = {};
            for (var p in projects) {
              final key = (p.student.trim().isEmpty) ? 'Unknown' : p.student;
              byStudent.putIfAbsent(key, () => []).add(p);
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
                  elevation: 4,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  clipBehavior: Clip.hardEdge,
                  child: ExpansionTile(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$studentName (${list.length})',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        TextButton(
                          onPressed: () =>
                              _showScheduleForStudentDialog(studentName, list),
                          child: const Text('Schedule'),
                        ),
                      ],
                    ),
                    children: list.map((p) => _projectTile(p)).toList(),
                  ),
                );
              }).toList(),
            );
          },
        );

      case 2: // Dashboard
        return ListView(
          children: [
            FutureBuilder<List<Project>>(
              future: _projectsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final projects = snapshot.data ?? [];
                final total = projects.length;
                final byStatus = <String, int>{};
                final byDomain = <String, int>{};
                for (var p in projects) {
                  byStatus[p.status] = (byStatus[p.status] ?? 0) + 1;
                  byDomain[p.domain] = (byDomain[p.domain] ?? 0) + 1;
                }
                return Padding(
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
                            'Overview',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Text('Total proposals: $total'),
                          const SizedBox(height: 8),
                          Text('By status:'),
                          ...byStatus.entries.map(
                            (e) => Text('${e.key}: ${e.value}'),
                          ),
                          const SizedBox(height: 8),
                          Text('By domain:'),
                          ...byDomain.entries.map(
                            (e) => Text('${e.key}: ${e.value}'),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            FutureBuilder<List<dynamic>>(
              future: _usersFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox.shrink();
                }
                if (snapshot.hasError) return const SizedBox.shrink();
                final users = snapshot.data ?? [];
                return Padding(
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
                        children: [Text('Users: ${users.length}')],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
