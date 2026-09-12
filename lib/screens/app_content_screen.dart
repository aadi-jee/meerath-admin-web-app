import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/menu_repository.dart';
import '../theme/app_colors.dart';
import 'website_content_editor.dart';
import 'catering_enquiries_screen.dart';

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
      final data = await Future.wait([
        _repo.loadBanners(),
        _repo.loadMenuItems(),
        _repo.loadCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _banners = data[0];
        _items = data[1];
        _categories = data[2];
      });
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(int slot, Map<String, dynamic>? banner) async {
    final saved = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _BannerEditor(
        slot: slot,
        banner: banner,
        items: _items,
        categories: _categories,
      ),
    );
    if (saved == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final active = _banners.where((b) => b['is_active'] == true).length;
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 24, 28, 40),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Content Studio',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'Manage what customers see across the Meerath website and ordering app.',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _load,
                  tooltip: 'Refresh content',
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (wide)
              Row(
                children: [
                  Expanded(
                    child: _actionCard(
                      icon: Icons.language_rounded,
                      eyebrow: 'WEBSITE',
                      title: 'Website presentation',
                      subtitle:
                          'Brand, hero, story, contact details, featured dishes and SEO',
                      action: 'Edit website',
                      onTap: _openWebsiteEditor,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _actionCard(
                      icon: Icons.celebration_outlined,
                      eyebrow: 'LEADS',
                      title: 'Catering & events',
                      subtitle:
                          'Review enquiries and move each opportunity through its status',
                      action: 'Open enquiries',
                      onTap: _openCatering,
                    ),
                  ),
                ],
              )
            else ...[
              _actionCard(
                icon: Icons.language_rounded,
                eyebrow: 'WEBSITE',
                title: 'Website presentation',
                subtitle:
                    'Brand, hero, story, contact details, featured dishes and SEO',
                action: 'Edit website',
                onTap: _openWebsiteEditor,
              ),
              const SizedBox(height: 12),
              _actionCard(
                icon: Icons.celebration_outlined,
                eyebrow: 'LEADS',
                title: 'Catering & events',
                subtitle:
                    'Review enquiries and move each opportunity through its status',
                action: 'Open enquiries',
                onTap: _openCatering,
              ),
            ],
            const SizedBox(height: 30),
            Row(
              children: [
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Home banners',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Three customer-facing positions, shown in this order.',
                        style: TextStyle(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$active of 3 live',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_error != null)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            if (_error == null)
              if (wide)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (var slot = 1; slot <= 3; slot++) ...[
                      Expanded(child: _slotCard(slot)),
                      if (slot < 3) const SizedBox(width: 14),
                    ],
                  ],
                )
              else
                for (var slot = 1; slot <= 3; slot++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _slotCard(slot),
                  ),
            const SizedBox(height: 14),
            const Text(
              'Disabled positions remain saved but stay hidden from customers. Linked items always use their current menu price.',
              style: TextStyle(color: AppColors.textDim, fontSize: 12),
            ),
          ],
        );
      },
    );
  }

  void _openWebsiteEditor() => showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const WebsiteContentEditor(),
  );

  void _openCatering() => Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const CateringEnquiriesScreen()),
  );

  Widget _actionCard({
    required IconData icon,
    required String eyebrow,
    required String title,
    required String subtitle,
    required String action,
    required VoidCallback onTap,
  }) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: AppColors.accent, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          action,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(
                          Icons.arrow_forward_rounded,
                          color: AppColors.accent,
                          size: 17,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotCard(int slot) {
    final matches = _banners.where((b) => b['slot'] == slot);
    final b = matches.isEmpty ? null : matches.first;
    final image = b?['image_url'] as String? ?? '';
    final isActive = b?['is_active'] == true;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () => _edit(slot, b),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 120,
              width: double.infinity,
              child: image.isEmpty
                  ? Container(
                      color: AppColors.surfaceAlt,
                      child: const Icon(
                        Icons.add_photo_alternate_outlined,
                        color: AppColors.textDim,
                        size: 34,
                      ),
                    )
                  : Image.network(
                      image,
                      fit: BoxFit.cover,
                      errorBuilder: (_, error, stack) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(
                          Icons.broken_image_outlined,
                          color: AppColors.textDim,
                        ),
                      ),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'POSITION $slot',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.circle,
                        size: 9,
                        color: isActive ? AppColors.success : AppColors.textDim,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isActive ? 'Live' : 'Hidden',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    b?['title_en'] as String? ?? 'Empty banner position',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    b == null
                        ? 'Add content and destination'
                        : 'Opens ${_targetLabel('${b['target_kind']}')}',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        color: AppColors.accent,
                        size: 17,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Edit banner',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _targetLabel(String value) => switch (value) {
    'item' => 'a menu item',
    'category' => 'a category',
    'offers' => 'offers',
    _ => 'the menu',
  };
}

