import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/article.dart';

import 'package:flutter/foundation.dart';
part 'article_model.g.dart';

/// Article entity'sinin data layer implementasyonu
/// JSON serialization ve Hive database desteği ile
/// Domain entity'den farklı olarak external dependencies içerir
@HiveType(typeId: 0)
class ArticleModel extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String? content;

  @HiveField(4)
  final String link;

  @HiveField(5)
  final String? imageUrl;

  @HiveField(6)
  final DateTime publishedDate;

  @HiveField(7)
  final String category;

  @HiveField(8)
  final String sourceName;

  @HiveField(9)
  final bool isRead;

  @HiveField(10)
  final bool isFavorite;

  @HiveField(11)
  final String? videoUrl;

  @HiveField(12)
  final String? videoThumbnail;

  ArticleModel({
    required this.id,
    required this.title,
    required this.description,
    this.content,
    required this.link,
    this.imageUrl,
    required this.publishedDate,
    required this.category,
    required this.sourceName,
    this.isRead = false,
    this.isFavorite = false,
    this.videoUrl,
    this.videoThumbnail,
  });

  /// JSON'dan ArticleModel oluşturur (RSS XML parse sonrası)
  factory ArticleModel.fromJson(Map<String, dynamic> json) {
    return ArticleModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      content: json['content'],
      link: json['link'] ?? '',
      imageUrl: json['imageUrl'],
      publishedDate: json['publishedDate'] != null
          ? DateTime.parse(json['publishedDate'])
          : DateTime.now(),
      category: json['category'] ?? '',
      sourceName: json['sourceName'] ?? '',
      isRead: json['isRead'] ?? false,
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  /// RSS XML item'ından ArticleModel oluşturur
  factory ArticleModel.fromRssItem({
    required Map<String, dynamic> rssItem,
    required String category,
    required String sourceName,
  }) {
    final title = _cleanHtml(rssItem['title'] ?? '');
    final link = rssItem['link'] ?? '';
    final pubDate = rssItem['pubDate'] ?? '';

    // Unique ID oluştur (link + sourceName + title + publishDate bazlı)
    final id = _generateId(link, sourceName, title, pubDate);

    return ArticleModel(
      id: id,
      title: title,
      description: _cleanHtml(rssItem['description'] ?? ''),
      content: _cleanHtml(rssItem['content'] ?? rssItem['description'] ?? ''),
      link: link,
      imageUrl: _extractImageUrl(rssItem),
      publishedDate: _parseDate(pubDate),
      category: category,
      sourceName: sourceName,
    );
  }

  /// ArticleModel'i JSON'a çevirir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'content': content,
      'link': link,
      'imageUrl': imageUrl,
      'publishedDate': publishedDate.toIso8601String(),
      'category': category,
      'sourceName': sourceName,
      'isRead': isRead,
      'isFavorite': isFavorite,
    };
  }

  /// Domain entity'ye çevirir
  Article toEntity() {
    return Article(
      id: id,
      title: title,
      description: description,
      content: content,
      link: link,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      videoThumbnail: videoThumbnail,
      publishedDate: publishedDate,
      category: category,
      sourceName: sourceName,
      isRead: isRead,
      isFavorite: isFavorite,
    );
  }

  /// Domain entity'den oluşturur
  factory ArticleModel.fromEntity(Article article) {
    return ArticleModel(
      id: article.id,
      title: article.title,
      description: article.description,
      content: article.content,
      link: article.link,
      imageUrl: article.imageUrl,
      videoUrl: article.videoUrl,
      videoThumbnail: article.videoThumbnail,
      publishedDate: article.publishedDate,
      category: article.category,
      sourceName: article.sourceName,
      isRead: article.isRead,
      isFavorite: article.isFavorite,
    );
  }

  /// HTML taglerini temizler
  static String _cleanHtml(String htmlString) {
    if (htmlString.isEmpty) return htmlString;

    final RegExp exp = RegExp(r'<[^>]*>', multiLine: true, caseSensitive: true);
    return htmlString
        .replaceAll(exp, '')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .trim();
  }

  /// RSS item'ından görsel URL'i çıkarır
  static String? _extractImageUrl(Map<String, dynamic> rssItem) {
    // 1. media:content URL'i (öncelikli)
    if (rssItem['mediaContent'] != null &&
        rssItem['mediaContent'].toString().isNotEmpty) {
      final url = rssItem['mediaContent'].toString().trim();
      if (_isValidImageUrl(url)) return url;
    }

    // 2. enclosure URL'i
    if (rssItem['enclosure'] != null &&
        rssItem['enclosure'].toString().isNotEmpty) {
      final url = rssItem['enclosure'].toString().trim();
      if (_isValidImageUrl(url)) return url;
    }

    // 3. description içindeki img tag'i (farklı formatlar)
    final description = rssItem['description'] ?? '';
    if (description.isNotEmpty) {
      // Standart img tag: <img src="..."> veya <img src='...'>
      // Önce çift tırnak ile dene
      var imgRegex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
      var match = imgRegex.firstMatch(description);
      if (match == null) {
        // Tek tırnak ile dene
        imgRegex = RegExp(r"<img[^>]+src='([^']+)'", caseSensitive: false);
        match = imgRegex.firstMatch(description);
      }
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }

      // data-src (lazy loading): <img data-src="...">
      imgRegex = RegExp(r'<img[^>]+data-src="([^"]+)"', caseSensitive: false);
      match = imgRegex.firstMatch(description);
      if (match == null) {
        imgRegex = RegExp(r"<img[^>]+data-src='([^']+)'", caseSensitive: false);
        match = imgRegex.firstMatch(description);
      }
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }

      // data-lazy-src: <img data-lazy-src="...">
      imgRegex = RegExp(
        r'<img[^>]+data-lazy-src="([^"]+)"',
        caseSensitive: false,
      );
      match = imgRegex.firstMatch(description);
      if (match == null) {
        imgRegex = RegExp(
          r"<img[^>]+data-lazy-src='([^']+)'",
          caseSensitive: false,
        );
        match = imgRegex.firstMatch(description);
      }
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }
    }

    // 4. content içindeki img tag'i
    final content = rssItem['content'] ?? '';
    if (content.isNotEmpty && content != description) {
      var imgRegex = RegExp(r'<img[^>]+src="([^"]+)"', caseSensitive: false);
      var match = imgRegex.firstMatch(content);
      if (match == null) {
        imgRegex = RegExp(r"<img[^>]+src='([^']+)'", caseSensitive: false);
        match = imgRegex.firstMatch(content);
      }
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }

      // content içinde data-src kontrol et
      imgRegex = RegExp(r'<img[^>]+data-src="([^"]+)"', caseSensitive: false);
      match = imgRegex.firstMatch(content);
      if (match != null) {
        final url = match.group(1)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }
    }

    // 5. Herhangi bir URL içinde görsel uzantısı ara (son çare)
    final allText = '$description $content';
    if (allText.isNotEmpty) {
      // HTTP(S) ile başlayan ve görsel uzantısı içeren URL'leri bul
      final urlRegex = RegExp(
        r'https?://[^\s<>"]+?\.(?:jpg|jpeg|png|gif|webp|bmp)(?:\?[^\s<>"]*)?',
        caseSensitive: false,
      );
      final match = urlRegex.firstMatch(allText);
      if (match != null) {
        final url = match.group(0)?.trim();
        if (url != null && _isValidImageUrl(url)) return url;
      }
    }

    return null;
  }

  /// Görsel URL'inin geçerli olup olmadığını kontrol eder
  static bool _isValidImageUrl(String url) {
    if (url.isEmpty) return false;

    // URL formatını kontrol et
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }

      // Görsel uzantılarını kontrol et
      final lowerUrl = url.toLowerCase();
      final imageExtensions = [
        '.jpg',
        '.jpeg',
        '.png',
        '.gif',
        '.webp',
        '.bmp',
        '.svg',
        '.avif',
      ];
      final hasImageExtension = imageExtensions.any(
        (ext) => lowerUrl.contains(ext),
      );

      // URL'de görsel uzantısı yoksa ama domain'de görsel servisi varsa kabul et
      if (!hasImageExtension) {
        final imageDomains = [
          'imgur.com',
          'i.imgur.com',
          'cdn',
          'image',
          'photo',
          'pic',
          'media',
          'img',
          'static',
          'assets',
          'upload',
          'content',
          'cloudinary',
          'imgix',
        ];
        final hasImageDomain = imageDomains.any(
          (domain) => lowerUrl.contains(domain),
        );
        if (!hasImageDomain) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Tarih parse eder - RSS feed'lerindeki farklı tarih formatlarını destekler
  static DateTime _parseDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      debugPrint('⚠️ Tarih string boş, şu anki zaman kullanılıyor');
      return DateTime.now();
    }

    // String'i temizle
    final cleaned = dateString.trim();

    // RFC 2822 formatı (Thu, 14 Sep 2025 09:00:00 GMT veya +0300)
    try {
      // RFC 2822 formatını parse et
      // Örnek: "Thu, 14 Sep 2025 09:00:00 GMT" veya "Thu, 14 Sep 2025 09:00:00 +0300"
      if (cleaned.contains(',') && cleaned.length > 20) {
        // RFC 2822 formatı
        final parts = cleaned.split(' ');
        if (parts.length >= 5) {
          // Ay ismini sayıya çevir
          final monthMap = {
            // English month names
            'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
            'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12,
            // Turkish month names
            'Oca': 1, 'Şub': 2, 'Nis': 4, 'Haz': 6,
            'Tem': 7, 'Ağu': 8, 'Eyl': 9, 'Eki': 10, 'Kas': 11, 'Ara': 12,
          };

          final day = int.tryParse(parts[1]) ?? 1;
          final monthStr = parts[2];
          final month = monthMap[monthStr] ?? DateTime.now().month;
          final year = int.tryParse(parts[3]) ?? DateTime.now().year;

          // Saat bilgisi
          final timeParts = parts[4].split(':');
          final hour = int.tryParse(timeParts[0]) ?? 0;
          final minute = int.tryParse(timeParts[1]) ?? 0;
          final second = timeParts.length > 2
              ? (int.tryParse(timeParts[2]) ?? 0)
              : 0;

          final date = DateTime(year, month, day, hour, minute, second);

          // Timezone offset varsa uygula
          if (parts.length > 5) {
            final tzStr = parts[5];
            if (tzStr.startsWith('+') || tzStr.startsWith('-')) {
              // +0300 formatı
              final offsetHours = int.tryParse(tzStr.substring(1, 3)) ?? 0;
              final offsetMinutes = int.tryParse(tzStr.substring(3, 5)) ?? 0;
              final offset = Duration(
                hours: offsetHours,
                minutes: offsetMinutes,
              );

              if (tzStr.startsWith('-')) {
                return date.add(offset);
              } else {
                return date.subtract(offset);
              }
            } else if (tzStr == 'GMT' || tzStr == 'UTC') {
              // GMT/UTC için local timezone'a çevir
              final localOffset = DateTime.now().timeZoneOffset;
              return date.add(localOffset);
            }
          }

          return date;
        }
      }
    } catch (e) {
      debugPrint('⚠️ RFC 2822 parse hatası: $e');
    }

    // ISO 8601 formatı (2025-09-14T09:00:00Z veya 2025-09-14T09:00:00+03:00)
    try {
      return DateTime.parse(cleaned);
    } catch (e) {
      debugPrint('⚠️ ISO 8601 parse hatası: $e');
    }

    // Unix timestamp (milliseconds)
    try {
      final timestamp = int.tryParse(cleaned);
      if (timestamp != null && timestamp > 0) {
        // Timestamp 10 haneli ise saniye, 13 haneli ise milisaniye
        if (timestamp.toString().length == 10) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
        } else if (timestamp.toString().length == 13) {
          return DateTime.fromMillisecondsSinceEpoch(timestamp);
        }
      }
    } catch (e) {
      debugPrint('⚠️ Timestamp parse hatası: $e');
    }

    // Parse edilemezse şu anki zamanı kullan ama logla
    debugPrint(
      '⚠️ Tarih parse edilemedi: "$dateString", şu anki zaman kullanılıyor',
    );
    return DateTime.now();
  }

  /// Unique ID oluşturur - link, kaynak adı, başlık ve tarih bazlı
  /// UUID v5 kullanarak deterministic ve platform-bağımsız ID üretir
  /// Bu sayede aynı linkli haberler farklı kaynaklardan geldiğinde karışmaz
  static String _generateId(
    String link,
    String sourceName,
    String title,
    String pubDate,
  ) {
    const uuid = Uuid();
    // UUID v5: namespace + name bazlı deterministic UUID üretir
    // Aynı girdi her zaman aynı UUID'yi üretir (hashCode'dan farklı olarak platform bağımsız)
    final name = '$link|$sourceName|$title|$pubDate';
    return uuid.v5(Namespace.url.value, name);
  }

  @override
  String toString() {
    return 'ArticleModel{id: $id, title: $title, category: $category}';
  }
}
