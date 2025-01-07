import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';
import 'dart:convert';
import '../../components/app_bar/custom_app_bar.dart';
import '../../components/card/custom_card.dart';
import '../../config/config.dart';

class StoreStatisticsScreen extends StatefulWidget {
  final int storeId;

  const StoreStatisticsScreen({super.key, required this.storeId});

  @override
  State<StoreStatisticsScreen> createState() => _StoreStatisticsScreenState();
}

class _StoreStatisticsScreenState extends State<StoreStatisticsScreen> {
  Map<String, dynamic> statistics = {};
  bool isLoading = true;
  String error = '';

  @override
  void initState() {
    super.initState();
    _fetchStatistics();
  }

  Future<void> _fetchStatistics() async {
    try {
      setState(() {
        isLoading = true;
        error = '';
      });

      final apiUrl = '${Config.baseurl}/foods/statistics/${widget.storeId}';
      print('Fetching statistics from: $apiUrl');

      final response = await http.get(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*'
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw TimeoutException('Connection timed out');
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          statistics = data;
          isLoading = false;
        });
      } else {
        setState(() {
          error = 'Server error: ${response.statusCode}';
          isLoading = false;
        });
      }
    } on TimeoutException {
      if (!mounted) return;
      setState(() {
        error = 'Connection timed out. Please try again.';
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      print('Error fetching statistics: $e');
      setState(() {
        error = 'Network error: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Monthly Statistics'),
      body: RefreshIndicator(
        onRefresh: _fetchStatistics,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error.isNotEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(error),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchStatistics,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildOverallStats(),
                        const SizedBox(height: 20),
                        _buildOrderFrequencyChart(),
                        const SizedBox(height: 20),
                        _buildPopularItems(),
                        const SizedBox(height: 20),
                        _buildMonthlyDetails(),
                      ],
                    ),
                  ),
      ),
    );
  }

  Widget _buildOverallStats() {
    final overallStats = statistics['overall_statistics'] ?? {};
    // Divide by 1000 to compensate for the multiplication in _parseNumber
    final totalRevenue = _parseNumber(overallStats['total_revenue']) / 1000;
    final shopRevenue = (totalRevenue * 0.7).floorToDouble();

    return CustomCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overall Statistics',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Completed Orders',
                  overallStats['total_completed']?.toString() ?? '0',
                  Icons.check_circle,
                  Colors.green,
                ),
                _buildStatItem(
                  'Cancelled Orders',
                  overallStats['total_cancelled']?.toString() ?? '0',
                  Icons.cancel,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Revenue: ${_formatCurrency(totalRevenue)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Shop Revenue (70%): ${_formatCurrency(shopRevenue)}',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(
      String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  // Add this new method
  Widget _buildOrderFrequencyChart() {
    final popularItems = statistics['popular_items'] as List? ?? [];
    if (popularItems.isEmpty) return const SizedBox();

    // Calculate maxY safely by converting string values to double
    final maxY = popularItems
        .map<double>((item) => double.parse((item['total_sold'] ?? '0').toString()))
        .reduce((a, b) => a > b ? a : b) * 1.2;

    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Order Frequency by Item',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          SizedBox(
            height: 300,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value < 0 || value >= popularItems.length) {
                          return const SizedBox();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: RotatedBox(
                            quarterTurns: 1,
                            child: Text(
                              popularItems[value.toInt()]['name'] ?? '',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        );
                      },
                      reservedSize: 60,
                    ),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                borderData: FlBorderData(
                  show: true,
                ),
                barGroups: List.generate(
                  popularItems.length,
                  (index) => BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: double.parse((popularItems[index]['total_sold'] ?? '0').toString()),
                        color: Theme.of(context).primaryColor,
                        width: 20,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Update the number parsing method to handle different number formats
  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num)
      return value.toDouble() * 1000; // Multiply by 1000 for VND
    if (value is String) {
      // Remove commas and any currency symbols before parsing
      String cleanValue = value.replaceAll(RegExp(r'[^\d.]'), '');
      return (double.tryParse(cleanValue) ?? 0.0) *
          1000; // Multiply by 1000 for VND
    }
    return 0.0;
  }

  String _formatCurrency(dynamic value) {
    final number = _parseNumber(value);
    // Format with comma separators for thousands, remove decimal places
    final formatted = number.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    return '$formatted VND';
  }

  Widget _buildPopularItems() {
    final popularItems = statistics['popular_items'] as List? ?? [];
    return CustomCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Popular Items',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (popularItems.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('No data available'),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: popularItems.length,
              itemBuilder: (context, index) {
                final item = popularItems[index];
                return ListTile(
                  title: Text(item['name'] ?? ''),
                  subtitle: Text('Sold: ${item['total_sold'] ?? 0}'),
                  trailing: Text(
                    _formatCurrency(item['total_revenue']),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMonthlyDetails() {
    final monthlyStats = statistics['monthly_statistics'] as List? ?? [];
    if (monthlyStats.isEmpty) {
      return const CustomCard(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Text('No monthly statistics available'),
        ),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: monthlyStats.length,
      itemBuilder: (context, index) {
        final stat = monthlyStats[index];
        // Divide by 1000 to compensate for the multiplication in _parseNumber
        final totalRevenue = _parseNumber(stat['completed_revenue']) / 1000;
        final shopRevenue = (totalRevenue * 0.7).floorToDouble();
        final averageOrder = _parseNumber(stat['average_order_value']) / 1000;

        return CustomCard(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Month: ${stat['month'] ?? 'N/A'}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text('Total Orders: ${stat['total_orders'] ?? 0}'),
                Text('Completed Orders: ${stat['completed_orders'] ?? 0}'),
                Text('Cancelled Orders: ${stat['cancelled_orders'] ?? 0}'),
                Text('Total Items: ${stat['total_items'] ?? 0}'),
                Text('Average Order: ${_formatCurrency(averageOrder)}'),
                Text(
                  'Total Revenue: ${_formatCurrency(totalRevenue)}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  'Shop Revenue (70%): ${_formatCurrency(shopRevenue)}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
