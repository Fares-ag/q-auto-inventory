import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/firestore_models.dart';
import '../../services/firebase_services.dart';
import '../../theme/app_theme.dart';
import '../../widgets/skeleton_list.dart';
import '../../widgets/error_retry_widget.dart';
import '../../widgets/network_error_widget.dart';
import '../../utils/network_utils.dart';
import '../items/items_screen.dart';
import '../items/all_items_screen.dart';

/// Dedicated Finance Portal Dashboard
/// Shows financial metrics, asset values, and finance-specific insights
class FinanceDashboardScreen extends StatefulWidget {
  const FinanceDashboardScreen({super.key});

  @override
  State<FinanceDashboardScreen> createState() => _FinanceDashboardScreenState();
}

class _FinanceDashboardScreenState extends State<FinanceDashboardScreen> {
  Future<_FinanceData>? _dashboardFuture;

  @override
  void initState() {
    super.initState();
    // Defer data loading to next frame to show UI immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _dashboardFuture = _loadFinanceData();
        });
      }
    });
  }

  Future<_FinanceData> _loadFinanceData() async {
    final catalog = context.read<CatalogService>();
    
    // Load items for financial analysis
    final items = await catalog.listAllItems(pageSize: 1000);
    
    // Calculate financial metrics
    double totalPurchaseValue = 0;
    double totalCurrentValue = 0;
    int itemsWithCosts = 0;
    int itemsWithoutAssetNumber = 0;
    int itemsNeedingSAPCodes = 0;
    final departmentValues = <String, double>{};
    final categoryValues = <String, double>{};
    
    for (final item in items) {
      // Purchase value
      if (item.purchasePrice != null) {
        totalPurchaseValue += item.purchasePrice!;
        itemsWithCosts++;
      }
      
      // Current value (from customFields or direct field)
      final currentVal = (item.customFields?['currentValue'] as num?)?.toDouble();
      if (currentVal != null && currentVal > 0) {
        totalCurrentValue += currentVal;
      }
      
      // Asset number check
      if (item.assetNumber == null || item.assetNumber!.isEmpty) {
        itemsWithoutAssetNumber++;
      }
      
      // SAP codes check
      if (item.coCd == null || item.coCd!.isEmpty ||
          item.sapClass == null || item.sapClass!.isEmpty ||
          item.apcAccount == null || item.apcAccount!.isEmpty) {
        itemsNeedingSAPCodes++;
      }
      
      // Department values
      if (item.purchasePrice != null && item.departmentId.isNotEmpty) {
        departmentValues.update(
          item.departmentId,
          (value) => value + item.purchasePrice!,
          ifAbsent: () => item.purchasePrice!,
        );
      }
      
      // Category values
      if (item.purchasePrice != null && item.categoryId.isNotEmpty) {
        categoryValues.update(
          item.categoryId,
          (value) => value + item.purchasePrice!,
          ifAbsent: () => item.purchasePrice!,
        );
      }
    }
    
    final depreciation = totalPurchaseValue - totalCurrentValue;
    final depreciationPercent = totalPurchaseValue > 0
        ? (depreciation / totalPurchaseValue * 100)
        : 0.0;
    
    return _FinanceData(
      totalItems: items.length,
      totalPurchaseValue: totalPurchaseValue,
      totalCurrentValue: totalCurrentValue,
      depreciation: depreciation,
      depreciationPercent: depreciationPercent,
      itemsWithCosts: itemsWithCosts,
      itemsWithoutAssetNumber: itemsWithoutAssetNumber,
      itemsNeedingSAPCodes: itemsNeedingSAPCodes,
      departmentValues: departmentValues,
      categoryValues: categoryValues,
      items: items,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<_FinanceData>(
        future: _dashboardFuture ?? Future.value(const _FinanceData.empty()),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: SkeletonList(itemCount: 10, itemHeight: 72),
            );
          }
          if (snapshot.hasError) {
            final error = snapshot.error!;
            return NetworkUtils.isNetworkError(error)
                ? NetworkErrorWidget(
                    error: error,
                    onRetry: () {
                      setState(() {
                        _dashboardFuture = _loadFinanceData();
                      });
                    },
                  )
                : ErrorRetryWidget(
                    message: NetworkUtils.getErrorMessage(error),
                    onRetry: () {
                      setState(() {
                        _dashboardFuture = _loadFinanceData();
                      });
                    },
                  );
          }
          final data = snapshot.data ?? const _FinanceData.empty();
          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _dashboardFuture = _loadFinanceData();
              });
              await _dashboardFuture;
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Finance Portal',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: () {
                          setState(() {
                            _dashboardFuture = _loadFinanceData();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Financial Overview',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _FinancialMetricsGrid(data: data),
                  const SizedBox(height: 24),
                  Text(
                    'Financial Health',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _FinancialHealthCards(data: data),
                  const SizedBox(height: 24),
                  Text(
                    'Quick Actions',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _FinanceQuickActions(),
                  const SizedBox(height: 24),
                  if (data.departmentValues.isNotEmpty) ...[
                    Text(
                      'Asset Value by Department',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _DepartmentValueList(data: data),
                    const SizedBox(height: 24),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _FinancialMetricsGrid extends StatelessWidget {
  const _FinancialMetricsGrid({required this.data});

  final _FinanceData data;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatConfig(
        label: 'Total Purchase Value',
        value: _formatCurrency(data.totalPurchaseValue),
        icon: Icons.shopping_cart,
        color: AppTheme.primary,
      ),
      _StatConfig(
        label: 'Total Current Value',
        value: _formatCurrency(data.totalCurrentValue),
        icon: Icons.attach_money,
        color: AppTheme.secondary,
      ),
      _StatConfig(
        label: 'Depreciation',
        value: _formatCurrency(data.depreciation),
        icon: Icons.trending_down,
        color: AppTheme.error,
      ),
      _StatConfig(
        label: 'Depreciation %',
        value: '${data.depreciationPercent.toStringAsFixed(1)}%',
        icon: Icons.percent,
        color: AppTheme.warning,
      ),
    ];

    return GridView.builder(
      itemCount: stats.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, index) {
        final stat = stats[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(stat.icon, size: 32, color: stat.color),
                const SizedBox(height: 12),
                Text(
                  stat.value,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  stat.label,
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'QAR ${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return 'QAR ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'QAR ${value.toStringAsFixed(0)}';
  }
}

class _FinancialHealthCards extends StatelessWidget {
  const _FinancialHealthCards({required this.data});

  final _FinanceData data;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _HealthCard(
          title: 'Items Missing Asset Numbers',
          count: data.itemsWithoutAssetNumber,
          total: data.totalItems,
          icon: Icons.tag,
          color: data.itemsWithoutAssetNumber > 0
              ? AppTheme.warning
              : AppTheme.success,
          onTap: () {
            // Navigate to items filtered by missing asset numbers
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ItemsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _HealthCard(
          title: 'Items Needing SAP Codes',
          count: data.itemsNeedingSAPCodes,
          total: data.totalItems,
          icon: Icons.code,
          color: data.itemsNeedingSAPCodes > 0
              ? AppTheme.warning
              : AppTheme.success,
          onTap: () {
            // Navigate to items filtered by missing SAP codes
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ItemsScreen(),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _HealthCard(
          title: 'Items with Cost Data',
          count: data.itemsWithCosts,
          total: data.totalItems,
          icon: Icons.check_circle,
          color: AppTheme.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AllItemsScreen(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({
    required this.title,
    required this.count,
    required this.total,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final int count;
  final int total;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percentage = total > 0 ? (count / total * 100) : 0.0;
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$count of $total items (${percentage.toStringAsFixed(1)}%)',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8)),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _FinanceQuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _QuickAction(
          label: 'View All Items',
          icon: Icons.inventory_2,
          color: AppTheme.primary,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const AllItemsScreen(),
              ),
            );
          },
        ),
        _QuickAction(
          label: 'Items Missing Asset #',
          icon: Icons.tag_outlined,
          color: AppTheme.warning,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ItemsScreen(),
              ),
            );
          },
        ),
        _QuickAction(
          label: 'Items Missing SAP Codes',
          icon: Icons.code_outlined,
          color: AppTheme.error,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const ItemsScreen(),
              ),
            );
          },
        ),
        _QuickAction(
          label: 'Financial Reports',
          icon: Icons.description,
          color: AppTheme.secondary,
          onTap: () {
            // Navigate to reports hub
            Navigator.of(context).pushNamed('/reports');
          },
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width > 600
          ? 200
          : (MediaQuery.of(context).size.width - 52) / 2,
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, color: color),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _DepartmentValueList extends StatelessWidget {
  const _DepartmentValueList({required this.data});

  final _FinanceData data;

  @override
  Widget build(BuildContext context) {
    final sortedDepts = data.departmentValues.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children: sortedDepts.take(10).map((entry) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.apartment),
            title: Text(entry.key),
            trailing: Text(
              _formatCurrency(entry.value),
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatCurrency(double value) {
    if (value >= 1000000) {
      return 'QAR ${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value >= 1000) {
      return 'QAR ${(value / 1000).toStringAsFixed(1)}K';
    }
    return 'QAR ${value.toStringAsFixed(0)}';
  }
}

class _StatConfig {
  const _StatConfig({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
}

class _FinanceData {
  const _FinanceData({
    required this.totalItems,
    required this.totalPurchaseValue,
    required this.totalCurrentValue,
    required this.depreciation,
    required this.depreciationPercent,
    required this.itemsWithCosts,
    required this.itemsWithoutAssetNumber,
    required this.itemsNeedingSAPCodes,
    required this.departmentValues,
    required this.categoryValues,
    required this.items,
  });

  const _FinanceData.empty()
      : totalItems = 0,
        totalPurchaseValue = 0,
        totalCurrentValue = 0,
        depreciation = 0,
        depreciationPercent = 0,
        itemsWithCosts = 0,
        itemsWithoutAssetNumber = 0,
        itemsNeedingSAPCodes = 0,
        departmentValues = const {},
        categoryValues = const {},
        items = const [];

  final int totalItems;
  final double totalPurchaseValue;
  final double totalCurrentValue;
  final double depreciation;
  final double depreciationPercent;
  final int itemsWithCosts;
  final int itemsWithoutAssetNumber;
  final int itemsNeedingSAPCodes;
  final Map<String, double> departmentValues;
  final Map<String, double> categoryValues;
  final List<InventoryItem> items;
}

