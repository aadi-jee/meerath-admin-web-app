import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/menu_repository.dart';

class AppContentScreen extends StatefulWidget {
  const AppContentScreen({super.key});
  @override
  State<AppContentScreen> createState() => _AppContentScreenState();
}

class _AppContentScreenState extends State<AppContentScreen> {
  final _repo = MenuRepository();
  List<Map<String, dynamic>> _banners = [], _items = [], _categories = [];
  bool _loading = true;
  String? _error;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final data = await Future.wait([_repo.loadBanners(), _repo.loadMenuItems(), _repo.loadCategories()]);
      if (!mounted) return;
      setState(() { _banners = data[0]; _items = data[1]; _categories = data[2]; });
    } catch (e) { if (mounted) setState(() => _error = MenuRepository.errorMessage(e)); }
    finally { if (mounted) setState(() => _loading = false); }
  }
  Future<void> _edit(int slot, Map<String, dynamic>? banner) async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => _BannerEditor(slot: slot, banner: banner, items: _items, categories: _categories));
    if (saved == true && mounted) await _load();
  }
  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView(padding: const EdgeInsets.all(24), children: [
      Row(children: [const Expanded(child: Text('Home Banners', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold))),
        IconButton(onPressed: _load, tooltip: 'Refresh', icon: const Icon(Icons.refresh))]),
      const Text('Three positions, displayed in order. Disable a position to hide it. Swipe navigation; no auto-slide.\nItem links use the current item price. Unavailable targets stay hidden from customers.'),
      if (_error != null) Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
      if (_error == null) for (var slot = 1; slot <= 3; slot++) _slotCard(slot),
    ]);
  }
  Widget _slotCard(int slot) {
    final matches = _banners.where((b) => b['slot'] == slot);
    final b = matches.isEmpty ? null : matches.first;
    return Card(margin: const EdgeInsets.only(top: 16), child: ListTile(
      leading: CircleAvatar(child: Text('$slot')),
      title: Text(b?['title_en'] as String? ?? 'Empty banner position'),
      subtitle: Text(b == null ? 'Add content here' : '${b['is_active'] == true ? 'Enabled' : 'Hidden'} • ${b['target_kind']}'),
      trailing: const Icon(Icons.edit), onTap: () => _edit(slot, b),
    ));
  }
}

