import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/sidebar.dart';
import '../widgets/top_header.dart';
import 'dashboard_screen.dart';
import 'menu_item_form_screen.dart';
import 'menu_screen.dart';
import 'placeholder_screen.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _navIndex = 0;
  String _branch = MockData.branches.first;
  bool _showMenuForm = false;
  MenuItemData? _editingItem;

  void _openMenuForm([MenuItemData? item]) {
    setState(() {
      _navIndex = 1;
      _showMenuForm = true;
      _editingItem = item;
    });
  }

  void _closeMenuForm() {
    setState(() {
      _showMenuForm = false;
      _editingItem = null;
    });
  }

  Widget _body() {
    if (_navIndex == 0) return const DashboardScreen();
    if (_navIndex == 1) {
      if (_showMenuForm) {
        return MenuItemFormScreen(item: _editingItem, onBack: _closeMenuForm);
      }
      return MenuScreen(onAdd: _openMenuForm, onEdit: _openMenuForm);
    }

    const placeholders = {
      2: ('Offers', 'Offers & flash deals UI will be added in a later pass.'),
      3: ('Customers', 'Customer profiles and loyalty will be added later.'),
      4: ('App Content', 'Banners and home content tools will live here.'),
      5: ('Notifications', 'Push campaigns will be managed from this screen.'),
      6: ('Reports', 'Sales and operations reports will appear here.'),
      7: ('Settings', 'Restaurant, tax, and staff settings will appear here.'),
    };
    final data = placeholders[_navIndex]!;
    return PlaceholderScreen(title: data.$1, subtitle: data.$2);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scaffold,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 1100;
          return Row(
            children: [
              if (!compact)
                AppSidebar(
                  selectedIndex: _navIndex,
                  onSelect: (index) {
                    setState(() {
                      _navIndex = index;
                      if (index != 1) {
                        _showMenuForm = false;
                        _editingItem = null;
                      }
                    });
                  },
                ),
              Expanded(
                child: Column(
                  children: [
                    TopHeader(
                      branch: _branch,
                      onBranchChanged: (value) => setState(() => _branch = value),
                      onMenuTap: compact
                          ? () {
                              showGeneralDialog(
                                context: context,
                                barrierDismissible: true,
                                barrierLabel: 'Menu',
                                pageBuilder: (context, animation, secondary) {
                                  return Align(
                                    alignment: Alignment.centerLeft,
                                    child: Material(
                                      color: AppColors.sidebar,
                                      child: SizedBox(
                                        width: 236,
                                        height: MediaQuery.of(context).size.height,
                                        child: AppSidebar(
                                          selectedIndex: _navIndex,
                                          onSelect: (index) {
                                            Navigator.pop(context);
                                            setState(() {
                                              _navIndex = index;
                                              if (index != 1) {
                                                _showMenuForm = false;
                                                _editingItem = null;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              );
                            }
                          : null,
                    ),
                    Expanded(child: _body()),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
