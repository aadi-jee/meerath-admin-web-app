import 'package:flutter/material.dart';

import '../data/mock_data.dart';
import '../theme/app_colors.dart';
import '../widgets/charts.dart';
import '../widgets/ui_bits.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;

        final fourKpis = width >= 980;
        final splitSales = width >= 980;
        final splitLists = width >= 900;

        return ListView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          children: [
            const Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Live overview of today’s restaurant performance.',
              style: TextStyle(
                color: AppColors.textMuted,
                fontSize: 14,
              ),
            ),

            const SizedBox(height: 22),

            // KPI CARDS
            if (fourKpis)
              Row(
                children: [
                  for (var i = 0; i < MockData.kpis.length; i++) ...[
                    Expanded(
                      child: SizedBox(
                        height: 160,
                        child: _CompactKpi(data: MockData.kpis[i]),
                      ),
                    ),
                    if (i != MockData.kpis.length - 1)
                      const SizedBox(width: 12),
                  ],
                ],
              )
            else
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: width >= 620 ? 2 : 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: width >= 620 ? 2.35 : 3.2,
                children: [
                  for (final data in MockData.kpis)
                    _CompactKpi(data: data),
                ],
              ),

            const SizedBox(height: 16),

            // SALES
            if (splitSales)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 7,
                    child: _SalesOverview(),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    flex: 5,
                    child: _SalesBySource(),
                  ),
                ],
              )
            else ...[
              const _SalesOverview(),
              const SizedBox(height: 16),
              const _SalesBySource(),
            ],

            const SizedBox(height: 16),

            // TOP ITEMS + ORDERS
            if (splitLists)
              const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _TopItems()),
                  SizedBox(width: 16),
                  Expanded(child: _RecentOrders()),
                ],
              )
            else ...[
              const _TopItems(),
              const SizedBox(height: 16),
              const _RecentOrders(),
            ],

            const SizedBox(height: 16),

            const _OperationsPanel(),

            const SizedBox(height: 16),

            const _ActivePromotions(),

            const SizedBox(height: 26),

            const Center(
              child: Text(
                '© MEERATH Restaurant',
                style: TextStyle(
                  color: AppColors.textDim,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactKpi extends StatelessWidget {
  const _CompactKpi({required this.data});

  final KpiData data;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  data.icon,
                  color: AppColors.accent,
                  size: 19,
                ),
              ),
              const Spacer(),
              Text(
                data.trend,
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            data.label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            data.value,
            style: const TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const Spacer(),
          SizedBox(
            height: 24,
            width: double.infinity,
            child: CustomPaint(
              painter: SparklinePainter(
                values: data.sparkline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SalesOverview extends StatelessWidget {
  const _SalesOverview();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sales Overview',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    'Last 7 days',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Spacer(),
              Text(
                'SAR 52,310',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: BarChartPainter(
                values: MockData.salesLast7Days
                    .map((e) => e.$2)
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (final day in MockData.salesLast7Days)
                Expanded(
                  child: Text(
                    day.$1.replaceAll('May ', ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SalesBySource extends StatelessWidget {
  const _SalesBySource();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sales by Source',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Where today’s sales are coming from',
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 20),

          Row(
            children: [
              SizedBox(
                width: 118,
                height: 118,
                child: CustomPaint(
                  painter: DonutPainter(
                    slices: [
                      for (final source in MockData.salesBySource)
                        (source.$2, source.$3),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 22),
              Expanded(
                child: Column(
                  children: [
                    for (final source in MockData.salesBySource)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: source.$3,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                source.$1,
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Text(
                              '${(source.$2 * 100).round()}%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TopItems extends StatelessWidget {
  const _TopItems();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Top Selling Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'Today',
                style: TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          for (final item in MockData.topItems)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  FoodThumb(
                    color: item.$4,
                    radius: 10,
                    size: 42,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item.$3,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    item.$2,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentOrders extends StatelessWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Recent Orders',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'View all',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          for (final order in MockData.recentOrders)
            Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              order.source,
                              style: const TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${order.customer} · ${order.items}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [
                      Text(
                        'SAR ${order.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      StatusChip(label: order.status),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _OperationsPanel extends StatelessWidget {
  const _OperationsPanel();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final split = constraints.maxWidth >= 720;

          final actions = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _QuickAction(
                    icon: Icons.add_circle_outline,
                    label: 'Add New Item',
                  ),
                  _QuickAction(
                    icon: Icons.local_offer_outlined,
                    label: 'Create Offer',
                  ),
                  _QuickAction(
                    icon: Icons.visibility_off_outlined,
                    label: 'Mark Unavailable',
                  ),
                  _QuickAction(
                    icon: Icons.notifications_none_rounded,
                    label: 'Send Notification',
                  ),
                ],
              ),
            ],
          );

          final alerts = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Menu Alerts',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 14),
              _AlertRow(
                text: 'Beef Pulao is running low',
                detail: 'Only 8 portions remaining',
                danger: false,
              ),
              SizedBox(height: 12),
              _AlertRow(
                text: 'Halwa Puri unavailable',
                detail: 'Currently hidden from customers',
                danger: true,
              ),
              SizedBox(height: 12),
              _AlertRow(
                text: 'Rahu Fish stock is low',
                detail: '42 portions available',
                danger: false,
              ),
            ],
          );

          if (!split) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                actions,
                const SizedBox(height: 24),
                const Divider(color: AppColors.border),
                const SizedBox(height: 20),
                alerts,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: actions),
              const SizedBox(width: 32),
              Container(
                width: 1,
                height: 155,
                color: AppColors.border,
              ),
              const SizedBox(width: 32),
              Expanded(child: alerts),
            ],
          );
        },
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.accent,
            size: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({
    required this.text,
    required this.detail,
    required this.danger,
  });

  final String text;
  final String detail;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color =
        danger ? AppColors.danger : AppColors.warning;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          danger
              ? Icons.error_outline_rounded
              : Icons.warning_amber_rounded,
          color: color,
          size: 19,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivePromotions extends StatelessWidget {
  const _ActivePromotions();

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Text(
                'Active Promotions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Spacer(),
              Text(
                'Manage offers',
                style: TextStyle(
                  color: AppColors.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _PromoCard(
                title: 'Biryani Flash Deal',
                detail: '20% OFF · 7 PM–10 PM',
                status: 'Live',
              ),
              _PromoCard(
                title: 'Weekend Family Offer',
                detail: '15% OFF family orders',
                status: 'Live',
              ),
              _PromoCard(
                title: 'New Customer Offer',
                detail: 'SAR 10 welcome discount',
                status: 'Scheduled',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  const _PromoCard({
    required this.title,
    required this.detail,
    required this.status,
  });

  final String title;
  final String detail;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_offer_outlined,
              color: AppColors.accent,
              size: 18,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          StatusChip(label: status),
        ],
      ),
    );
  }
}