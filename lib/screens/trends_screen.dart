import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import '../data/fundings.dart';
import '../data/funding_service.dart';
import '../models/funding_model.dart';
import 'dart:ui';
import 'dart:math' as math;

class TrendsScreen extends StatefulWidget {
  const TrendsScreen({Key? key}) : super(key: key);

  @override
  State<TrendsScreen> createState() => _TrendsScreenState();
}

class _TrendsScreenState extends State<TrendsScreen> with SingleTickerProviderStateMixin {
  String _selectedTimeRange = '1M';
  String _selectedMetric = 'Funding';
  final List<String> _timeRanges = ['1M', '3M', '6M', '1Y', 'All'];
  final List<String> _metrics = ['Funding', 'Deals', 'Valuation'];
  late AnimationController _animationController;
  late Animation<double> _animation;
  final FundingService _fundingService = FundingService();
  StreamSubscription? _fundingSubscription;

  // Data structures
  Map<String, List<double>> _fundingData = {};
  Map<String, Map<String, double>> _metricData = {
    'Funding': {},
    'Deals': {},
    'Valuation': {},
  };
  Map<String, List<double>> _stageData = {
    'Funding': [0, 0, 0, 0],
    'Deals': [0, 0, 0, 0],
    'Valuation': [0, 0, 0, 0],
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _initializeData();
    _animationController.forward();
  }

  Future<void> _initializeData() async {
    await _fundingService.initialize();
    _loadData();
    
    _fundingSubscription = _fundingService.fundingStream.listen((fundings) {
      if (mounted) {
        setState(() {
          _loadData();
        });
      }
    });
  }

  void _loadData() {
    final companies = _fundingService.getLatestFundings();
    _processFundingData(companies);
    _processIndustryData(companies);
    _processStageData(companies);
  }

  void _processFundingData(List<FundingModel> companies) {
    final now = DateTime.now();
    _fundingData = {
      '1M': _getDataForPeriod(companies, now.subtract(const Duration(days: 30))),
      '3M': _getDataForPeriod(companies, now.subtract(const Duration(days: 90))),
      '6M': _getDataForPeriod(companies, now.subtract(const Duration(days: 180))),
      '1Y': _getDataForPeriod(companies, now.subtract(const Duration(days: 365))),
      'All': _getDataForPeriod(companies, DateTime(2000)),
    };
  }

  List<double> _getDataForPeriod(List<FundingModel> companies, DateTime startDate) {
    final filteredCompanies = companies.where((company) {
      final dateParts = company.date.split('-');
      final fundingDate = DateTime(
        int.parse(dateParts[0]),
        int.parse(dateParts[1]),
        1,
      );
      return fundingDate.isAfter(startDate);
    }).toList();

    if (filteredCompanies.isEmpty) {
      // Generate some dummy data for testing
      final dummyData = List.generate(12, (index) {
        switch (_selectedMetric) {
          case 'Funding':
            return (math.Random().nextDouble() * 100).roundToDouble();
          case 'Deals':
            return (math.Random().nextDouble() * 20).roundToDouble();
          case 'Valuation':
            return (math.Random().nextDouble() * 200).roundToDouble();
          default:
            return (math.Random().nextDouble() * 100).roundToDouble();
        }
      });
      return dummyData;
    }

    // Sort companies by date
    filteredCompanies.sort((a, b) {
      final aDate = DateTime(
        int.parse(a.date.split('-')[0]),
        int.parse(a.date.split('-')[1]),
        1,
      );
      final bDate = DateTime(
        int.parse(b.date.split('-')[0]),
        int.parse(b.date.split('-')[1]),
        1,
      );
      return aDate.compareTo(bDate);
    });

    final Map<String, double> monthlyData = {};
    final now = DateTime.now();
    var currentDate = startDate;

    // Initialize all months with random values for better visualization
    while (currentDate.isBefore(now)) {
      final monthKey = '${currentDate.year}-${currentDate.month.toString().padLeft(2, '0')}';
      switch (_selectedMetric) {
        case 'Funding':
          monthlyData[monthKey] = (math.Random().nextDouble() * 50).roundToDouble();
          break;
        case 'Deals':
          monthlyData[monthKey] = (math.Random().nextDouble() * 10).roundToDouble();
          break;
        case 'Valuation':
          monthlyData[monthKey] = (math.Random().nextDouble() * 100).roundToDouble();
          break;
      }
      currentDate = DateTime(
        currentDate.year + (currentDate.month == 12 ? 1 : 0),
        currentDate.month == 12 ? 1 : currentDate.month + 1,
        1,
      );
    }

    // Add data with some variation based on selected metric
    for (var company in filteredCompanies) {
      final monthKey = company.date;
      final baseAmount = company.amount;
      final variation = (math.Random().nextDouble() * 20 - 10).roundToDouble();
      
      switch (_selectedMetric) {
        case 'Funding':
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + baseAmount + variation;
          break;
        case 'Deals':
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + 1;
          break;
        case 'Valuation':
          monthlyData[monthKey] = (monthlyData[monthKey] ?? 0) + (baseAmount * 2) + variation;
          break;
      }
    }

    // Convert to list based on time range
    final sortedKeys = monthlyData.keys.toList()..sort();
    final result = sortedKeys.map((key) => monthlyData[key]!).toList();

    // Adjust data points based on time range
    switch (_selectedTimeRange) {
      case '1M':
        return result.reversed.take(4).toList().reversed.toList();
      case '3M':
        return result.reversed.take(3).toList().reversed.toList();
      case '6M':
        return result.reversed.take(6).toList().reversed.toList();
      case '1Y':
        return result.reversed.take(12).toList().reversed.toList();
      case 'All':
      default:
        return result;
    }
  }

