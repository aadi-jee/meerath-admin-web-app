import 'dart:async';
import 'package:flutter/material.dart';
import '../data/catering_repository.dart';
import '../screens/catering_enquiries_screen.dart';

/// Persistent new-enquiry backlog: initial fetch, resume and 30-second polling.
/// Opening this widget never changes the saved enquiry status.
class CateringDashboardAlert extends StatefulWidget {
  const CateringDashboardAlert({super.key});
  @override
  State<CateringDashboardAlert> createState() => _CateringDashboardAlertState();
}

class _CateringDashboardAlertState extends State<CateringDashboardAlert>
    with WidgetsBindingObserver {
  Timer? _timer;
  int? _count;
  bool _busy = false;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _refresh());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    if (_busy) {
      return;
    }
    _busy = true;
    try {
      final count = await CateringRepository().newCount();
      if (mounted) {
        setState(() {
          _count = count;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _failed = true);
      }
    } finally {
      _busy = false;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 18,
        runSpacing: 10,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Icon(Icons.notifications_active_outlined, color: Colors.orange),
          Text(
            _failed
                ? 'Catering alert unavailable — retry'
                : _count == null
                ? 'Checking catering enquiries…'
                : '$_count new catering enquiries awaiting response',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          TextButton(
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const CateringEnquiriesScreen(),
                ),
              );
              if (mounted) {
                _refresh();
              }
            },
            child: const Text('View enquiries'),
          ),
          IconButton(
            onPressed: _refresh,
            tooltip: 'Refresh catering count',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
    ),
  );
}
