import 'package:flutter/material.dart';
import '../data/catering_repository.dart';
import '../data/menu_repository.dart';

class CateringEnquiriesScreen extends StatefulWidget {
  const CateringEnquiriesScreen({super.key, this.repository});
  final CateringRepository? repository;
  @override
  State<CateringEnquiriesScreen> createState() =>
      _CateringEnquiriesScreenState();
}

class _CateringEnquiriesScreenState extends State<CateringEnquiriesScreen> {
  late final CateringRepository _repo =
      widget.repository ?? CateringRepository();
  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;
  String? _error;
  String? _saving;
  String _filter = 'all';
  final Set<String> _expanded = {};
  static const statuses = {
    'new': Colors.orange,
    'contacted': Colors.lightBlue,
    'quoted': Colors.purpleAccent,
    'confirmed': Colors.green,
    'completed': Colors.blueGrey,
    'lost': Colors.redAccent,
  };
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await _repo.loadEnquiries();
      if (mounted) {
        setState(() => _rows = rows);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _error = MenuRepository.errorMessage(e));
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _when(dynamic value) {
    final parsed = DateTime.tryParse('$value');
    if (parsed == null) {
      return 'Not provided';
    }
    final d = parsed.toUtc().add(const Duration(hours: 3));
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    return '${d.day}/${d.month}/${d.year}  $h:${d.minute.toString().padLeft(2, '0')} ${d.hour < 12 ? 'AM' : 'PM'} (Riyadh)';
  }

  String _label(String value) => value
      .split('_')
      .map((x) => x.isEmpty ? x : '${x[0].toUpperCase()}${x.substring(1)}')
      .join(' ');

  Future<void> _status(Map<String, dynamic> row, String value) async {
    if (_saving != null || row['status'] == value) {
      return;
    }
    setState(() => _saving = row['id'] as String);
    try {
      final saved = await _repo.setStatus(row['id'] as String, value);
      if (!mounted) {
        return;
      }
      setState(() {
        final index = _rows.indexWhere((r) => r['id'] == saved['id']);
        if (index >= 0) {
          _rows[index] = saved;
        }
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Saved: ${_label(value)}')));
    } catch (e) {
      if (!mounted) {
        return;
      }
      // A read may fail after commit. Never claim an unverified status was saved.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 10),
          content: Text(
            'Could not confirm status: ${MenuRepository.errorMessage(e)}. Refresh to check the saved record.',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _saving = null);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _rows
        .where((r) => _filter == 'all' || r['status'] == _filter)
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catering enquiries'),
        actions: [
          IconButton(
            onPressed: _loading || _saving != null ? null : _load,
            tooltip: 'Refresh saved enquiries',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Text(
                  'Latest 250 enquiries · select a status to save. Opening an enquiry does not mark it contacted.',
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final s in ['all', ...statuses.keys])
                      FilterChip(
                        label: Text(_label(s)),
                        selected: _filter == s,
                        onSelected: (_) => setState(() => _filter = s),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                if (visible.isEmpty) const Text('No enquiries in this view.'),
                for (final r in visible) _card(r),
              ],
            ),
    );
  }

  Widget _card(Map<String, dynamic> r) {
    final status = r['status'] as String? ?? 'new';
    final id = r['id'] as String;
    final expanded = _expanded.contains(id);
    final color = statuses[status] ?? Colors.grey;
    final venue = switch (r['venue_type']) {
      'meerath' => 'At Meerath restaurant',
      'outside' => 'Outside catering',
      _ => 'Not decided yet',
    };
    final name = '${r['customer_name'] ?? ''}'.trim().isEmpty
        ? 'Guest'
        : '${r['customer_name']}'.trim();
    final event = _label(r['event_type'] as String? ?? 'event');
    final guests = int.tryParse('${r['guest_count']}');
    final area = '${r['area'] ?? ''}'.trim();
    final place = r['venue_type'] == 'meerath'
        ? 'Meerath Kabab'
        : area.isNotEmpty
        ? area
        : venue;
    final guestText = guests == null
        ? 'an estimated number of guests'
        : '$guests ${guests == 1 ? 'guest' : 'guests'}';
    return Card(
      key: ValueKey(r['id']),
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Chip(
                  avatar: Icon(Icons.circle, size: 12, color: color),
                  label: Text(_label(status)),
                  side: BorderSide(color: color),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '$name wants to enquire about $event at $place for $guestText.',
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Received ${_when(r['created_at'])}  ·  ${r['mobile'] ?? ''}  ·  ${r['event_date'] ?? 'Date undecided'}',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            TextButton.icon(
              key: ValueKey('expand-$id'),
              onPressed: () => setState(() {
                if (expanded) {
                  _expanded.remove(id);
                } else {
                  _expanded.add(id);
                }
              }),
              icon: Icon(expanded ? Icons.expand_less : Icons.expand_more),
              label: Text(expanded ? 'Hide details' : 'View details'),
            ),
            if (expanded) ...[
              const SizedBox(height: 12),
              _detail('Mobile / WhatsApp', r['mobile']),
              _detail(
                'Venue / location',
                r['venue_type'] == 'meerath'
                    ? 'Meerath Kabab'
                    : area.isEmpty
                    ? venue
                    : '$venue · $area',
              ),
              _detail('Preferred date', r['event_date']),
              _detail('Guests (total)', r['guest_count']),
              _detail('Adults / ages 12+', r['adult_count']),
              if ((int.tryParse('${r['kids_5_11_count']}') ?? 0) > 0)
                _detail('Children 5–11', r['kids_5_11_count']),
              if ((int.tryParse('${r['kids_under_5_count']}') ?? 0) > 0)
                _detail('Children under 5', r['kids_under_5_count']),
              _detail('Customer message', r['message']),
              _detail('Last updated', _when(r['updated_at'])),
            ],
            const Divider(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                const Text('Update status:'),
                DropdownButton<String>(
                  value: statuses.containsKey(status) ? status : null,
                  items: [
                    for (final entry in statuses.entries)
                      DropdownMenuItem(
                        value: entry.key,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, color: entry.value, size: 12),
                            const SizedBox(width: 8),
                            Text(_label(entry.key)),
                          ],
                        ),
                      ),
                  ],
                  onChanged: _saving != null
                      ? null
                      : (value) {
                          if (value != null) {
                            _status(r, value);
                          }
                        },
                ),
                if (_saving == r['id']) const Text('Saving and verifying…'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detail(String title, dynamic value) {
    final text = value == null || '$value'.trim().isEmpty
        ? 'Not provided'
        : '$value';
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: SelectableText(text)),
        ],
      ),
    );
  }
}
