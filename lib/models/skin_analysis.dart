import 'package:skin_analyzer/models/cosmetic_product.dart';

class SkinAnalysis {
  final int id;
  final int userId;
  final String imageUrl;
  final String? thumbnailUrl;
  final DateTime analysisDate;
  final Map<String, dynamic> skinCondition;
  final List<String> skinIssues;
  final List<String> recommendations;
  final List<CosmeticProduct>? recommendedProducts;
  final List<SkinMetric> metrics;

  SkinAnalysis({
    required this.id,
    required this.userId,
    required this.imageUrl,
    this.thumbnailUrl,
    required this.analysisDate,
    required this.skinCondition,
    required this.skinIssues,
    required this.recommendations,
    this.recommendedProducts,
    required this.metrics,
  });

  factory SkinAnalysis.fromJson(Map<String, dynamic> json) {
    List<String> parseStringList(List<dynamic> data) {
      return data.map((item) => item.toString()).toList();
    }

    List<CosmeticProduct>? parseProducts(List<dynamic>? data) {
      if (data == null) return null;
      return data.map((item) => CosmeticProduct.fromJson(item)).toList();
    }

    List<SkinMetric> parseMetrics(List<dynamic> data) {
      return data.map((item) => SkinMetric.fromJson(item)).toList();
    }

    return SkinAnalysis(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      thumbnailUrl: json['thumbnail_url'],
      analysisDate: DateTime.parse(json['analysis_date']),
      skinCondition: json['skin_condition'],
      skinIssues: parseStringList(json['skin_issues']),
      recommendations: parseStringList(json['recommendations']),
      recommendedProducts: json['recommended_products'] != null
          ? parseProducts(json['recommended_products'])
          : null,
      metrics: parseMetrics(json['metrics']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'thumbnail_url': thumbnailUrl,
      'analysis_date': analysisDate.toIso8601String(),
      'skin_condition': skinCondition,
      'skin_issues': skinIssues,
      'recommendations': recommendations,
      'recommended_products': recommendedProducts?.map((p) => p.toJson()).toList(),
      'metrics': metrics.map((m) => m.toJson()).toList(),
    };
  }
}

class SkinMetric {
  final String name;
  final double value;
  final double? minValue;
  final double? maxValue;
  final String? unit;
  final String? category;

  SkinMetric({
    required this.name,
    required this.value,
    this.minValue,
    this.maxValue,
    this.unit,
    this.category,
  });

  factory SkinMetric.fromJson(Map<String, dynamic> json) {
    return SkinMetric(
      name: json['name'],
      value: json['value'].toDouble(),
      minValue: json['min_value']?.toDouble(),
      maxValue: json['max_value']?.toDouble(),
      unit: json['unit'],
      category: json['category'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'value': value,
      'min_value': minValue,
      'max_value': maxValue,
      'unit': unit,
      'category': category,
    };
  }
}