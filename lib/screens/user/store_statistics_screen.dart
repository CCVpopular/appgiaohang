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
                        _buildRevenueChart(),
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
              'Total Revenue: \$${_formatNumber(overallStats['total_revenue'])}',
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

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(value, style: Theme.of(context).textTheme.titleLarge),
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }

  Widget _buildRevenueChart() {
    final monthlyStats = statistics['monthly_statistics'] as List? ?? [];
    if (monthlyStats.isEmpty) return const SizedBox();

    final revenueData = monthlyStats.take(6).map((stat) {
      // Safely convert total_revenue to double
      final revenue = _parseNumber(stat['total_revenue']);
      return FlSpot(
        monthlyStats.indexOf(stat).toDouble(),
        revenue,
      );
    }).toList();

    return CustomCard(
      child: SizedBox(
        height: 200,
        child: LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: true),
            lineBarsData: [
              LineChartBarData(
                spots: revenueData,
                isCurved: true,
                color: Theme.of(context).primaryColor,
                barWidth: 3,
                dotData: FlDotData(show: true),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Add this helper method for parsing numbers
  double _parseNumber(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? 0.0;
    }
    return 0.0;
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
                    '\$${_formatNumber(item['total_revenue'])}',
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
                Text('Average Order: \$${_formatNumber(stat['average_order_value'])}'),
                Text(
                  'Revenue: \$${_formatNumber(stat['completed_revenue'])}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatNumber(dynamic value) {
    return _parseNumber(value).toStringAsFixed(2);
  }
}
