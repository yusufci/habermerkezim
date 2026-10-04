import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/article.dart';

/// Export formatları
enum ExportFormat { csv, json }

/// Export türleri
enum ExportType { favorites, readingHistory, readingList, statistics, all }

/// Export sonucu
class ExportResult {
  final bool success;
  final String? filePath;
  final String? error;
  final int itemCount;

  const ExportResult({
    required this.success,
    this.filePath,
    this.error,
    this.itemCount = 0,
  });

  factory ExportResult.success(String filePath, int itemCount) {
    return ExportResult(
      success: true,
      filePath: filePath,
      itemCount: itemCount,
    );
  }

  factory ExportResult.failure(String error) {
    return ExportResult(success: false, error: error);
  }
}

/// Export servisi - Verileri CSV ve JSON formatında dışa aktarır
class ExportService {
  static final ExportService _instance = ExportService._internal();
  factory ExportService() => _instance;
  ExportService._internal();

  /// Favorileri dışa aktar
  Future<ExportResult> exportFavorites({
    required List<Article> favorites,
    required ExportFormat format,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'haber_merkezi_favoriler_$timestamp';

      String content;
      String extension;

      if (format == ExportFormat.csv) {
        content = _articlesToCsv(favorites);
        extension = 'csv';
      } else {
        content = _articlesToJson(favorites, 'favorites');
        extension = 'json';
      }

      final filePath = await _saveToFile(fileName, extension, content);
      return ExportResult.success(filePath, favorites.length);
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult.failure(
        'Favoriler dışa aktarılırken hata oluştu: $e',
      );
    }
  }

  /// Okuma geçmişini dışa aktar
  Future<ExportResult> exportReadingHistory({
    required List<Article> history,
    required ExportFormat format,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'haber_merkezi_okuma_gecmisi_$timestamp';

      String content;
      String extension;

      if (format == ExportFormat.csv) {
        content = _articlesToCsv(history);
        extension = 'csv';
      } else {
        content = _articlesToJson(history, 'reading_history');
        extension = 'json';
      }

      final filePath = await _saveToFile(fileName, extension, content);
      return ExportResult.success(filePath, history.length);
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult.failure(
        'Okuma geçmişi dışa aktarılırken hata oluştu: $e',
      );
    }
  }

  /// Okuma listesini dışa aktar
  Future<ExportResult> exportReadingList({
    required List<Article> readingList,
    required ExportFormat format,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'haber_merkezi_okuma_listesi_$timestamp';

      String content;
      String extension;

      if (format == ExportFormat.csv) {
        content = _articlesToCsv(readingList);
        extension = 'csv';
      } else {
        content = _articlesToJson(readingList, 'reading_list');
        extension = 'json';
      }

      final filePath = await _saveToFile(fileName, extension, content);
      return ExportResult.success(filePath, readingList.length);
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult.failure(
        'Okuma listesi dışa aktarılırken hata oluştu: $e',
      );
    }
  }

  /// İstatistikleri dışa aktar
  Future<ExportResult> exportStatistics({
    required Map<String, dynamic> statistics,
    required ExportFormat format,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'haber_merkezi_istatistikler_$timestamp';

      String content;
      String extension;

      if (format == ExportFormat.csv) {
        content = _statisticsToCsv(statistics);
        extension = 'csv';
      } else {
        content = _statisticsToJson(statistics);
        extension = 'json';
      }

      final filePath = await _saveToFile(fileName, extension, content);
      return ExportResult.success(filePath, statistics.length);
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult.failure(
        'İstatistikler dışa aktarılırken hata oluştu: $e',
      );
    }
  }

  /// Tüm verileri dışa aktar
  Future<ExportResult> exportAll({
    required List<Article> favorites,
    required List<Article> readingHistory,
    required List<Article> readingList,
    required Map<String, dynamic> statistics,
  }) async {
    try {
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'haber_merkezi_tum_veriler_$timestamp';

      final allData = {
        'export_date': DateTime.now().toIso8601String(),
        'app_version': '1.0.0',
        'favorites': favorites.map((a) => _articleToMap(a)).toList(),
        'reading_history': readingHistory.map((a) => _articleToMap(a)).toList(),
        'reading_list': readingList.map((a) => _articleToMap(a)).toList(),
        'statistics': statistics,
      };

      final content = const JsonEncoder.withIndent('  ').convert(allData);
      final filePath = await _saveToFile(fileName, 'json', content);

      final totalItems =
          favorites.length + readingHistory.length + readingList.length;
      return ExportResult.success(filePath, totalItems);
    } catch (e) {
      debugPrint('Export error: $e');
      return ExportResult.failure('Veriler dışa aktarılırken hata oluştu: $e');
    }
  }

