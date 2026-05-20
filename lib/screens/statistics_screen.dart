import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/expense_provider.dart';
import '../models/transaction.dart';
import '../theme/app_theme.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  String _selectedPeriod = 'Month';
  final List<String> _periods = ['Week', 'Month', 'Year'];
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ExpenseProvider>();
    final formatter = NumberFormat('#,##0.00', 'en_US');
    
    // Period-based data
    final periodTransactions = provider.getTransactionsForPeriod(_selectedPeriod);
    final chartData = provider.getAggregatedData(_selectedPeriod);
    
    final periodIncome = periodTransactions
        .where((t) => t.type == TransactionType.income)
        .fold(0.0, (sum, t) => sum + t.amount);
    final periodExpense = periodTransactions
        .where((t) => t.type == TransactionType.expense)
        .fold(0.0, (sum, t) => sum + t.amount);
    final periodBalance = periodIncome - periodExpense;

    final bgColor = AppTheme.getBackground(context);
    final cardColor = AppTheme.getCardColor(context);
    final textColor = AppTheme.getTextColor(context);
    final textGrey = AppTheme.getTextGreyColor(context);

    // Calculate category breakdown for Pie Chart
    final expenseTransactions = periodTransactions.where((t) => t.type == TransactionType.expense).toList();

    Map<PaymentCategory, double> categoryTotals = {};
    for (var t in expenseTransactions) {
      final cat = provider.getTransactionCategory(t);
      categoryTotals[cat] = (categoryTotals[cat] ?? 0) + t.amount;
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Dynamic scale for Bar Chart
    double maxVal = 500;
    for (var d in chartData) {
      if (d['income'] > maxVal) maxVal = d['income'];
      if (d['expense'] > maxVal) maxVal = d['expense'];
    }
    maxVal = (maxVal / 500).ceil() * 500.0;
    if (maxVal == 0) maxVal = 500;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Statistics',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor)),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cardColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8)
                        ],
                      ),
                      child: const Icon(Icons.tune,
                          color: AppColors.primary, size: 20),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Total Balance Overview Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 20,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('$_selectedPeriod Balance',
                          style: TextStyle(
                              fontSize: 13, color: textGrey)),
                      const SizedBox(height: 4),
                      Text('\$${formatter.format(periodBalance)}',
                          style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: textColor)),
                      const SizedBox(height: 20),

                      // Overview + Period selector
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Overview',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: textColor)),
                          Row(
                            children: _periods
                                .map((p) => GestureDetector(
                                      onTap: () =>
                                          setState(() => _selectedPeriod = p),
                                      child: Container(
                                        margin: const EdgeInsets.only(left: 6),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: _selectedPeriod == p
                                              ? AppColors.primary
                                              : (Theme.of(context).brightness == Brightness.dark ? AppColors.darkCardLight : Colors.grey.shade100),
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(p,
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: _selectedPeriod == p
                                                    ? Colors.white
                                                    : textGrey,
                                                fontWeight: FontWeight.w500)),
                                      ),
                                    ))
                                .toList(),
                          )
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Bar Chart
                      SizedBox(
                        height: 180,
                        child: BarChart(
                          BarChartData(
                            alignment: BarChartAlignment.spaceAround,
                            maxY: maxVal,
                            barTouchData: BarTouchData(
                              touchTooltipData: BarTouchTooltipData(
                                getTooltipColor: (group) => AppColors.primary,
                                tooltipPadding: const EdgeInsets.all(8),
                                tooltipMargin: 8,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                  return BarTooltipItem(
                                    '\$${rod.toY.toStringAsFixed(0)}',
                                    const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (val, meta) {
                                    final idx = val.toInt();
                                    if (idx >= 0 &&
                                        idx < chartData.length) {
                                      return Padding(
                                        padding:
                                            const EdgeInsets.only(top: 8),
                                        child: Text(chartData[idx]['label'],
                                            style: TextStyle(
                                                fontSize: 10,
                                                color: textGrey)),
                                      );
                                    }
                                    return const SizedBox();
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: maxVal / 4,
                              getDrawingHorizontalLine: (val) => FlLine(
                                  color: textGrey.withValues(alpha: 0.1), strokeWidth: 1),
                            ),
                            borderData: FlBorderData(show: false),
                            barGroups: chartData.asMap().entries.map((entry) {
                              final i = entry.key;
                              final data = entry.value;
                              
                              final incomeVal = data['income'] == 0 ? 0.0 : data['income'];
                              final expenseVal = data['expense'] == 0 ? 0.0 : data['expense'];

                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: incomeVal,
                                    color: AppColors.primary,
                                    width: _selectedPeriod == 'Year' ? 4 : 10,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                  BarChartRodData(
                                    toY: expenseVal,
                                    color: AppColors.primary.withValues(alpha: 0.3),
                                    width: _selectedPeriod == 'Year' ? 4 : 10,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ],
                                barsSpace: 2,
                              );
                            }).toList(),
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Legend
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _LegendDot(
                              color: AppColors.primary, label: 'Income', textGrey: textGrey),
                          const SizedBox(width: 20),
                          _LegendDot(
                              color: AppColors.primary.withValues(alpha: 0.3),
                              label: 'Expense',
                              textGrey: textGrey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Pie Chart Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15)
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Expense Distribution',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor)),
                          Icon(Icons.pie_chart_outline, color: textGrey, size: 20),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 200,
                        child: periodExpense > 0 
                        ? PieChart(
                          PieChartData(
                            pieTouchData: PieTouchData(
                              touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                setState(() {
                                  if (!event.isInterestedForInteractions ||
                                      pieTouchResponse == null ||
                                      pieTouchResponse.touchedSection == null) {
                                    _touchedIndex = -1;
                                    return;
                                  }
                                  _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                                });
                              },
                            ),
                            borderData: FlBorderData(show: false),
                            sectionsSpace: 4,
                            centerSpaceRadius: 50,
                            sections: sortedCategories.asMap().entries.map((entry) {
                              final index = entry.key;
                              final cat = entry.value.key;
                              final amount = entry.value.value;
                              final isTouched = index == _touchedIndex;
                              final fontSize = isTouched ? 16.0 : 12.0;
                              final radius = isTouched ? 60.0 : 50.0;
                              final widgetSize = isTouched ? 45.0 : 35.0;

                              return PieChartSectionData(
                                color: cat.color,
                                value: amount,
                                title: isTouched ? '${(amount/periodExpense*100).toStringAsFixed(0)}%' : '',
                                radius: radius,
                                titleStyle: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                badgeWidget: isTouched ? null : _Badge(cat.icon, size: widgetSize, borderColor: cat.color),
                                badgePositionPercentageOffset: .98,
                              );
                            }).toList(),
                          ),
                        )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.analytics_outlined, size: 40, color: textGrey.withValues(alpha: 0.5)),
                                const SizedBox(height: 8),
                                Text('No expenses for this period', style: TextStyle(color: textGrey, fontSize: 13)),
                              ],
                            ),
                          ),
                      ),
                      if (periodExpense > 0) ...[
                        const SizedBox(height: 20),
                        Wrap(
                          spacing: 16,
                          runSpacing: 8,
                          alignment: WrapAlignment.center,
                          children: sortedCategories.take(4).map((entry) => _LegendDot(
                            color: entry.key.color, 
                            label: entry.key.name, 
                            textGrey: textGrey,
                          )).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Category breakdown (List)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('Category Breakdown',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor)),
              ),

              const SizedBox(height: 12),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10)
                    ],
                  ),
                  child: periodExpense > 0 
                  ? Column(
                    children: sortedCategories.asMap().entries.map((entry) {
                      final isLast = entry.key == sortedCategories.length - 1;
                      final cat = entry.value.key;
                      final amount = entry.value.value;
                      final percentage = periodExpense > 0 ? (amount / periodExpense) : 0.0;
                      
                      return _CategoryBreakdown(
                        label: cat.name,
                        percentage: percentage,
                        color: cat.color,
                        icon: cat.icon,
                        isLast: isLast,
                        textColor: textColor,
                      );
                    }).toList(),
                  )
                  : Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(
                        child: Text('No data found', style: TextStyle(color: textGrey)),
                      ),
                    ),
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  final Color textGrey;
  const _LegendDot({required this.color, required this.label, required this.textGrey});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color borderColor;

  const _Badge(this.icon, {required this.size, required this.borderColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: PieChart.defaultDuration,
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: borderColor, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 3),
            blurRadius: 3,
          ),
        ],
      ),
      padding: EdgeInsets.all(size * .15),
      child: Center(
        child: Icon(icon, color: borderColor, size: size * 0.5),
      ),
    );
  }
}

class _CategoryBreakdown extends StatelessWidget {
  final String label;
  final double percentage;
  final Color color;
  final IconData icon;
  final bool isLast;
  final Color textColor;

  const _CategoryBreakdown({
    required this.label,
    required this.percentage,
    required this.color,
    required this.icon,
    this.isLast = false,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(
                bottom: BorderSide(
                    color: Colors.grey.withValues(alpha: 0.1), width: 1)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textColor)),
                    Text('${(percentage * 100).toInt()}%',
                        style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage,
                    backgroundColor: Colors.grey.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                    minHeight: 6,
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