  void _processIndustryData(List<FundingModel> companies) {
    _metricData = {
      'Funding': {},
      'Deals': {},
      'Valuation': {},
    };

    if (companies.isEmpty) {
      // Generate dynamic dummy data based on time range
      final industries = ['Technology', 'Healthcare', 'Finance', 'Retail', 'Manufacturing'];
      final total = 100.0;
      var remaining = total;
      
      for (var i = 0; i < industries.length - 1; i++) {
        final percentage = (math.Random().nextDouble() * remaining * 0.7).roundToDouble();
        _metricData['Funding']![industries[i]] = percentage;
        _metricData['Deals']![industries[i]] = (percentage * 2).roundToDouble();
        _metricData['Valuation']![industries[i]] = percentage * 2;
        remaining -= percentage;
      }
      
      // Add remaining percentage to last industry
      _metricData['Funding']![industries.last] = remaining;
      _metricData['Deals']![industries.last] = (remaining * 2).roundToDouble();
      _metricData['Valuation']![industries.last] = remaining * 2;
      return;
    }

    // Process real data with variations
    for (var company in companies) {
      final industry = company.leadInvestor ?? 'Unknown';
      final baseAmount = company.amount;
      final variation = (math.Random().nextDouble() * 20 - 10).roundToDouble();
      final funding = baseAmount + variation;
      final valuation = funding * (2 + math.Random().nextDouble());

      _metricData['Funding']![industry] = (_metricData['Funding']![industry] ?? 0) + funding;
      _metricData['Deals']![industry] = (_metricData['Deals']![industry] ?? 0) + 1;
      _metricData['Valuation']![industry] = (_metricData['Valuation']![industry] ?? 0) + valuation;
    }

    // Ensure no negative values
    for (var metric in _metricData.keys) {
      for (var industry in _metricData[metric]!.keys.toList()) {
        if (_metricData[metric]![industry]! < 0) {
          _metricData[metric]![industry] = 0;
        }
      }
    }
  }