  /// Dosyayı paylaş
  Future<void> shareExportedFile(String filePath) async {
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(filePath)],
          subject: 'Haber Merkezi Verileri',
        ),
      );
    } catch (e) {
      debugPrint('Share error: $e');
      rethrow;
    }
  }

  /// Makaleleri CSV formatına dönüştür
  String _articlesToCsv(List<Article> articles) {
    final buffer = StringBuffer();

    // Header
    buffer.writeln(
      'ID,Başlık,Açıklama,Kaynak,Kategori,Yayın Tarihi,Link,Okundu,Favori',
    );

    // Data rows
    for (final article in articles) {
      final row = [
        _escapeCsv(article.id),
        _escapeCsv(article.title),
        _escapeCsv(article.description),
        _escapeCsv(article.sourceName),
        _escapeCsv(article.category),
        _escapeCsv(article.publishedDate.toIso8601String()),
        _escapeCsv(article.link),
        article.isRead ? 'Evet' : 'Hayır',
        article.isFavorite ? 'Evet' : 'Hayır',
      ].join(',');
      buffer.writeln(row);
    }

    return buffer.toString();
  }

  /// Makaleleri JSON formatına dönüştür
  String _articlesToJson(List<Article> articles, String type) {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'type': type,
      'count': articles.length,
      'articles': articles.map((a) => _articleToMap(a)).toList(),
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// İstatistikleri CSV formatına dönüştür
  String _statisticsToCsv(Map<String, dynamic> statistics) {
    final buffer = StringBuffer();

    buffer.writeln('Metrik,Değer');

    void addRow(String key, dynamic value) {
      if (value is Map) {
        for (final entry in value.entries) {
          buffer.writeln(
            '${_escapeCsv('$key - ${entry.key}')},${_escapeCsv(entry.value.toString())}',
          );
        }
      } else {
        buffer.writeln('${_escapeCsv(key)},${_escapeCsv(value.toString())}');
      }
    }

    statistics.forEach(addRow);

    return buffer.toString();
  }

  /// İstatistikleri JSON formatına dönüştür
  String _statisticsToJson(Map<String, dynamic> statistics) {
    final data = {
      'export_date': DateTime.now().toIso8601String(),
      'type': 'statistics',
      'data': statistics,
    };

    return const JsonEncoder.withIndent('  ').convert(data);
  }

  /// Article'ı Map'e dönüştür
  Map<String, dynamic> _articleToMap(Article article) {
    return {
      'id': article.id,
      'title': article.title,
      'description': article.description,
      'content': article.content,
      'source_name': article.sourceName,
      'category': article.category,
      'published_date': article.publishedDate.toIso8601String(),
      'link': article.link,
      'image_url': article.imageUrl,
      'is_read': article.isRead,
      'is_favorite': article.isFavorite,
    };
  }

  /// CSV için escape işlemi
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Dosyaya kaydet
  Future<String> _saveToFile(
    String fileName,
    String extension,
    String content,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${directory.path}/exports');

    if (!exportDir.existsSync()) {
      await exportDir.create(recursive: true);
    }

    final file = File('${exportDir.path}/$fileName.$extension');
    await file.writeAsString(content, encoding: utf8);

    return file.path;
  }

  /// Export dizindeki dosyaları listele
  Future<List<FileSystemEntity>> listExportedFiles() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (!exportDir.existsSync()) {
        return [];
      }

      return exportDir.listSync()..sort(
        (a, b) => b.statSync().modified.compareTo(a.statSync().modified),
      );
    } catch (e) {
      debugPrint('List exports error: $e');
      return [];
    }
  }

  /// Export dosyasını sil
  Future<bool> deleteExportedFile(String filePath) async {
    try {
      final file = File(filePath);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete export error: $e');
      return false;
    }
  }

  /// Tüm export dosyalarını sil
  Future<bool> clearAllExports() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${directory.path}/exports');

      if (exportDir.existsSync()) {
        await exportDir.delete(recursive: true);
      }
      return true;
    } catch (e) {
      debugPrint('Clear exports error: $e');
      return false;
    }
  }
}
