import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_header.dart';
import 'dashboard_screen.dart';
import 'menu_item_form_screen.dart';
import 'menu_screen.dart';
import 'placeholder_screen.dart';
import 'offer_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;
  bool _showMenuForm = false;
  MenuItemData? _editingItem;
  int _formInitialTab = 0;
  int _formReturnIndex = 1;
  bool _formSaving = false;
  bool _navigationPending = false;
  bool _drawerOpen = false;
  GlobalKey<MenuItemFormScreenState> _formKey = GlobalKey<MenuItemFormScreenState>();

  bool get _locked => _formSaving || _navigationPending;

  void _openMenuForm([MenuItemData? item]) => _openForm(item, offers: false);
  void _openOfferForm(MenuItemData item) => _openForm(item, offers: true);

  void _openForm(MenuItemData? item, {required bool offers}) {
    if (_locked || _showMenuForm) return;
    setState(() {
      _formReturnIndex = offers ? 2 : 1;
      _navIndex = _formReturnIndex;
      _formInitialTab = offers ? 5 : 0;
      _editingItem = item;
      _formKey = GlobalKey<MenuItemFormScreenState>();
      _showMenuForm = true;
    });
  }

  // All sidebar and form-cancel navigation shares the same exit check.
  Future<void> _selectSection(int index) async {
    if (index < 0 || index > 7 || _locked) return;
    if (!_showMenuForm && index == _navIndex) return;
    setState(() => _navigationPending = true);
    try {
      if (_showMenuForm) {
        final form = _formKey.currentState;
        if (form == null || !await form.confirmLeave()) return;
      }
      if (!mounted) return;
      setState(() {
        _navIndex = index;
        _showMenuForm = false;
        _editingItem = null;
      });
    } finally {
      if (mounted) setState(() => _navigationPending = false);
    }
  }

  void _requestCloseForm() {
    _selectSection(_formReturnIndex);
  }

  // Successful save is distinct from Cancel: it must not show a discard dialog.
  void _onFormSaved() {
    if (!mounted) return;
    setState(() {
      _showMenuForm = false;
      _editingItem = null;
      _formSaving = false;
      _navIndex = _formReturnIndex;
    });
  }

  void _onSavingChanged(bool saving) {
    if (mounted && _formSaving != saving) setState(() => _formSaving = saving);
  }

  Future<void> _openSidebar() async {
    if (_locked || _drawerOpen) return;
    _drawerOpen = true;
    try {
      final selected = await showGeneralDialog<int>(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Menu',
        pageBuilder: (dialogContext, animation, secondary) => Align(
          alignment: Alignment.centerLeft,
          child: Material(
            color: AppColors.sidebar,
            child: SafeArea(child: SizedBox(
              width: 236,
              height: MediaQuery.of(dialogContext).size.height,
              child: AppSidebar(
                selectedIndex: _navIndex,
                onSelect: (index) => Navigator.pop(dialogContext, index),
              ),
            )),
          ),
        ),
      );
      if (mounted && selected != null) await _selectSection(selected);
    } finally {
      _drawerOpen = false;
    }
  }

  Widget _body() {
    if (_showMenuForm) {
      return MenuItemFormScreen(
        key: _formKey,
        item: _editingItem,
        initialTab: _formInitialTab,
        onBack: _requestCloseForm,
        onSaved: _onFormSaved,
        onSavingChanged: _onSavingChanged,
      );
    }
    switch (_navIndex) {
      case 0: return const DashboardScreen();
      case 1: return MenuScreen(onAdd: _openMenuForm, onEdit: _openMenuForm);
      case 2: return OfferScreen(onEdit: _openOfferForm);
      default:
        const placeholders = {
          3: ('Customers', 'Customer profiles and loyalty will be added later.'),
          4: ('App Content', 'Banners and home content tools will live here.'),
          5: ('Notifications', 'Push campaigns will be managed from this screen.'),
          6: ('Reports', 'Sales and operations reports will appear here.'),
          7: ('Settings', 'Restaurant, tax, and staff settings will appear here.'),
        };
        final data = placeholders[_navIndex];
        if (data == null) return const DashboardScreen();
        return PlaceholderScreen(title: data.$1, subtitle: data.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      canPop: !_showMenuForm && !_locked,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _showMenuForm && !_locked) _requestCloseForm();
      },
      child: Scaffold(
        backgroundColor: AppColors.scaffold,
        body: LayoutBuilder(builder: (context, constraints) {
          final compact = constraints.maxWidth < 1100;
          return ExcludeFocus(excluding: _locked, child: Row(children: [
            if (!compact)
              AbsorbPointer(absorbing: _locked, child: AppSidebar(
                selectedIndex: _navIndex,
                onSelect: _selectSection,
              )),
            Expanded(child: Column(children: [
              AbsorbPointer(absorbing: _locked, child: TopHeader(
                branchName: 'Meerath Riyadh',
                onMenuTap: compact ? _openSidebar : null,
              )),
              Expanded(child: AbsorbPointer(absorbing: _locked, child: _body())),
            ])),
          ]));
        }),
      ),
    );
  }
}