class _BannerEditor extends StatefulWidget {
  const _BannerEditor({required this.slot, this.banner, required this.items, required this.categories});
  final int slot;
  final Map<String, dynamic>? banner;
  final List<Map<String, dynamic>> items, categories;
  @override
  State<_BannerEditor> createState() => _BannerEditorState();
}
class _BannerEditorState extends State<_BannerEditor> {
  final _form = GlobalKey<FormState>();
  final _repo = MenuRepository();
  final _fields = <String, TextEditingController>{};
  String _kind = 'menu', _image = '';
  String? _target, _error;
  bool _active = false, _busy = false, _dirty = false, _arabicPreview = false;
  @override
  void initState() {
    super.initState();
    final b = widget.banner ?? {};
    for (final name in ['title_en', 'title_ar', 'subtitle_en', 'subtitle_ar', 'button_en', 'button_ar']) {
      _fields[name] = TextEditingController(text: b[name] as String? ?? (name == 'button_en' ? 'View menu' : ''));
    }
    _kind = b['target_kind'] as String? ?? 'menu'; _target = b['target_id'] as String?;
    _image = b['image_url'] as String? ?? ''; _active = b['is_active'] == true;
  }
  @override
  void dispose() { for (final c in _fields.values) { c.dispose(); } super.dispose(); }
  Future<void> _cancel() async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(context: context, builder: (ctx) => AlertDialog(
        title: const Text('Discard banner changes?'), actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep editing')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Discard'))]));
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context, false);
  }
  Future<void> _upload() async {
    setState(() { _busy = true; _error = null; });
    try {
      final file = await FilePicker.pickFile(
  type: FileType.image,
);
if (file == null) return;

final fileSize = await file.length();
if (fileSize > 5 * 1024 * 1024) {
  throw const FormatException('Choose an image smaller than 5 MB.');
}

final bytes = await file.readAsBytes();
final url = await _repo.uploadImage(bytes, file.name);
      if (mounted) setState(() { _image = url; _dirty = true; });
    } catch (e) { if (mounted) setState(() => _error = MenuRepository.errorMessage(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await _repo.saveBanner({'slot': widget.slot, for (final e in _fields.entries) e.key: e.value.text.trim(),
        'image_url': _image, 'target_kind': _kind, 'target_id': ['item','category'].contains(_kind) ? _target : null,
        'is_active': _active});
      if (mounted) Navigator.pop(context, true);
    } catch (e) { if (mounted) setState(() => _error = MenuRepository.errorMessage(e)); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Widget _text(String key, String label, int limit, {bool required = false}) => TextFormField(
    controller: _fields[key], maxLength: limit, decoration: InputDecoration(labelText: label),
    onChanged: (_) => setState(() => _dirty = true),
    validator: (v) => required && (v ?? '').trim().isEmpty ? 'Required' : null);
  @override
  Widget build(BuildContext context) {
    final targets = _kind == 'item' ? widget.items : widget.categories;
    final hasTarget = targets.any((i) => i['id'] == _target);
    String preview(String name) { final ar = _fields['${name}_ar']!.text.trim(); return _arabicPreview && ar.isNotEmpty ? ar : _fields['${name}_en']!.text.trim(); }
    return PopScope(canPop: false, child: AlertDialog(
      title: Text('Banner position ${widget.slot}'),
      content: SizedBox(width: 620, child: SingleChildScrollView(child: AbsorbPointer(absorbing: _busy,
        child: Form(key: _form, child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _text('title_en', 'English title', 80, required: true), _text('title_ar', 'Arabic title (optional)', 80),
          _text('subtitle_en', 'English subtitle', 160), _text('subtitle_ar', 'Arabic subtitle', 160),
          _text('button_en', 'English button text', 35, required: true), _text('button_ar', 'Arabic button text', 35),
          DropdownButtonFormField<String>(initialValue: _kind, decoration: const InputDecoration(labelText: 'Open when tapped'),
            items: ['menu','category','item','offers'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
            onChanged: (v) => setState(() { _kind = v!; _target = null; _dirty = true; })),
          if (['item','category'].contains(_kind)) DropdownButtonFormField<String>(
            key: ValueKey(_kind), initialValue: hasTarget ? _target : null, isExpanded: true,
            decoration: const InputDecoration(labelText: 'Choose destination'),
            items: targets.map((v) => DropdownMenuItem(value: v['id'] as String, child: Text(v['name_en'] as String? ?? '', overflow: TextOverflow.ellipsis))).toList(),
            validator: (v) => v == null ? 'Select a destination' : null,
            onChanged: (v) => setState(() { _target = v; _dirty = true; })),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Enabled on customer home'), value: _active,
            onChanged: (v) => setState(() { _active = v; _dirty = true; })),
          Wrap(spacing: 8, children: [TextButton.icon(onPressed: _upload, icon: const Icon(Icons.upload), label: const Text('Upload image (max 5 MB)')),
            if (_image.isNotEmpty) TextButton(onPressed: () => setState(() { _image = ''; _dirty = true; }), child: const Text('Remove image'))]),
          const Text('Use a wide food photo (suggested 1600 × 700). Keep prices out of images/text; item links show the live price.'),
          SwitchListTile(contentPadding: EdgeInsets.zero, title: const Text('Arabic preview'), value: _arabicPreview, onChanged: (v) => setState(() => _arabicPreview = v)),
          Card(child: Padding(padding: const EdgeInsets.all(16), child: Directionality(textDirection: _arabicPreview ? TextDirection.rtl : TextDirection.ltr,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (_image.isNotEmpty) Image.network(_image, height: 140, width: double.infinity, fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => const Text('Image preview unavailable')),
              Text(preview('title'), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              Text(preview('subtitle')), const SizedBox(height: 8), Text(preview('button')),
              if (_kind == 'item') const Text('Customer view also shows the current item price.'),
            ])))),
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.redAccent)),
        ]))))),
      actions: [if (_busy) const CircularProgressIndicator(), TextButton(onPressed: _busy ? null : _cancel, child: const Text('Cancel')),
        FilledButton(onPressed: _busy ? null : _save, child: const Text('Save banner'))],
    ));
  }
}