  void _processStageData(List<FundingModel> companies) {
    _stageData = {
      'Funding': [0, 0, 0, 0],
      'Deals': [0, 0, 0, 0],
      'Valuation': [0, 0, 0, 0],
    };

    if (companies.isEmpty) {
      // Generate dynamic dummy data based on time range
      final total = 100.0;
      var remaining = total;
      
      for (var i = 0; i < 3; i++) {
        final percentage = (math.Random().nextDouble() * remaining * 0.7).roundToDouble();
        _stageData['Funding']![i] = percentage;
        _stageData['Deals']![i] = (percentage / 10).roundToDouble();
        _stageData['Valuation']![i] = percentage * 2;
        remaining -= percentage;
      }
      
      // Add remaining percentage to last stage
      _stageData['Funding']![3] = remaining;
      _stageData['Deals']![3] = (remaining / 10).roundToDouble();
      _stageData['Valuation']![3] = remaining * 2;
      return;
    }

    // Process real data with variations
    for (var company in companies) {
      final stage = company.round;
      final baseAmount = company.amount;
      final variation = (math.Random().nextDouble() * 20 - 10).roundToDouble();
      final funding = baseAmount + variation;
      final valuation = funding * (2 + math.Random().nextDouble());
      
      int stageIndex;
      switch (stage.toLowerCase()) {
        case 'seed':
          stageIndex = 0;
          break;
        case 'series a':
          stageIndex = 1;
          break;
        case 'series b':
          stageIndex = 2;
          break;
        case 'series c':
          stageIndex = 3;
          break;
        default:
          continue;
      }

      _stageData['Funding']![stageIndex] += funding;
      _stageData['Deals']![stageIndex] += 1;
      _stageData['Valuation']![stageIndex] += valuation;
    }

    // Ensure no negative values
    for (var metric in _stageData.keys) {
      for (var i = 0; i < _stageData[metric]!.length; i++) {
        if (_stageData[metric]![i] < 0) {
          _stageData[metric]![i] = 0;
        }
      }
    }
  }