class _BannerEditor extends StatefulWidget {
  const _BannerEditor({
    required this.slot,
    this.banner,
    required this.items,
    required this.categories,
  });
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
    for (final name in [
      'title_en',
      'title_ar',
      'subtitle_en',
      'subtitle_ar',
      'button_en',
      'button_ar',
    ]) {
      _fields[name] = TextEditingController(
        text: b[name] as String? ?? (name == 'button_en' ? 'View menu' : ''),
      );
    }
    _kind = b['target_kind'] as String? ?? 'menu';
    _target = b['target_id'] as String?;
    _image = b['image_url'] as String? ?? '';
    _active = b['is_active'] == true;
  }

  @override
  void dispose() {
    for (final c in _fields.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _cancel() async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard banner changes?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Discard'),
            ),
          ],
        ),
      );
      if (discard != true || !mounted) return;
    }
    if (mounted) Navigator.pop(context, false);
  }

  Future<void> _upload() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;

      final fileSize = await file.length();
      if (fileSize > 5 * 1024 * 1024) {
        throw const FormatException('Choose an image smaller than 5 MB.');
      }

      final bytes = await file.readAsBytes();
      final url = await _repo.uploadImage(bytes, file.name);
      if (mounted) {
        setState(() {
          _image = url;
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.saveBanner({
        'slot': widget.slot,
        for (final e in _fields.entries) e.key: e.value.text.trim(),
        'image_url': _image,
        'target_kind': _kind,
        'target_id': ['item', 'category'].contains(_kind) ? _target : null,
        'is_active': _active,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete() async {
    if (widget.banner == null || _busy) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this banner?'),
        content: const Text(
          'This banner position will become empty. The uploaded image file is kept for safety.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await _repo.deleteBanner(widget.slot);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _text(String key, String label, int limit, {bool required = false}) =>
      TextFormField(
        controller: _fields[key],
        maxLength: limit,
        decoration: InputDecoration(labelText: label),
        onChanged: (_) => setState(() => _dirty = true),
        validator: (v) =>
            required && (v ?? '').trim().isEmpty ? 'Required' : null,
      );
  @override
  Widget build(BuildContext context) {
    final targets = _kind == 'item' ? widget.items : widget.categories;
    final hasTarget = targets.any((i) => i['id'] == _target);
    String preview(String name) {
      final ar = _fields['${name}_ar']!.text.trim();
      return _arabicPreview && ar.isNotEmpty
          ? ar
          : _fields['${name}_en']!.text.trim();
    }

    return PopScope(
      canPop: false,
      child: AlertDialog(
        title: Text('Banner position ${widget.slot}'),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: AbsorbPointer(
              absorbing: _busy,
              child: Form(
                key: _form,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _text('title_en', 'English title', 80, required: true),
                    _text('title_ar', 'Arabic title (optional)', 80),
                    _text('subtitle_en', 'English subtitle', 160),
                    _text('subtitle_ar', 'Arabic subtitle', 160),
                    _text(
                      'button_en',
                      'English button text',
                      35,
                      required: true,
                    ),
                    _text('button_ar', 'Arabic button text', 35),
                    DropdownButtonFormField<String>(
                      initialValue: _kind,
                      decoration: const InputDecoration(
                        labelText: 'Open when tapped',
                      ),
                      items: ['menu', 'category', 'item', 'offers']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                      onChanged: (v) => setState(() {
                        _kind = v!;
                        _target = null;
                        _dirty = true;
                      }),
                    ),
                    if (['item', 'category'].contains(_kind))
                      DropdownButtonFormField<String>(
                        key: ValueKey(_kind),
                        initialValue: hasTarget ? _target : null,
                        isExpanded: true,
                        decoration: const InputDecoration(
                          labelText: 'Choose destination',
                        ),
                        items: targets
                            .map(
                              (v) => DropdownMenuItem(
                                value: v['id'] as String,
                                child: Text(
                                  v['name_en'] as String? ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            )
                            .toList(),
                        validator: (v) =>
                            v == null ? 'Select a destination' : null,
                        onChanged: (v) => setState(() {
                          _target = v;
                          _dirty = true;
                        }),
                      ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enabled on customer home'),
                      value: _active,
                      onChanged: (v) => setState(() {
                        _active = v;
                        _dirty = true;
                      }),
                    ),
                    Wrap(
                      spacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: _upload,
                          icon: const Icon(Icons.upload),
                          label: const Text('Upload image (max 5 MB)'),
                        ),
                        if (_image.isNotEmpty)
                          TextButton(
                            onPressed: () => setState(() {
                              _image = '';
                              _dirty = true;
                            }),
                            child: const Text('Remove image'),
                          ),
                      ],
                    ),
                    const Text(
                      'Use a wide food photo (suggested 1600 × 700). Keep prices out of images/text; item links show the live price.',
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Arabic preview'),
                      value: _arabicPreview,
                      onChanged: (v) => setState(() => _arabicPreview = v),
                    ),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Directionality(
                          textDirection: _arabicPreview
                              ? TextDirection.rtl
                              : TextDirection.ltr,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (_image.isNotEmpty)
                                Image.network(
                                  _image,
                                  height: 140,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, error, stack) =>
                                      const Text('Image preview unavailable'),
                                ),
                              Text(
                                preview('title'),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(preview('subtitle')),
                              const SizedBox(height: 8),
                              Text(preview('button')),
                              if (_kind == 'item')
                                const Text(
                                  'Customer view also shows the current item price.',
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (_error != null)
                      Text(
                        _error!,
                        style: const TextStyle(color: Colors.redAccent),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          if (_busy) const CircularProgressIndicator(),
          if (widget.banner != null)
            TextButton.icon(
              onPressed: _busy ? null : _delete,
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              label: const Text(
                'Delete banner',
                style: TextStyle(color: Colors.redAccent),
              ),
            ),
          TextButton(
            onPressed: _busy ? null : _cancel,
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _busy ? null : _save,
            child: const Text('Save banner'),
          ),
        ],
      ),
    );
  }
}
