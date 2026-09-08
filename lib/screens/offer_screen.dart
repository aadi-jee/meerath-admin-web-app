import 'dart:async';
import 'package:flutter/material.dart';
import '../data/menu_repository.dart';
import '../data/mock_data.dart';
import '../data/offer_rules.dart';

class OfferScreen extends StatefulWidget {
  const OfferScreen({super.key, required this.onEdit});
  final ValueChanged<MenuItemData> onEdit;
  @override
  State<OfferScreen> createState() => _OfferScreenState();
}

class _OfferScreenState extends State<OfferScreen> {
  final _repository = MenuRepository();
  List<MenuItemData> _offers = [];
  bool _loading = true;
  bool _busy = false;
  String? _error;
  OfferStatus? _filter;
  Timer? _clock;

  @override
  void initState() {
    super.initState();
    _loadOffers();
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {}); // Refresh date-derived status at midnight.
    });
  }

  @override
  void dispose() {
    _clock?.cancel();
    super.dispose();
  }

  Future<bool> _loadOffers() async {
    setState(() { _loading = true; _error = null; });
    try {
      final offers = await _repository.loadOffers();
      if (!mounted) return false;
      setState(() => _offers = offers);
      return true;
    } catch (error) {
      if (mounted) setState(() => _error = MenuRepository.errorMessage(error));
      return false;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _message(String message) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _refresh() async {
    if (_busy || _loading) return;
    if (await _loadOffers()) _message('Offers refreshed.');
  }

  Future<void> _change(Future<void> Function() action, String success) async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      await action();
      if (!mounted) return;
      final refreshed = await _loadOffers();
      _message(refreshed ? success : 'Change saved. Refresh to load the latest offers.');
    } catch (error) {
      _message(MenuRepository.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _delete(MenuItemData item) async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('Delete offer?'),
      content: Text('Remove the offer for ${item.name}? The food item stays in your menu.'),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
        TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete offer')),
      ],
    ));
    if (confirmed == true && mounted) {
      await _change(() => _repository.removeOffer(item.id), 'Offer deleted. Menu item kept.');
    }
  }

  // An offer belongs to an existing food item; creation never creates a blank dish.
  Future<void> _create() async {
    if (_busy || _loading) return;
    setState(() => _busy = true);
    try {
      final items = (await _repository.loadDisplayItems()).where((i) => !i.hasOffer).toList();
      if (!mounted) return;
      if (items.isEmpty) {
        _message('No items without an offer. Add a menu item first or edit an existing offer.');
        return;
      }
      final item = await showDialog<MenuItemData>(context: context, builder: (context) => SimpleDialog(
        title: const Text('Choose a menu item'),
        children: [for (final item in items) SimpleDialogOption(
          onPressed: () => Navigator.pop(context, item),
          child: Text('${item.name} · SAR ${item.price.toStringAsFixed(2)}'),
        )],
      ));
      if (item != null && mounted) widget.onEdit(item);
    } catch (error) {
      _message(MenuRepository.errorMessage(error));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  OfferStatus _status(MenuItemData item) => OfferRules.status(
    enabled: item.offerActive, price: item.price, discount: item.offerDiscount,
    type: item.offerType, from: item.offerValidFrom, to: item.offerValidTo,
  );

  Color _color(OfferStatus status) => switch (status) {
    OfferStatus.active => Colors.green, OfferStatus.disabled => Colors.grey,
    OfferStatus.scheduled => Colors.lightBlue, OfferStatus.expired => Colors.redAccent,
    OfferStatus.invalid => Colors.orange,
  };

  @override
  Widget build(BuildContext context) {
    final visible = _offers.where((i) => _filter == null || _status(i) == _filter).toList();
    final active = _offers.where((i) => _status(i) == OfferStatus.active).length;
    final locked = _loading || _busy;
    return ListView(padding: const EdgeInsets.all(24), children: [
      Wrap(alignment: WrapAlignment.spaceBetween, crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 16, runSpacing: 12, children: [
          const Text('Offers & Flash Deals', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          Row(mainAxisSize: MainAxisSize.min, children: [
            FilledButton.icon(onPressed: locked ? null : _create,
              icon: const Icon(Icons.add), label: const Text('Create Offer')),
            IconButton(onPressed: locked ? null : _refresh,
              tooltip: 'Refresh offers', icon: const Icon(Icons.refresh)),
          ]),
        ]),
      const SizedBox(height: 10),
      Text('${_offers.length} offers · $active active by date'),
      const SizedBox(height: 6),
      const Text('Saudi dates · End date includes the full day. Customer visibility also depends on item and branch availability.',
        style: TextStyle(color: Colors.grey, fontSize: 12)),
      const SizedBox(height: 16),
      Wrap(spacing: 8, runSpacing: 8, children: [
        ChoiceChip(label: const Text('All'), selected: _filter == null,
          onSelected: (_) => setState(() => _filter = null)),
        for (final status in OfferStatus.values)
          ChoiceChip(label: Text(OfferRules.label(status)), selected: _filter == status,
            onSelected: (_) => setState(() => _filter = status)),
      ]),
      const SizedBox(height: 16),
      if (locked) const LinearProgressIndicator(),
      if (_error != null) Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_error!, style: const TextStyle(color: Colors.redAccent)),
          TextButton(onPressed: locked ? null : _refresh, child: const Text('Retry')),
        ],
      )),
      if (!locked && _error == null && visible.isEmpty)
        const Padding(padding: EdgeInsets.all(32), child: Text('No offers in this view.')),
      for (final item in visible) _offerCard(item, locked),
    ]);
  }

  Widget _offerCard(MenuItemData item, bool locked) {
    final status = _status(item);
    final color = _color(status);
    final valid = status != OfferStatus.invalid;
    final discount = item.offerDiscount;
    final discounted = valid && discount != null
      ? (item.offerType == 'percentage' ? item.price * (1 - discount / 100) : item.price - discount)
      : null;
    final toggleAllowed = item.offerActive || (status != OfferStatus.expired && valid);
    return Card(margin: const EdgeInsets.only(top: 12), child: Padding(
      padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(item.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
          PopupMenuButton<String>(enabled: !locked, tooltip: 'Offer actions',
            onSelected: (value) { if (value == 'edit') { widget.onEdit(item); } else { _delete(item); } },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit offer')),
              PopupMenuItem(value: 'delete', child: Text('Delete offer')),
            ]),
        ]),
        if (item.description.isNotEmpty) Text(item.description),
        const SizedBox(height: 10),
        Wrap(spacing: 16, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text(OfferRules.label(status), style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          Text('${OfferRules.formatDate(item.offerValidFrom)} → ${OfferRules.formatDate(item.offerValidTo)}'),
          if (discount != null && discount.isFinite)
            Text(item.offerType == 'percentage' ? '${discount.toStringAsFixed(2)}% off' : 'SAR ${discount.toStringAsFixed(2)} off'),
          if (discounted != null)
            Text('Base SAR ${item.price.toStringAsFixed(2)} → SAR ${discounted.toStringAsFixed(2)} with offer'),
        ]),
        if (status == OfferStatus.expired || status == OfferStatus.invalid)
          const Padding(padding: EdgeInsets.only(top: 8), child: Text('Edit the offer settings before enabling it.')),
        Row(children: [
          const Expanded(child: Text('Offer enabled')),
          Switch(value: item.offerActive, onChanged: locked || !toggleAllowed ? null : (enabled) =>
            _change(() => _repository.setOfferEnabled(item.id, enabled), enabled ? 'Offer enabled.' : 'Offer disabled.')),
        ]),
      ]),
    ));
  }
}
