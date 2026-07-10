import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/models/routine.dart';
import '../state/routines_provider.dart';
import '../theme/notebook_theme.dart';
import '../widgets/notebook_header.dart';
import '../widgets/notebook_page.dart';
import 'calendar_screen.dart';
import 'manage_routine_screen.dart';
import 'routine_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final RoutinesProvider _provider;
  final _nameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _provider = RoutinesProvider()..load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _submitNewRoutine() async {
    final name = _nameController.text;
    if (name.trim().isEmpty) return;
    await _provider.addRoutine(name);
    _nameController.clear();
    if (mounted) FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
        drawer: _NotebookDrawer(),
        body: SafeArea(
          child: NotebookPage(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Builder(
                  builder: (context) => NotebookHeader(
                    title: 'My fit notebook',
                    large: true,
                    leading: IconButton(
                      icon: const Icon(Icons.menu, color: NotebookColors.inkSoft),
                      onPressed: () => Scaffold.of(context).openDrawer(),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_month, color: NotebookColors.inkSoft),
                      tooltip: 'Calendar',
                      onPressed: () => Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CalendarScreen()),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'New routine',
                      style: TextStyle(
                        fontFamily: 'Caveat',
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: NotebookColors.ink,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        style: const TextStyle(fontFamily: 'Caveat', fontSize: 20),
                        decoration: const InputDecoration(
                          hintText: 'Name…',
                          isDense: true,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(color: NotebookColors.ink),
                          ),
                        ),
                        onSubmitted: (_) => _submitNewRoutine(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.check, color: NotebookColors.ink),
                      tooltip: 'Create routine',
                      onPressed: _submitNewRoutine,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Expanded(child: _RoutineList()),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoutineList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoutinesProvider>();
    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (provider.routines.isEmpty) {
      return const Text(
        'No routines yet — add one above.',
        style: TextStyle(fontFamily: 'Caveat', fontSize: 20, color: NotebookColors.inkSoft),
      );
    }
    return ListView.separated(
      itemCount: provider.routines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 2),
      itemBuilder: (context, index) {
        final routine = provider.routines[index];
        return Row(
          children: [
            if (routine.isStarted)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.fiber_manual_record, size: 10, color: NotebookColors.ink),
              ),
            Expanded(
              child: InkWell(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => RoutineScreen(routineId: routine.id)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    routine.name,
                    style: const TextStyle(
                      fontFamily: 'Caveat',
                      fontSize: 22,
                      color: NotebookColors.ink,
                    ),
                  ),
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, size: 20, color: NotebookColors.inkSoft),
              tooltip: 'Manage ${routine.name}',
              onPressed: () async {
                await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ManageRoutineScreen(routineId: routine.id)),
                );
                if (context.mounted) context.read<RoutinesProvider>().load();
              },
            ),
            IconButton(
              icon: const Icon(Icons.close, color: NotebookColors.inkSoft),
              tooltip: 'Delete ${routine.name}',
              onPressed: () => _confirmDelete(context, routine),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, Routine routine) async {
    final provider = context.read<RoutinesProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete "${routine.name}"?'),
        content: const Text('This removes the routine, its exercises, and its history.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await provider.deleteRoutine(routine.id);
    }
  }
}

class _NotebookDrawer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: NotebookColors.paper,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            ListTile(
              leading: Icon(Icons.person_outline, color: NotebookColors.inkSoft),
              title: Text('Profile', style: TextStyle(fontFamily: 'Caveat', fontSize: 22)),
            ),
            ListTile(
              leading: Icon(Icons.history, color: NotebookColors.inkSoft),
              title: Text('History', style: TextStyle(fontFamily: 'Caveat', fontSize: 22)),
            ),
            ListTile(
              leading: Icon(Icons.insert_chart_outlined, color: NotebookColors.inkSoft),
              title: Text('Reports', style: TextStyle(fontFamily: 'Caveat', fontSize: 22)),
            ),
          ],
        ),
      ),
    );
  }
}
