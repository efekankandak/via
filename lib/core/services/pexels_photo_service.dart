import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Pexels API üzerinden şehirlere özel fotoğraflar çeker.
/// İlk açılışta indirir, sonra disk önbelleğinden anında yükler.
class PexelsCityPhotoService {
  PexelsCityPhotoService._();

  // ── Pexels API Key ──────────────────────────────────────────
  // https://www.pexels.com/api/ adresinden ücretsiz alın
  static const _apiKey =
      'flCl480l5LpgStRpwcdpS478jLbvDqlLRhcJEtlzdT0NwVfo4ywZ9YDz';
  static const _baseUrl = 'https://api.pexels.com/v1/search';

  // ── Disk Önbelleği ──────────────────────────────────────────
  static const _diskKey = 'pexels_city_photos_v5';
  static SharedPreferences? _prefs;
  static final Map<String, String> _memCache = {};
  static final Map<String, Future<String?>> _pending = {};

  /// Uygulama başlangıcında çağrılmalı — disk önbelleğini yükler
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_diskKey);
    if (raw != null) {
      try {
        final map = json.decode(raw) as Map<String, dynamic>;
        _memCache.addAll(map.cast<String, String>());
      } catch (_) {}
    }
  }

  /// Şehir için fotoğraf URL döndürür
  /// Sıra: bellek → disk → Pexels API
  static Future<String?> getPhotoUrl(String city) {
    final key = city.trim();
    if (_memCache.containsKey(key)) return Future.value(_memCache[key]);
    if (_pending.containsKey(key)) return _pending[key]!;

    final future = _fetchPhotoUrl(key);
    _pending[key] = future;
    future.then((url) {
      _pending.remove(key);
      if (url != null) {
        _memCache[key] = url;
        _prefs?.setString(_diskKey, json.encode(_memCache));
      }
    }).catchError((_) { _pending.remove(key); });

    return future;
  }

  /// Mekan fotoğrafı URL'si döndürür.
  /// [photoQuery]: Gemini tarafından üretilen İngilizce arama sorgusu (varsa direkt kullanılır)
  /// [placeName]: Mekan adı (Wikipedia araması için)
  /// [category]: Kategori (fallback Pexels araması için)
  /// [city]: Mekanın bulunduğu şehir (Wikipedia aramasını özelleştirmek için)
  static Future<String?> getPlacePhotoUrl(
    String placeName, {
    String? photoQuery,
    String? category,
    String? city,
  }) {
    // "Sabah: Koza Han" veya "1. Gün Sabah: Koza Han" → "Koza Han" temizliği
    final cleanName = placeName
        .replaceAll(RegExp(r'^(?:[0-9]+\.?\s*)?(Sabah|Öğle|Öğleden Sonra|Akşam|Gece|Aktivite|Etkinlik|Gün)[\s:-]+', caseSensitive: false), '')
        .trim();

    // Önbellek anahtarı: photoQuery veya şehir bilgisine göre
    final cacheKey = 'place:${photoQuery ?? cleanName}_${city ?? ''}';
    if (_memCache.containsKey(cacheKey)) return Future.value(_memCache[cacheKey]);
    if (_pending.containsKey(cacheKey)) return _pending[cacheKey]!;

    final future = _fetchPlacePhoto(cleanName, category: category, photoQuery: photoQuery, city: city);
    _pending[cacheKey] = future;
    future.then((url) {
      _pending.remove(cacheKey);
      if (url != null) {
        _memCache[cacheKey] = url;
        _prefs?.setString(_diskKey, json.encode(_memCache));
      }
    }).catchError((_) { _pending.remove(cacheKey); });

    return future;
  }

  static Future<String?> _fetchPlacePhoto(
    String placeName, {
    String? category,
    String? photoQuery,
    String? city,
  }) async {
    // ── TURKISH WIKIPEDIA SEARCHES ──
    // 1. Wikipedia TR — Şehir detaylı arama (Örn: "Yeşil Cami (Bursa)")
    if (city != null && city.isNotEmpty) {
      final trWikiCity = await _fetchWikipediaImage('$placeName ($city)', 'tr', city: city, searchedPlace: placeName);
      if (trWikiCity != null) return trWikiCity;
    }

    // 2. Wikipedia TR — Düz arama (Örn: "Koza Han")
    final trWiki = await _fetchWikipediaImage(placeName, 'tr', city: city, searchedPlace: placeName);
    if (trWiki != null) return trWiki;

    // 3. Wikipedia TR — Şehir birleşik arama (Örn: "Tophane Parkı Bursa")
    if (city != null && city.isNotEmpty) {
      final trWikiSpaceCity = await _fetchWikipediaImage('$placeName $city', 'tr', city: city, searchedPlace: placeName);
      if (trWikiSpaceCity != null) return trWikiSpaceCity;
    }

    // ── ENGLISH WIKIPEDIA SEARCHES (FALLBACK) ──
    // 4. Wikipedia EN — Şehir detaylı arama (Örn: "Yeşil Cami (Bursa)")
    if (city != null && city.isNotEmpty) {
      final enWikiCity = await _fetchWikipediaImage('$placeName ($city)', 'en', city: city, searchedPlace: placeName);
      if (enWikiCity != null) return enWikiCity;
    }

    // 5. Wikipedia EN — Düz arama (Örn: "Koza Han")
    final enWiki = await _fetchWikipediaImage(placeName, 'en', city: city, searchedPlace: placeName);
    if (enWiki != null) return enWiki;

    // 6. Wikipedia EN — Şehir birleşik arama (Örn: "Tophane Parkı Bursa")
    if (city != null && city.isNotEmpty) {
      final enWikiSpaceCity = await _fetchWikipediaImage('$placeName $city', 'en', city: city, searchedPlace: placeName);
      if (enWikiSpaceCity != null) return enWikiSpaceCity;
    }

    // ── PEXELS FALLBACKS ──
    // 7. Gemini'nin ürettiği detaylı İngilizce photoQuery varsa — Pexels araması
    if (photoQuery != null && photoQuery.isNotEmpty) {
      final url = await _pexelsSearch(photoQuery);
      if (url != null) return url;
    }

    // 8. Kategori bazlı Pexels — Yukarıdakilerin hepsi başarısız olursa garanti resim döner
    return await _fetchCategoryPhoto(category);
  }

  /// Wikipedia Commons — mekan adına göre arama yapıp doğrulanmış kapak fotoğrafı getirir
  static Future<String?> _fetchWikipediaImage(
    String queryTitle, 
    String lang, {
    String? city,
    required String searchedPlace,
  }) async {
    try {
      final encoded = Uri.encodeComponent(queryTitle);
      final uri = Uri.parse(
        'https://$lang.wikipedia.org/w/api.php'
        '?action=query&generator=search&gsrsearch=$encoded&gsrlimit=1'
        '&prop=pageimages&format=json&pithumbsize=960&redirects=1',
      );

      final response = await http.get(uri, headers: {
        'User-Agent': 'SanalRehber/1.0 (contact@sanalrehber.app)',
      }).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final pages = data['query']?['pages'] as Map<String, dynamic>?;
        if (pages != null) {
          for (final page in pages.values) {
            if (page['pageid'] == -1 || page['pageid'] == null) continue;
            final matchTitle = page['title'] as String?;
            
            if (matchTitle != null) {
              final normalizedMatch = _normalizeForMatch(matchTitle);

              // 1. Reddet: Sayfa başlığı sadece şehir adı veya şehir tanımı ise (Örn: aranan "Kurşunlu Han" ama eşleşen "Bursa")
              if (city != null && city.isNotEmpty) {
                final normalizedCity = _normalizeForMatch(city);
                if (normalizedMatch == normalizedCity || 
                    normalizedMatch == '$normalizedCity sehir' || 
                    normalizedMatch == '$normalizedCity il' ||
                    normalizedMatch == '$normalizedCity turkey' ||
                    normalizedMatch == '$normalizedCity turkiye') {
                  continue;
                }
              }

              // 2. Reddet: Aranan asıl mekan isminden en az bir benzersiz kelime barındırmıyorsa
              // (şehir ismini temizleyelim ki sadece şehir adı eşleşmesinden kurtulalım)
              String cleanSearchedPlace = searchedPlace;
              if (city != null && city.isNotEmpty) {
                cleanSearchedPlace = searchedPlace.replaceAll(RegExp(city, caseSensitive: false), '');
              }
              
              final cleanSearch = _normalizeForMatch(cleanSearchedPlace).trim();
              final searchWords = cleanSearch.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
              
              bool hasWordMatch = false;
              for (final word in searchWords) {
                if (normalizedMatch.contains(word)) {
                  hasWordMatch = true;
                  break;
                }
              }

              if (!hasWordMatch && searchWords.isNotEmpty) {
                continue;
              }

              final thumb = page['thumbnail'] as Map<String, dynamic>?;
              if (thumb != null) {
                final source = thumb['source'] as String?;
                if (source != null) {
                  return source;
                }
              }
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  static String _normalizeForMatch(String s) {
    return s
        .toLowerCase()
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ı', 'i')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  /// Tek seferlik Pexels araması (hem photoQuery hem kategori için kullanılır)
  static Future<String?> _pexelsSearch(String query, {int count = 10}) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl?query=${Uri.encodeComponent(query)}&per_page=$count&orientation=landscape',
      );
      final response = await http.get(uri, headers: {
        'Authorization': _apiKey,
      }).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final photos = data['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          // İlk 3'ten rastgele seç (en alakalı sonuçlar)
          final pickFrom = photos.length > 3 ? 3 : photos.length;
          final rnd = DateTime.now().millisecondsSinceEpoch % pickFrom;
          final src = photos[rnd]['src'] as Map<String, dynamic>?;
          return src?['large2x'] as String? ?? src?['large'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Kategori bazlı Pexels — geniş sorgular, her zaman sonuç döndürür
  static Future<String?> _fetchCategoryPhoto(String? category) async {
    const categoryQueries = <String, String>{
      'Tarihi Yapı':    'ancient Ottoman historic building Turkey castle ruins',
      'Müze':           'Turkey museum exhibition cultural art interior',
      'Doğa & Manzara': 'Turkey scenic nature landscape mountains valley',
      'Yemek & Mutfak': 'Turkish food cuisine restaurant kebab baklava',
      'Alışveriş':      'Turkey bazaar grand market shopping traditional',
      'Dini Yapı':      'Turkey mosque minaret Islamic architecture blue',
      'Park & Bahçe':   'Turkey park garden nature botanical flowers',
      'Eğlence':        'Turkey entertainment festival performance street',
      'Sanat & Kültür': 'Turkey art culture festival dance performance',
      'Çarşı & Pazar':  'Turkey traditional bazaar market spices colorful',
    };

    final query = categoryQueries[category] ?? 'Turkey travel landmark beautiful historic';
    return _pexelsSearch(query);
  }

  static Future<String?> _fetchPhotoUrl(String city) async {
    try {
      final query = _buildQuery(city);
      final uri = Uri.parse(
        '$_baseUrl?query=${Uri.encodeComponent(query)}&per_page=5&orientation=landscape&size=large',
      );

      final response = await http.get(uri, headers: {
        'Authorization': _apiKey,
      }).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final photos = data['photos'] as List?;
        if (photos != null && photos.isNotEmpty) {
          final src = photos[0]['src'] as Map<String, dynamic>?;
          // large2x = 940px, large = 650px
          return src?['large2x'] as String? ?? src?['large'] as String?;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Şehir için Pexels'ta en iyi sonucu verecek arama sorgusu
  static String _buildQuery(String city) {
    const queries = <String, String>{
      'İstanbul': 'Istanbul Turkey Bosphorus skyline',
      'Ankara': 'Ankara Turkey Ataturk Mausoleum Anitkabir',
      'İzmir': 'Izmir Turkey waterfront Kordon bay',
      'Antalya': 'Antalya Turkey old town harbor marina',
      'Adana': 'Adana Turkey Seyhan river stone bridge',
      'Bursa': 'Bursa Turkey Grand Mosque Uludag',
      'Gaziantep': 'Gaziantep Turkey mosaic zeugma historic',
      'Konya': 'Konya Turkey Mevlana Museum Rumi',
      'Kayseri': 'Kayseri Turkey Erciyes mountain historic',
      'Trabzon': 'Trabzon Turkey Sumela Monastery Black Sea',
      'Samsun': 'Samsun Turkey Black Sea coast promenade',
      'Mersin': 'Mersin Turkey Mediterranean harbor',
      'Diyarbakır': 'Diyarbakir Turkey ancient walls basalt',
      'Hatay': 'Hatay Turkey ancient Roman mosaic',
      'Manisa': 'Manisa Turkey Spil mountain historic mosque',
      'Kocaeli': 'Kocaeli Turkey Izmit bay industrial',
      'Sakarya': 'Sakarya Turkey green nature river',
      'Balıkesir': 'Balikesir Turkey Ayvalik olive groves Aegean',
      'Kahramanmaraş': 'Kahramanmaras Turkey castle scenic',
      'Van': 'Van Turkey lake castle historic',
      'Şanlıurfa': 'Sanliurfa Turkey Gobekli Tepe ancient ruins',
      'Denizli': 'Pamukkale Turkey white travertine terraces thermal',
      'Muğla': 'Mugla Turkey turquoise sea Aegean coast',
      'Aydın': 'Aydin Turkey Ephesus ancient ruins',
      'Edirne': 'Edirne Turkey Selimiye Mosque Ottoman',
      'Tekirdağ': 'Tekirdag Turkey Marmara Sea coast vineyard',
      'Eskişehir': 'Eskisehir Turkey Porsuk river tram modern',
      'Mardin': 'Mardin Turkey old city stone houses hilltop',
      'Erzurum': 'Erzurum Turkey castle historic Ottoman',
      'Malatya': 'Malatya Turkey apricot valley landscape',
      'Elazığ': 'Elazig Turkey Keban dam lake scenic',
      'Kars': 'Kars Turkey Ani ancient ruins Armenia',
      'Adıyaman': 'Nemrut Turkey mountain stone statues heads',
      'Çorum': 'Corum Turkey Hittite Hattusa ruins ancient',
      'Sivas': 'Sivas Turkey Gok Medrese Seljuk architecture',
      'Amasya': 'Amasya Turkey Yesilirmak river rock tombs',
      'Tokat': 'Tokat Turkey Yildizeli river valley castle',
      'Ordu': 'Ordu Turkey Black Sea coast hazelnut mountains',
      'Giresun': 'Giresun Turkey Black Sea cliff coast',
      'Rize': 'Rize Turkey tea gardens green mountains',
      'Artvin': 'Artvin Turkey mountain valley Coruh river',
      'Ardahan': 'Ardahan Turkey highland plateau grassland',
      'Iğdır': 'Igdir Turkey Mount Ararat snow peak',
      'Ağrı': 'Agri Turkey Ararat mountain volcano snow',
      'Bitlis': 'Bitlis Turkey castle historic mountain',
      'Hakkari': 'Hakkari Turkey mountain Zap valley',
      'Şırnak': 'Sirnak Turkey Cudi mountain landscape',
      'Siirt': 'Siirt Turkey historic mosque pistachio',
      'Batman': 'Batman Turkey Tigris river historic',
      'Urfa': 'Sanliurfa Turkey Balikligol sacred fish lake',
      'Bingöl': 'Bingol Turkey green mountains river valley',
      'Muş': 'Mus Turkey Malazgirt plain historic',
      'Tunceli': 'Tunceli Turkey Munzur river nature reserve',
      'Erzincan': 'Erzincan Turkey Euphrates valley mountain',
      'Gümüşhane': 'Gumushane Turkey historic silver mines mountain',
      'Bayburt': 'Bayburt Turkey castle Coruh river canyon',
      'Kastamonu': 'Kastamonu Turkey historic wooden Ottoman house',
      'Sinop': 'Sinop Turkey Black Sea peninsula lighthouse',
      'Bartın': 'Bartin Turkey Amasra castle Kastro ancient',
      'Karabük': 'Karabuk Turkey Safranbolu historic Ottoman houses',
      'Zonguldak': 'Zonguldak Turkey Black Sea cliff coast',
      'Düzce': 'Duzce Turkey forest mountain nature',
      'Bolu': 'Bolu Turkey Golcuk lake forest scenic',
      'Yalova': 'Yalova Turkey thermal spa Marmara',
      'Kırklareli': 'Kirklareli Turkey Thrace sunflower fields',
      'Çanakkale': 'Canakkale Turkey Gallipoli Troy ancient',
      'Bilecik': 'Bilecik Turkey Ottoman bridge historic Sogut',
      'Kütahya': 'Kutahya Turkey blue ceramic tile pottery',
      'Afyonkarahisar': 'Afyon Turkey limestone castle poppy fields',
      'Isparta': 'Isparta Turkey rose fields Egirdir lake',
      'Burdur': 'Burdur Turkey lake travertine limestone',
      'Karaman': 'Karaman Turkey historic Karamanid mosque',
      'Niğde': 'Nigde Turkey Cappadocia landscape underground',
      'Nevşehir': 'Nevsehir Turkey Cappadocia fairy chimneys balloons',
      'Aksaray': 'Aksaray Turkey Ihlara valley volcanic landscape',
      'Kırşehir': 'Kirsehir Turkey Ahi Evran mosque historic',
      'Kırıkkale': 'Kirikkale Turkey Kizilirmak river valley',
      'Çankırı': 'Cankiri Turkey salt lake Tuz Golu',
      'Yozgat': 'Yozgat Turkey Anatolian plateau landscape',
      'Uşak': 'Usak Turkey Aegean olive landscape ancient',
      'İçel': 'Mersin Turkey Mediterranean harbor lighthouse',
      'Osmaniye': 'Osmaniye Turkey Karatepe Hittite ruins',
    };

    return queries[city] ?? '$city Turkey landmark travel scenic';
  }

  // ── Türkiye'nin 81 ili ───────────────────────────────────────────────────
  static const List<String> turkeyProvinces = [
    'Adana',
    'Adıyaman',
    'Afyonkarahisar',
    'Ağrı',
    'Aksaray',
    'Amasya',
    'Ankara',
    'Antalya',
    'Ardahan',
    'Artvin',
    'Aydın',
    'Balıkesir',
    'Bartın',
    'Batman',
    'Bayburt',
    'Bilecik',
    'Bingöl',
    'Bitlis',
    'Bolu',
    'Burdur',
    'Bursa',
    'Çanakkale',
    'Çankırı',
    'Çorum',
    'Denizli',
    'Diyarbakır',
    'Düzce',
    'Edirne',
    'Elazığ',
    'Erzincan',
    'Erzurum',
    'Eskişehir',
    'Gaziantep',
    'Giresun',
    'Gümüşhane',
    'Hakkari',
    'Hatay',
    'Iğdır',
    'Isparta',
    'İstanbul',
    'İzmir',
    'Kahramanmaraş',
    'Karabük',
    'Karaman',
    'Kars',
    'Kastamonu',
    'Kayseri',
    'Kilis',
    'Kırıkkale',
    'Kırklareli',
    'Kırşehir',
    'Kocaeli',
    'Konya',
    'Kütahya',
    'Malatya',
    'Manisa',
    'Mardin',
    'Mersin',
    'Muğla',
    'Muş',
    'Nevşehir',
    'Niğde',
    'Ordu',
    'Osmaniye',
    'Rize',
    'Sakarya',
    'Samsun',
    'Siirt',
    'Sinop',
    'Sivas',
    'Şanlıurfa',
    'Şırnak',
    'Tekirdağ',
    'Tokat',
    'Trabzon',
    'Tunceli',
    'Uşak',
    'Van',
    'Yalova',
    'Yozgat',
    'Zonguldak',
  ];

  static String _norm(String s) => s
      .toLowerCase()
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ı', 'i')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  static List<String> searchProvinces(String query) {
    if (query.isEmpty) return turkeyProvinces;
    final q = _norm(query);
    return turkeyProvinces.where((c) => _norm(c).contains(q)).toList();
  }
}
