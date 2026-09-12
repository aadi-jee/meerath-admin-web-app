import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../data/menu_repository.dart';
import '../data/website_repository.dart';

class WebsiteContentEditor extends StatefulWidget {
  const WebsiteContentEditor({super.key});
  @override
  State<WebsiteContentEditor> createState() => _WebsiteContentEditorState();
}

class _WebsiteContentEditorState extends State<WebsiteContentEditor> {
  final _repo = WebsiteRepository();
  final _menu = MenuRepository();
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{};
  final _selected = <String>[];
  List<Map<String, dynamic>> _items = [];
  bool _loading = true, _busy = false, _dirty = false, _loaded = false;
  int _revision = 0;
  String? _error;
  static const groups = <String, Map<String, String>>{
    'Brand and hero': {
      'logo_url': 'Logo image URL',
      'hero_url': 'Hero image URL',
      'heading_en': 'Main heading — English',
      'heading_ar': 'Main heading — Arabic',
      'intro_en': 'Introduction — English',
      'intro_ar': 'Introduction — Arabic',
      'button_en': 'Hero button — English',
      'button_ar': 'Hero button — Arabic',
    },
    'About Meerath': {
      'about_heading_en': 'Story heading — English',
      'about_heading_ar': 'Story heading — Arabic',
      'about_en': 'Story — English',
      'about_ar': 'Story — Arabic',
    },
    'Contact and opening hours': {
      'phone': 'Phone (+966561663119)',
      'whatsapp': 'WhatsApp (966561663119)',
      'address_en': 'Full address — English',
      'address_ar': 'Full address — Arabic',
      'maps_url': 'Google Maps URL',
      'hours_en': 'Hours — English (12-hour AM/PM)',
      'hours_ar': 'Hours — Arabic',
    },
    'Social links': {
      'facebook_url': 'Facebook URL',
      'instagram_url': 'Instagram URL',
      'tiktok_url': 'TikTok URL',
    },
    'Homepage SEO': {
      'seo_title_en': 'SEO title — English',
      'seo_title_ar': 'SEO title — Arabic',
      'seo_description_en': 'SEO description — English',
      'seo_description_ar': 'SEO description — Arabic',
    },
    'Events & Catering': {
      'catering_hero_url': 'Catering hero image',
      'catering_heading_en': 'Main heading — English',
      'catering_heading_ar': 'Main heading — Arabic',
      'catering_intro_en': 'Introduction — English',
      'catering_intro_ar': 'Introduction — Arabic',
      'catering_corporate_url': 'Corporate lunches image',
      'catering_family_url': 'Family gatherings image',
      'catering_birthday_url': 'Birthday celebrations image',
      'catering_anniversary_url': 'Anniversary dinners image',
      'catering_wedding_url': 'Wedding and outdoor catering image',
      'catering_restaurant_url': 'Celebrate at Meerath image',
    },
    'Catering portfolio gallery': {
      'catering_gallery_1_url': 'Gallery image 1',
      'catering_gallery_2_url': 'Gallery image 2',
      'catering_gallery_3_url': 'Gallery image 3',
      'catering_gallery_4_url': 'Gallery image 4',
      'catering_gallery_5_url': 'Gallery image 5',
      'catering_gallery_6_url': 'Gallery image 6',
    },
  };
  @override
  void initState() {
    super.initState();
    for (final group in groups.values) {
      for (final key in group.keys) {
        _fields[key] = TextEditingController();
      }
    }
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _loaded = false;
    });
    try {
      final row = await _repo.load();
      final items = await _menu.loadMenuItems();
      if (!mounted) return;
      final data = Map<String, dynamic>.from(row?['content'] as Map? ?? {});
      for (final field in _fields.entries) {
        field.value.text = data[field.key] as String? ?? '';
      }
      _selected
        ..clear()
        ..addAll(List<String>.from(data['featured_ids'] as List? ?? []));
      setState(() {
        _revision = (row?['revision'] as num?)?.toInt() ?? 0;
        _items = items;
        _dirty = false;
        _loaded = true;
      });
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final field in _fields.values) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> _close() async {
    if (_busy) return;
    if (_dirty) {
      final discard = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Discard unsaved website changes?'),
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
    if (mounted) Navigator.pop(context);
  }

  Future<void> _upload(String key) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null) return;
      if (await file.length() > 5 * 1024 * 1024) {
        throw const FormatException('Choose a JPG, PNG or WebP under 5 MB.');
      }
      final url = await _menu.uploadImage(await file.readAsBytes(), file.name);
      if (mounted) {
        setState(() {
          _fields[key]!.text = url;
          _dirty = true;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _imageEditor(String key, String title, String guidance) {
    final url = _fields[key]!.text.trim();
    final custom = url.startsWith('https://');
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(guidance),
            const SizedBox(height: 14),
            if (custom)
              Image.network(
                url,
                height: key.contains('hero_url') ? 210 : 140,
                fit: key == 'logo_url' ? BoxFit.contain : BoxFit.cover,
                errorBuilder: (_, error, stack) => const SizedBox(
                  height: 100,
                  child: Center(
                    child: Text(
                      'Image preview unavailable. Replace it or restore the original.',
                    ),
                  ),
                ),
              )
            else
              Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  border: Border.all(color: Theme.of(context).dividerColor),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  key == 'logo_url'
                      ? 'Original Meerath logo is active'
                      : key == 'hero_url' || key == 'catering_hero_url'
                      ? 'The original website hero image is active'
                      : 'No image selected — this block stays elegantly styled without a photo',
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _upload(key),
                  icon: const Icon(Icons.image_outlined),
                  label: Text(custom ? 'Replace image' : 'Choose new image'),
                ),
                if (custom)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _fields[key]!.clear();
                      _dirty = true;
                    }),
                    icon: const Icon(Icons.restore),
                    label: const Text('Restore original'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textField(String key, String label) {
    final isSeoTitle = key.startsWith('seo_title');
    final isSeoDescription = key.startsWith('seo_description');
    final limit = isSeoTitle
        ? 70
        : isSeoDescription
        ? 170
        : 3000;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _fields[key],
        textDirection: key.endsWith('_ar')
            ? TextDirection.rtl
            : TextDirection.ltr,
        maxLength: limit,
        minLines: 1,
        maxLines: key.endsWith('_url') || key == 'phone' || key == 'whatsapp'
            ? 1
            : 4,
        decoration: InputDecoration(
          labelText: label,
          helperText: isSeoTitle
              ? 'Recommended: roughly 50–60 characters. Leave blank to use the safe default.'
              : isSeoDescription
              ? 'Recommended: roughly 140–160 characters. Leave blank to use the safe default.'
              : null,
        ),
        validator: (v) => _validate(key, v),
        onChanged: (_) => setState(() => _dirty = true),
      ),
    );
  }

  Future<void> _save() async {
    if (!_loaded || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final revision = await _repo.save({
        for (final e in _fields.entries) e.key: e.value.text.trim(),
        'featured_ids': _selected,
      }, _revision);
      if (!mounted) return;
      setState(() {
        _revision = revision;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Published. Refresh the website to see your changes.'),
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validate(String key, String? value) {
    final v = (value ?? '').trim();
    if (v.isEmpty) return null;
    if (key.endsWith('_url')) {
      final u = Uri.tryParse(v);
      if (u == null ||
          u.scheme != 'https' ||
          u.host.isEmpty ||
          u.userInfo.isNotEmpty ||
          RegExp(r'\s').hasMatch(v)) {
        return 'Enter a complete https:// URL';
      }
    }
    if (key == 'phone' && !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(v)) {
      return 'Example: +966561663119';
    }
    if (key == 'whatsapp' && !RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(v)) {
      return 'Example: 966561663119';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Website settings',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : _close,
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (_loading)
                const Expanded(
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                Expanded(
                  child: SingleChildScrollView(
                    child: AbsorbPointer(
                      absorbing: _busy,
                      child: Form(
                        key: _form,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            const Text(
                              'Save & publish updates the website after refresh. Blank main text/contact fields use the original website defaults. Blank social links and opening hours are hidden. Menu data continues to come from Menu.',
                            ),
                            if (_error != null)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                              ),
                            for (final group in groups.entries)
                              Card(
                                margin: const EdgeInsets.only(top: 14),
                                child: ExpansionTile(
                                  initiallyExpanded:
                                      group.key == 'Brand and hero',
                                  title: Text(
                                    group.key,
                                    style: const TextStyle(
                                      fontSize: 19,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    group.key == 'Homepage SEO'
                                        ? 'Advanced — optional. Safe defaults are already active.'
                                        : group.key == 'Brand and hero'
                                        ? 'Images, headline and main button text'
                                        : 'Open to edit',
                                  ),
                                  childrenPadding: const EdgeInsets.fromLTRB(
                                    16,
                                    0,
                                    16,
                                    18,
                                  ),
                                  children: [
                                    for (final field in group.value.entries)
                                      if (field.key.endsWith('_url') &&
                                          (field.key == 'logo_url' ||
                                              field.key == 'hero_url' ||
                                              field.key.startsWith(
                                                'catering_',
                                              )))
                                        _imageEditor(
                                          field.key,
                                          field.value,
                                          field.key == 'logo_url'
                                              ? 'Square transparent PNG or WebP recommended. Blank means the original Meerath logo.'
                                              : 'JPG, PNG or WebP under 5 MB. Use a genuine landscape event or food image without text.',
                                        )
                                      else
                                        _textField(field.key, field.value),
                                  ],
                                ),
                              ),
                            Card(
                              margin: const EdgeInsets.only(top: 14),
                              child: ExpansionTile(
                                title: const Text(
                                  'Homepage featured dishes',
                                  style: TextStyle(
                                    fontSize: 19,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  _selected.isEmpty
                                      ? 'Automatic: first six published dishes'
                                      : '${_selected.length} of 6 dishes selected',
                                ),
                                childrenPadding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  18,
                                ),
                                children: [
                                  const Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      'Choose up to six. Selection order is display order. Leave all unchecked to use the first six published items in menu order.',
                                    ),
                                  ),
                                  for (final id
                                      in _selected
                                          .where(
                                            (id) => !_items.any(
                                              (i) => i['id'] == id,
                                            ),
                                          )
                                          .toList())
                                    ListTile(
                                      title: const Text(
                                        'Previously selected dish was removed',
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.remove_circle_outline,
                                        ),
                                        onPressed: () => setState(() {
                                          _selected.remove(id);
                                          _dirty = true;
                                        }),
                                      ),
                                    ),
                                  for (final item in _items)
                                    CheckboxListTile(
                                      title: Text(
                                        item['name_en'] as String? ?? '',
                                      ),
                                      subtitle: Text(
                                        '${item['status']} ${_selected.contains(item['id']) ? '• Position ${_selected.indexOf(item['id'] as String) + 1}' : ''}',
                                      ),
                                      value: _selected.contains(item['id']),
                                      onChanged: (v) {
                                        final id = item['id'] as String;
                                        if (v == true &&
                                            _selected.length >= 6) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Maximum six featured dishes.',
                                              ),
                                            ),
                                          );
                                          return;
                                        }
                                        setState(() {
                                          if (v == true) {
                                            _selected.add(id);
                                          } else {
                                            _selected.remove(id);
                                          }
                                          _dirty = true;
                                        });
                                      },
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 16,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (_busy)
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(),
                    ),
                  TextButton(
                    onPressed: _busy ? null : _close,
                    child: const Text('Close'),
                  ),
                  if (!_loading && !_loaded)
                    TextButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Retry loading'),
                    ),
                  FilledButton(
                    onPressed: !_loaded || _loading || _busy ? null : _save,
                    child: const Text('Save & publish'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
