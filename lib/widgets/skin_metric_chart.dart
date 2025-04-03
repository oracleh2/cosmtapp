import 'package:flutter/material.dart';
import 'package:skin_analyzer/models/skin_analysis.dart';
import 'package:fl_chart/fl_chart.dart';

class SkinMetricChart extends StatelessWidget {
  final List<SkinMetric> metrics;

  const SkinMetricChart({
    Key? key,
    required this.metrics,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return _buildBarChart(context);
  }

  Widget _buildBarChart(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16, right: 16),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _getMaxY(),
          barGroups: _getBarGroups(context),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 60,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() >= 0 && value.toInt() < metrics.length) {
                    return RotatedBox(
                      quarterTurns: 1,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          metrics[value.toInt()].name,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
              ),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
          ),
          gridData: const FlGridData(
            show: true,
            horizontalInterval: 20,
            getDrawingHorizontalLine: _getGridLine,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(color: Colors.grey.shade300),
              left: BorderSide(color: Colors.grey.shade300),
            ),
          ),
        ),
      ),
    );
  }

  List<BarChartGroupData> _getBarGroups(BuildContext context) {
    return List.generate(metrics.length, (index) {
      final metric = metrics[index];
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: metric.value,
            color: _getBarColor(metric, context),
            width: 20,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      );
    });
  }

  double _getMaxY() {
    double maxValue = 0;
    for (var metric in metrics) {
      if (metric.maxValue != null && metric.maxValue! > maxValue) {
        maxValue = metric.maxValue!;
      } else if (metric.value > maxValue) {
        maxValue = metric.value;
      }
    }
    // Округлим до ближайшего большего кратного 20
    return ((maxValue ~/ 20) + 1) * 20.0;
  }

  Color _getBarColor(SkinMetric metric, BuildContext context) {
    if (metric.maxValue == null) {
      // Если нет максимального значения, используем простую логику:
      if (metric.value < 30) {
        return Colors.red;
      }
      if (metric.value < 70) {
        return Colors.orange;
      }
      return Colors.green;
    }

    // Если есть максимальное значение, используем соотношение:
    final ratio = metric.value / metric.maxValue!;
    if (ratio < 0.3) {
      return Colors.red;
    }
    if (ratio < 0.7) {
      return Colors.orange;
    }
    return Colors.green;
  }

  static FlLine _getGridLine(double value) {
    return FlLine(
      color: Colors.grey.shade200,
      strokeWidth: 1,
    );
  }
}