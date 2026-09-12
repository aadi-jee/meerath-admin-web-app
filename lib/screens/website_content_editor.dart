import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
  Map<String, dynamic> _original = {};
  List<Map<String, dynamic>> _items = [];
  bool _announcementEnabled = false;
  bool _loading = true, _busy = false, _dirty = false, _loaded = false;
  int _revision = 0, _section = 0;
  String? _error;

  static const fields = <String, String>{
    'announcement_en': 'Announcement — English',
    'announcement_ar': 'Announcement — Arabic',
    'hero_url': 'Homepage cover',
    'heading_en': 'Homepage heading — English',
    'heading_ar': 'Homepage heading — Arabic',
    'intro_en': 'Short introduction — English',
    'intro_ar': 'Short introduction — Arabic',
    'phone': 'Phone',
    'whatsapp': 'WhatsApp',
    'address_en': 'Address — English',
    'address_ar': 'Address — Arabic',
    'maps_url': 'Google Maps link',
    'hours_en': 'Opening hours — English',
    'hours_ar': 'Opening hours — Arabic',
    'instagram_url': 'Instagram link',
    'facebook_url': 'Facebook link',
    'tiktok_url': 'TikTok link',
    'catering_hero_url': 'Events & Catering cover',
    'catering_gallery_1_url': 'Portfolio photo 1',
    'catering_gallery_2_url': 'Portfolio photo 2',
    'catering_gallery_3_url': 'Portfolio photo 3',
    'catering_gallery_4_url': 'Portfolio photo 4',
    'catering_gallery_5_url': 'Portfolio photo 5',
    'catering_gallery_6_url': 'Portfolio photo 6',
  };
  static const sections = [
    (
      Icons.campaign_outlined,
      'Announcement',
      'Short message shown across the website',
    ),
    (Icons.home_outlined, 'Homepage', 'Cover, heading and introduction'),
    (
      Icons.storefront_outlined,
      'Visit & contact',
      'Phone, location, hours and social links',
    ),
    (
      Icons.celebration_outlined,
      'Events portfolio',
      'Catering cover and recent work',
    ),
    (
      Icons.restaurant_menu,
      'Featured dishes',
      'Choose what appears on the homepage',
    ),
  ];

  @override
  void initState() {
    super.initState();
    for (final key in fields.keys) {
      _fields[key] = TextEditingController();
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
        _original = data;
        _announcementEnabled = data['announcement_enabled'] == true;
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
        builder: (context) => AlertDialog(
          title: const Text('Discard unsaved changes?'),
          content: const Text(
            'Your website will keep its currently published settings.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Keep editing'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
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

  int _limit(String key) {
    if (key.startsWith('announcement_')) return 140;
    if (key.startsWith('heading_')) return 90;
    if (key.startsWith('intro_')) return 260;
    if (key.startsWith('address_')) return 220;
    if (key.startsWith('hours_')) return 180;
    return 3000;
  }

  Widget _field(String key, {String? hint}) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: _fields[key],
      textDirection: key.endsWith('_ar')
          ? TextDirection.rtl
          : TextDirection.ltr,
      maxLength: _limit(key),
      maxLines: key.endsWith('_url') || key == 'phone' || key == 'whatsapp'
          ? 1
          : 3,
      decoration: InputDecoration(
        labelText: fields[key],
        hintText: hint,
        helperText: 'Leave blank to use the website default',
      ),
      validator: (value) => _validate(key, value),
      onChanged: (_) => setState(() => _dirty = true),
    ),
  );

  Widget _image(String key, String guidance) {
    final url = _fields[key]!.text.trim();
    final custom = url.startsWith('https://');
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              fields[key]!,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(
              guidance,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (custom)
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  url,
                  height: key.contains('hero') ? 190 : 125,
                  fit: BoxFit.cover,
                  errorBuilder: (_, error, stack) => const SizedBox(
                    height: 100,
                    child: Center(
                      child: Text(
                        'Preview unavailable — replace this photo or restore the default.',
                      ),
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
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Text('Original website image is active'),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              children: [
                FilledButton.tonalIcon(
                  onPressed: () => _upload(key),
                  icon: const Icon(Icons.add_photo_alternate_outlined),
                  label: Text(custom ? 'Replace photo' : 'Choose photo'),
                ),
                if (custom)
                  TextButton.icon(
                    onPressed: () => setState(() {
                      _fields[key]!.clear();
                      _dirty = true;
                    }),
                    icon: const Icon(Icons.restore),
                    label: const Text('Use original'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _heading(String title, String description) => Padding(
    padding: const EdgeInsets.only(bottom: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 5),
        Text(
          description,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _announcement() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Live announcement',
        'Use this for a limited-time offer, holiday timing or an important customer update.',
      ),
      Card(
        child: SwitchListTile(
          secondary: const Icon(Icons.campaign_outlined),
          title: const Text(
            'Show announcement on website',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          subtitle: Text(
            _announcementEnabled
                ? 'Live after you publish'
                : 'Currently hidden',
          ),
          value: _announcementEnabled,
          onChanged: (value) => setState(() {
            _announcementEnabled = value;
            _dirty = true;
          }),
        ),
      ),
      const SizedBox(height: 14),
      _field(
        'announcement_en',
        hint: 'Weekend family platter — available Thursday to Saturday',
      ),
      _field('announcement_ar', hint: 'اكتب الإعلان بالعربية'),
      const _InfoNote(
        icon: Icons.auto_awesome_outlined,
        text:
            'The message moves gently across the top of the website. Keep it short and clear.',
      ),
    ],
  );

  Widget _homepage() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Homepage',
        'Update the main photo and message customers see first.',
      ),
      _image(
        'hero_url',
        'Landscape JPG, PNG or WebP under 5 MB. Use a real Meerath food photo without text.',
      ),
      _field('heading_en'),
      _field('heading_ar'),
      _field('intro_en'),
      _field('intro_ar'),
    ],
  );

  Widget _contact() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Visit & contact',
        'Keep customer-facing details accurate. Social links can stay blank.',
      ),
      LayoutBuilder(
        builder: (context, box) {
          final left = Column(
            children: [
              _field('phone', hint: '+966561663119'),
              _field('whatsapp', hint: '966561663119'),
              _field('maps_url'),
            ],
          );
          final right = Column(
            children: [
              _field('address_en'),
              _field('address_ar'),
              _field('hours_en'),
              _field('hours_ar'),
            ],
          );
          return box.maxWidth > 650
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 18),
                    Expanded(child: right),
                  ],
                )
              : Column(children: [left, right]);
        },
      ),
      const SizedBox(height: 8),
      Text(
        'Social media',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      _field('instagram_url'),
      _field('facebook_url'),
      _field('tiktok_url'),
    ],
  );

  Widget _catering() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Events portfolio',
        'Refresh these photos as Meerath completes stronger events and catering work.',
      ),
      _image(
        'catering_hero_url',
        'Use your strongest wide event, restaurant setup or live BBQ photo.',
      ),
      Text(
        'Portfolio gallery',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 12),
      for (var i = 1; i <= 6; i++)
        _image(
          'catering_gallery_${i}_url',
          'Real event photo $i. Landscape images work best.',
        ),
    ],
  );

  Widget _featured() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _heading(
        'Featured dishes',
        'Choose up to six menu items for the homepage. Selection order is display order.',
      ),
      const _InfoNote(
        icon: Icons.tips_and_updates_outlined,
        text:
            'Leave everything unchecked to automatically show the first six published menu items.',
      ),
      const SizedBox(height: 12),
      for (final id
          in _selected
              .where((id) => !_items.any((item) => item['id'] == id))
              .toList())
        ListTile(
          title: const Text('A previously selected dish was removed'),
          trailing: IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: () => setState(() {
              _selected.remove(id);
              _dirty = true;
            }),
          ),
        ),
      for (final item in _items)
        Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: CheckboxListTile(
            title: Text(item['name_en'] as String? ?? ''),
            subtitle: Text(
              '${item['status']} ${_selected.contains(item['id']) ? '• Position ${_selected.indexOf(item['id'] as String) + 1}' : ''}',
            ),
            value: _selected.contains(item['id']),
            onChanged: (value) {
              final id = item['id'] as String;
              if (value == true && _selected.length >= 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('You can feature up to six dishes.'),
                  ),
                );
                return;
              }
              setState(() {
                value == true ? _selected.add(id) : _selected.remove(id);
                _dirty = true;
              });
            },
          ),
        ),
    ],
  );

  Widget _content() => switch (_section) {
    0 => _announcement(),
    1 => _homepage(),
    2 => _contact(),
    3 => _catering(),
    _ => _featured(),
  };

  Future<void> _save() async {
    if (!_loaded || !_form.currentState!.validate()) return;
    if (_announcementEnabled &&
        _fields['announcement_en']!.text.trim().isEmpty &&
        _fields['announcement_ar']!.text.trim().isEmpty) {
      setState(() {
        _section = 0;
        _error =
            'Add an English or Arabic announcement before switching it on.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final content = <String, dynamic>{..._original};
      for (final entry in _fields.entries) {
        content[entry.key] = entry.value.text.trim();
      }
      content['announcement_enabled'] = _announcementEnabled;
      content['featured_ids'] = _selected;
      final revision = await _repo.save(content, _revision);
      if (!mounted) return;
      setState(() {
        _original = content;
        _revision = revision;
        _dirty = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Website published successfully.')),
      );
    } catch (e) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _validate(String key, String? value) {
    final text = (value ?? '').trim();
    if (text.isEmpty) return null;
    if (key.endsWith('_url')) {
      final url = Uri.tryParse(text);
      if (url == null ||
          url.scheme != 'https' ||
          url.host.isEmpty ||
          url.userInfo.isNotEmpty ||
          RegExp(r'\s').hasMatch(text)) {
        return 'Enter a complete https:// link';
      }
    }
    if (key == 'phone' && !RegExp(r'^\+[1-9][0-9]{7,14}$').hasMatch(text)) {
      return 'Use format +966561663119';
    }
    if (key == 'whatsapp' && !RegExp(r'^[1-9][0-9]{7,14}$').hasMatch(text)) {
      return 'Use digits such as 966561663119';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1080, maxHeight: 850),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 18, 16, 14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.language),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Website control centre',
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Only the settings your team may update regularly',
                        ),
                      ],
                    ),
                  ),
                  if (_dirty)
                    const Chip(
                      avatar: Icon(Icons.circle, size: 9),
                      label: Text('Unsaved'),
                    ),
                  IconButton(
                    onPressed: _busy ? null : _close,
                    tooltip: 'Close',
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else
              Expanded(
                child: AbsorbPointer(
                  absorbing: _busy,
                  child: Form(
                    key: _form,
                    child: LayoutBuilder(
                      builder: (context, box) {
                        final desktop = box.maxWidth >= 820;
                        final navigation = ListView.separated(
                          padding: const EdgeInsets.all(14),
                          itemCount: sections.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 6),
                          itemBuilder: (context, index) {
                            final section = sections[index];
                            return ListTile(
                              selected: _section == index,
                              selectedTileColor: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              leading: Icon(section.$1),
                              title: Text(
                                section.$2,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: desktop
                                  ? Text(section.$3, maxLines: 2)
                                  : null,
                              onTap: () => setState(() => _section = index),
                            );
                          },
                        );
                        final body = SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              if (_error != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 16),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.errorContainer,
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: Text(_error!),
                                ),
                              _content(),
                            ],
                          ),
                        );
                        if (desktop) {
                          return Row(
                            children: [
                              SizedBox(width: 270, child: navigation),
                              const VerticalDivider(width: 1),
                              Expanded(child: body),
                            ],
                          );
                        }
                        return Column(
                          children: [
                            SizedBox(
                              height: 72,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                padding: const EdgeInsets.all(10),
                                itemCount: sections.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, i) => ChoiceChip(
                                  avatar: Icon(sections[i].$1, size: 18),
                                  label: Text(sections[i].$2),
                                  selected: _section == i,
                                  onSelected: (_) =>
                                      setState(() => _section = i),
                                ),
                              ),
                            ),
                            Expanded(child: body),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _dirty
                          ? 'Changes are not live yet'
                          : 'Website settings are up to date',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.only(right: 14),
                      child: SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  TextButton(
                    onPressed: _busy ? null : _close,
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 10),
                  if (!_loading && !_loaded)
                    OutlinedButton(
                      onPressed: _busy ? null : _load,
                      child: const Text('Retry'),
                    )
                  else
                    FilledButton.icon(
                      onPressed: !_loaded || _busy || !_dirty ? null : _save,
                      icon: const Icon(Icons.publish_outlined),
                      label: const Text('Save & publish'),
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

class _InfoNote extends StatelessWidget {
  const _InfoNote({required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      children: [
        Icon(icon, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(text)),
      ],
    ),
  );
}