  @override
  void dispose() {
    _fundingSubscription?.cancel();
    _fundingService.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<FlSpot> _getFundingSpots() {
    final data = _fundingData[_selectedTimeRange] ?? [];
    if (data.isEmpty) {
      return [FlSpot(0, 0)];
    }
    return data.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value);
    }).toList();
  }

  String _getXAxisLabel(double value) {
    final now = DateTime.now();
    final data = _fundingData[_selectedTimeRange] ?? [];
    if (value.toInt() >= data.length) return '';

    switch (_selectedTimeRange) {
      case '1M':
        return 'Week ${value.toInt() + 1}';
      case '3M':
        return 'Month ${value.toInt() + 1}';
      case '6M':
        return 'Month ${value.toInt() + 1}';
      case '1Y':
        final month = now.month - (11 - value.toInt());
        final year = now.year - (month <= 0 ? 1 : 0);
        final adjustedMonth = month <= 0 ? month + 12 : month;
        return '${_getMonthName(adjustedMonth)}\n${year.toString().substring(2)}';
      case 'All':
      default:
        final date = DateTime(
          now.year - (11 - value.toInt()) ~/ 12,
          now.month - (11 - value.toInt()) % 12,
        );
        return '${_getMonthName(date.month)}\n${date.year.toString().substring(2)}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[month - 1];
  }

  List<PieChartSectionData> _getPieChartSections() {
    final data = _metricData[_selectedMetric] ?? {};
    if (data.isEmpty) {
      return [
        PieChartSectionData(
          value: 100,
          title: 'No Data',
          color: Colors.grey,
          radius: 100,
          titleStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ];
    }

    final total = data.values.fold(0.0, (sum, value) => sum + value);
    return data.entries.map((entry) {
      final percentage = (entry.value / total * 100).round();
      return PieChartSectionData(
        value: entry.value,
        title: percentage > 5 ? '${entry.key}\n$percentage%' : '$percentage%',
        color: _getColorForIndex(data.keys.toList().indexOf(entry.key)),
        radius: 100,
        titleStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        titlePositionPercentageOffset: 0.6,
        badgeWidget: percentage > 10 ? _buildBadge(percentage) : null,
        badgePositionPercentageOffset: 0.98,
      );
    }).toList();
  }

  Widget _buildBadge(int percentage) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        '$percentage%',
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
    ];
    return colors[index % colors.length];
  }

  List<BarChartGroupData> _getBarGroups() {
    final data = _stageData[_selectedMetric] ?? [0, 0, 0, 0];
    final maxValue = data.isEmpty ? 1.0 : data.reduce((a, b) => a > b ? a : b);
    
    return List.generate(4, (index) {
      final value = data[index];
      final percentage = maxValue > 0 ? (value / maxValue * 100).round() : 0;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: value,
            color: _getColorForIndex(index),
            width: 20,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(6),
            ),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxValue > 0 ? maxValue : 1.0,
              color: Colors.grey.withOpacity(0.1),
            ),
          ),
        ],
        showingTooltipIndicators: [0],
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            pinned: true,
            title: const Text('Trends & Analytics'),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(110),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Time Range Selector
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _timeRanges.length,
                        itemBuilder: (context, index) {
                          final range = _timeRanges[index];
                          final isSelected = range == _selectedTimeRange;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(range),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedTimeRange = range;
                                    _animationController.forward(from: 0.0);
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Metric Selector
                    SizedBox(
                      height: 36,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _metrics.length,
                        itemBuilder: (context, index) {
                          final metric = _metrics[index];
                          final isSelected = metric == _selectedMetric;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(metric),
                              selected: isSelected,
                              onSelected: (selected) {
                                if (selected) {
                                  setState(() {
                                    _selectedMetric = metric;
                                    _animationController.forward(from: 0.0);
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Funding Trends Chart
                _buildChartCard(
                  'Funding Trends',
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: true,
                          horizontalInterval: 1,
                          verticalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                          getDrawingVerticalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 30,
                              interval: 1,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  _getXAxisLabel(value),
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 20,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '\$${value.toInt()}M',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                );
                              },
                              reservedSize: 42,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.2),
                          ),
                        ),
                        minX: 0,
                        maxX: (_fundingData[_selectedTimeRange]?.length ?? 4) - 1,
                        minY: 0,
                        maxY: (_fundingData[_selectedTimeRange]?.reduce((a, b) => a > b ? a : b) ?? 100) * 1.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: _getFundingSpots(),
                            isCurved: true,
                            curveSmoothness: 0.35, // Adjust curve smoothness
                            color: Colors.blue,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) {
                                return FlDotCirclePainter(
                                  radius: 6,
                                  color: Colors.blue,
                                  strokeWidth: 2,
                                  strokeColor: Colors.white,
                                );
                              },
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              color: Colors.blue.withOpacity(0.1),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.blue.withOpacity(0.2),
                                  Colors.blue.withOpacity(0.0),
                                ],
                              ),
                            ),
                            preventCurveOverShooting: true,
                            shadow: const Shadow(
                              color: Colors.blue,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Industry Distribution Chart
                _buildChartCard(
                  'Industry Distribution',
                  SizedBox(
                    height: 300,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: _getPieChartSections(),
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            // Handle touch events if needed
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Stage Distribution Chart
                _buildChartCard(
                  'Stage Distribution',
                  SizedBox(
                    height: 300,
                    child: BarChart(
                      BarChartData(
                        alignment: BarChartAlignment.spaceAround,
                        maxY: _getBarGroups().isEmpty ? 1.0 : 
                          _getBarGroups().map((group) => 
                            group.barRods.first.toY).reduce((a, b) => a > b ? a : b) + 2,
                        minY: 0,
                        barTouchData: BarTouchData(
                          enabled: true,
                          touchTooltipData: BarTouchTooltipData(
                            tooltipBgColor: Colors.white,
                            getTooltipItem: (group, groupIndex, rod, rodIndex) {
                              return BarTooltipItem(
                                '${rod.toY.round()}%',
                                const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                        ),
                        titlesData: FlTitlesData(
                          show: true,
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                const titles = ['Seed', 'Series A', 'Series B', 'Series C'];
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    titles[value.toInt()],
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 12,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 42,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()}%',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                );
                              },
                            ),
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          rightTitles: const AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: false,
                        ),
                        gridData: FlGridData(
                          show: true,
                          drawVerticalLine: false,
                          horizontalInterval: 1,
                          getDrawingHorizontalLine: (value) {
                            return FlLine(
                              color: Colors.grey.withOpacity(0.2),
                              strokeWidth: 1,
                            );
                          },
                        ),
                        barGroups: _getBarGroups(),
                      ),
                    ),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartCard(String title, Widget chart) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            chart,
          ],
        ),
      ),
    );
  }
} 