import 'package:flutter/widgets.dart';

class ChartData {
  final List<String> labels;
  final List<double> values;
  final String color;

  ChartData({
    required this.labels,
    required this.values,
    required this.color,
  });

  factory ChartData.fromJson(Map<String, dynamic> json) {
    return ChartData(
      labels: json['labels'] != null ? List<String>.from(json['labels']) : [],
      values: json['values'] != null
          ? (json['values'] as List).map((v) => (v as num).toDouble()).toList()
          : [],
      color: json['color'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labels': labels,
      'values': values,
      'color': color,
    };
  }
}

class Indicator {
  final String title;
  final String value;
  final String change;
  final String direction; // 'up' | 'down'
  final String description;
  final Widget icon; // Équivalent de JSX.Element en Flutter
  final ChartData chartData;

  Indicator({
    required this.title,
    required this.value,
    required this.change,
    required this.direction,
    required this.description,
    required this.icon,
    required this.chartData,
  });
}

class PieChartDataModel {
  final List<String> labels;
  final List<double> values;
  final List<String> colors;

  PieChartDataModel({
    required this.labels,
    required this.values,
    required this.colors,
  });

  factory PieChartDataModel.fromJson(Map<String, dynamic> json) {
    return PieChartDataModel(
      labels: json['labels'] != null ? List<String>.from(json['labels']) : [],
      values: json['values'] != null
          ? (json['values'] as List).map((v) => (v as num).toDouble()).toList()
          : [],
      colors: json['colors'] != null ? List<String>.from(json['colors']) : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labels': labels,
      'values': values,
      'colors': colors,
    };
  }
}

class MainChartDataModel {
  final List<int> labels;
  final List<double> values;

  MainChartDataModel({
    required this.labels,
    required this.values,
  });

  factory MainChartDataModel.fromJson(Map<String, dynamic> json) {
    return MainChartDataModel(
      labels: json['labels'] != null ? List<int>.from(json['labels']) : [],
      values: json['values'] != null
          ? (json['values'] as List).map((v) => (v as num).toDouble()).toList()
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'labels': labels,
      'values': values,
    };
  }
}