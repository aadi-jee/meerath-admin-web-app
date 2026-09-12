import 'package:flutter/material.dart';
import '../data/channel_pricing_repository.dart';
import '../data/menu_repository.dart';
import '../data/channel_price_rules.dart';

class ChannelPricingScreen extends StatefulWidget {
  const ChannelPricingScreen({super.key});
  @override
  State<ChannelPricingScreen> createState() => _ChannelPricingScreenState();
}

class _ChannelPricingScreenState extends State<ChannelPricingScreen> {
  final _repo = ChannelPricingRepository();
  List<Map<String, dynamic>> _branches = [], _items = [], _prices = [];
  String? _branch, _error;
  String _channel = 'hungerStation', _search = '', _filter = 'All';
  bool _loading = true;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _loadBranches();
  }

  Future<void> _loadBranches() async {
    try {
      final branches = (await MenuRepository().loadBranches())
          .where((b) => b['is_active'] == true)
          .toList();
      if (!mounted) {
        return;
      }
      setState(() {
        _branches = branches;
        _branch = branches.isEmpty ? null : branches.first['id'] as String;
        _loading = false;
      });
      if (_branch != null) {
        await _load();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = MenuRepository.errorMessage(e);
        });
      }
    }
  }

  Future<void> _load() async {
    final branch = _branch;
    if (branch == null) {
      return;
    }
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
      _prices = [];
    });
    try {
      final result = await _repo.load(branch);
      if (!mounted || request != _request) {
        return;
      }
      setState(() {
        _items = (result['items'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _prices = (result['channel_prices'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
      });
    } catch (e) {
      if (mounted && request == _request) {
        setState(() => _error = MenuRepository.errorMessage(e));
      }
    } finally {
      if (mounted && request == _request) {
        setState(() => _loading = false);
      }
    }
  }

  Map<String, dynamic>? _priceFor(Map<String, dynamic> item) => _prices
      .where((p) => p['item_id'] == item['id'] && p['channel'] == _channel)
      .firstOrNull;

  String _status(Map<String, dynamic>? price) => price == null
      ? 'Not set'
      : price['options_current'] != true
      ? 'Review required'
      : price['is_available'] == true
      ? 'Available'
      : 'Unavailable';

  Future<void> _edit(Map<String, dynamic> item) async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PriceDialog(
        repo: _repo,
        branchId: _branch!,
        channel: _channel,
        item: item,
        existing: _priceFor(item),
      ),
    );
    if (changed == true && mounted) {
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = _items
        .where(
          (i) =>
              (i['name_en'] as String).toLowerCase().contains(
                _search.toLowerCase(),
              ) &&
              (_filter == 'All' || _status(_priceFor(i)) == _filter),
        )
        .toList();
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Channel Pricing',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Set platform prices for manual POS orders. Standard menu and Customer App prices stay separate.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              SizedBox(
                width: 200,
                child: DropdownButtonFormField<String>(
                  key: ValueKey('branch-$_branch'),
                  initialValue: _branch,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Branch'),
                  items: _branches
                      .map(
                        (b) => DropdownMenuItem(
                          value: b['id'] as String,
                          child: Text(
                            b['name'] as String,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _loading
                      ? null
                      : (v) {
                          setState(() => _branch = v);
                          _load();
                        },
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _channel,
                  decoration: const InputDecoration(labelText: 'Platform'),
                  items: salesChannels.entries
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.key,
                          child: Text(e.value),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _channel = v);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 190,
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items:
                      [
                            'All',
                            'Not set',
                            'Review required',
                            'Available',
                            'Unavailable',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _filter = v);
                    }
                  },
                ),
              ),
              SizedBox(
                width: 240,
                child: TextField(
                  onChanged: (v) => setState(() => _search = v),
                  decoration: const InputDecoration(
                    labelText: 'Search items',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh prices',
                onPressed: _loading
                    ? null
                    : () => _branch == null ? _loadBranches() : _load(),
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Only published items assigned to this branch are listed. All prices include VAT. Changes reach POS on Refresh or within about 30 seconds.',
          ),
          const SizedBox(height: 12),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(_error!, style: const TextStyle(color: Colors.red)),
            ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : visible.isEmpty
                ? const Center(
                    child: Text(
                      'No matching items. Check branch, publication and filters.',
                    ),
                  )
                : ListView.separated(
                    itemCount: visible.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = visible[index],
                          price = _priceFor(visible[index]);
                      final status = _status(price);
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        title: Text(item['name_en'] as String),
                        subtitle: Text(
                          'Standard SAR ${(item['price'] as num).toStringAsFixed(2)}  •  $status',
                        ),
                        trailing: TextButton(
                          onPressed: () => _edit(item),
                          child: Text(
                            price == null
                                ? 'Set price'
                                : 'SAR ${(price['price'] as num).toStringAsFixed(2)}  •  Edit',
                          ),
                        ),
                        onTap: () => _edit(item),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _PriceDialog extends StatefulWidget {
  const _PriceDialog({
    required this.repo,
    required this.branchId,
    required this.channel,
    required this.item,
    required this.existing,
  });
  final ChannelPricingRepository repo;
  final String branchId, channel;
  final Map<String, dynamic> item;
  final Map<String, dynamic>? existing;
  @override
  State<_PriceDialog> createState() => _PriceDialogState();
}

class _PriceDialogState extends State<_PriceDialog> {
  final _form = GlobalKey<FormState>();
  late final List<dynamic> _options = widget.item['options'] as List? ?? [];
  late final _price = TextEditingController(
    text: widget.existing == null
        ? ''
        : (widget.existing!['price'] as num).toStringAsFixed(2),
  );
  late final List<TextEditingController> _choices = List.generate(
    _options.length,
    (i) {
      final saved = widget.existing;
      final amount = saved != null && saved['options_current'] == true
          ? (saved['option_prices'] as List)[i]
          : _options[i]['price'];
      return TextEditingController(text: (amount as num).toStringAsFixed(2));
    },
  );
  final _markup = TextEditingController();
  late bool _available = widget.existing?['is_available'] as bool? ?? true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _price.dispose();
    _markup.dispose();
    for (final c in _choices) {
      c.dispose();
    }
    super.dispose();
  }

  String? _valid(String? text, double maximum) {
    if (ChannelPriceRules.money(text ?? '', maximum: maximum) == null) {
      return 'Enter 0–$maximum, up to 2 decimal places';
    }
    return null;
  }

  void _calculate() {
    final proposal = ChannelPriceRules.markup([
      widget.item['price'] as num,
      for (final o in _options) o['price'] as num,
    ], _markup.text);
    if (proposal == null) {
      setState(
        () => _error =
            'Enter 0–500%. Calculated prices must stay within the allowed limits.',
      );
      return;
    }
    _price.text = proposal.first.toStringAsFixed(2);
    for (var i = 0; i < _choices.length; i++) {
      _choices[i].text = proposal[i + 1].toStringAsFixed(2);
    }
    setState(() => _error = null);
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repo.save(
        branchId: widget.branchId,
        itemId: widget.item['id'] as String,
        channel: widget.channel,
        price: double.parse(_price.text.trim()),
        available: _available,
        choicePrices: _choices.map((c) => double.parse(c.text.trim())).toList(),
        expectedOptions: _options,
        expectedRevision: (widget.existing?['revision'] as num?)?.toInt() ?? 0,
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = MenuRepository.errorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        '${salesChannels[widget.channel]} • ${widget.item['name_en']}',
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Standard branch price: SAR ${(widget.item['price'] as num).toStringAsFixed(2)}',
                ),
                const SizedBox(height: 12),
                if (widget.existing?['options_current'] == false)
                  const Text(
                    'Item choices changed. Review all choice prices before saving.',
                    style: TextStyle(color: Colors.orange),
                  ),
                const Text(
                  'Optional calculator: applies a markup to the current standard item and choice prices. Review the result before saving.',
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _markup,
                        enabled: !_saving,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Markup %',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _saving ? null : _calculate,
                      child: const Text('Calculate'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _price,
                  enabled: !_saving,
                  validator: (v) => _valid(v, 9999999),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Platform item price (SAR, VAT included)',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available on this platform'),
                  value: _available,
                  onChanged: _saving
                      ? null
                      : (v) => setState(() => _available = v),
                ),
                if (_options.isNotEmpty)
                  const Text(
                    'Choices add to the item price. Disabled choices are stored for later use.',
                  ),
                for (var i = 0; i < _options.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: TextFormField(
                      controller: _choices[i],
                      enabled: !_saving,
                      validator: (v) => _valid(v, 99999.99),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText:
                            '${_options[i]['type']}: ${_options[i]['name']}',
                        helperText:
                            'Standard + SAR ${(_options[i]['price'] as num).toStringAsFixed(2)}',
                      ),
                    ),
                  ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save platform prices'),
        ),
      ],
    ),
  );
}
