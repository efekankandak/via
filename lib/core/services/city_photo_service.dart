import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Türkçe Wikipedia REST API üzerinden şehirlerin ana fotoğraflarını çeker.
/// Disk önbelleği (SharedPreferences) kullanır → ikinci açılıştan itibaren
/// tüm fotoğraflar anında gelir, hiç API çağrısı yapılmaz.
class WikipediaCityPhotoService {
  WikipediaCityPhotoService._();

  // ── Bellek Önbelleği ────────────────────────────────────────────
  static final Map<String, String> _memCache = {};
  static final Map<String, Future<String?>> _pending = {};

  // ── Disk Önbelleği ──────────────────────────────────────────────
  static const _diskKey = 'wiki_city_photos_v1';
  static SharedPreferences? _prefs;

  // ── İstek hız sınırlayıcı ───────────────────────────────────────
  static int _activeRequests = 0;
  static const _maxConcurrent = 1; // Wikimedia için 1 istek aynı anda
  static const _betweenRequestMs = 400; // İstekler arası bekleme

  /// Uygulama başlangıcında çağrılmalı.
  /// Disk önbelleğini belleğe yükler → anında fotoğraf.
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

  /// Şehir için fotoğraf URL'si döndürür.
  /// Sıra: bellek önbelleği → disk önbelleği → Wikipedia API
  static Future<String?> getPhotoUrl(String city) {
    final key = city.trim();
    if (_memCache.containsKey(key)) return Future.value(_memCache[key]);
    if (_pending.containsKey(key)) return _pending[key]!;

    final future = _throttledFetch(key);
    _pending[key] = future;
    future.then((url) {
      _pending.remove(key);
      if (url != null) {
        _memCache[key] = url;
        _persistCache(); // Diske kaydet
      }
    }).catchError((_) { _pending.remove(key); });

    return future;
  }

  /// Bellek önbelleğini diske yazar (uç çağrı: her yeni URL sonrası)
  static void _persistCache() {
    _prefs?.setString(_diskKey, json.encode(_memCache));
  }

  /// Önbelleği temizle (test/geliştirme için)
  static Future<void> clearCache() async {
    _memCache.clear();
    await _prefs?.remove(_diskKey);
  }

  static Future<String?> _throttledFetch(String city) async {
    while (_activeRequests >= _maxConcurrent) {
      await Future.delayed(const Duration(milliseconds: _betweenRequestMs));
    }
    _activeRequests++;
    try {
      // İstekler arası bekleme (Wikimedia rate limit koruması)
      await Future.delayed(const Duration(milliseconds: _betweenRequestMs));
      return await _fetchPhotoUrl(city);
    } finally {
      _activeRequests--;
    }
  }

  static Future<String?> _fetchPhotoUrl(String city) async {
    // 1. Türkçe Wikipedia
    final trTitle = _trWikipediaTitles[_norm(city)] ?? city;
    final trUrl = await _fetchFromWikipedia(trTitle, lang: 'tr');
    if (trUrl != null) return trUrl;

    // 2. İngilizce Wikipedia
    final enTitle = _enWikipediaTitles[_norm(city)] ?? '$city Turkey';
    return _fetchFromWikipedia(enTitle, lang: 'en');
  }

  static Future<String?> _fetchFromWikipedia(
      String title, {required String lang, int retries = 3}) async {
    for (int attempt = 0; attempt <= retries; attempt++) {
      try {
        final uri = Uri.parse(
          'https://$lang.wikipedia.org/api/rest_v1/page/summary/'
          '${Uri.encodeComponent(title)}',
        );
        final res = await http.get(uri, headers: {
          'User-Agent': 'SanalRehber/1.0 (Flutter seyahat uygulaması)',
          'Accept': 'application/json',
        }).timeout(const Duration(seconds: 10));

        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final thumb =
              (data['thumbnail'] as Map<String, dynamic>?)?['source'] as String?;
          if (thumb != null) {
            // Thumbnail'i 640px'e yükselt
            return thumb
                .replaceAll('/320px-', '/640px-')
                .replaceAll('/240px-', '/640px-')
                .replaceAll('/150px-', '/640px-');
          }
          return null;
        } else if (res.statusCode == 429) {
          // Rate limit: üstel bekleme
          final waitMs = 1000 * (attempt + 1);
          await Future.delayed(Duration(milliseconds: waitMs));
        } else {
          return null;
        }
      } catch (_) {
        if (attempt < retries) {
          await Future.delayed(Duration(milliseconds: 500 * (attempt + 1)));
        }
      }
    }
    return null;
  }

  static String _norm(String s) =>
      s.toLowerCase().trim()
       .replaceAll('ğ', 'g').replaceAll('ü', 'u')
       .replaceAll('ş', 's').replaceAll('ı', 'i')
       .replaceAll('ö', 'o').replaceAll('ç', 'c');

  // ── Türkçe Wikipedia başlıkları ─────────────────────────────────
  // Şehir arama sonucu anlamlı bir makaleye yönlensin diye
  // bazı iller için özel başlıklar tanımlanmış.
  static const Map<String, String> _trWikipediaTitles = {
    'adana'          : 'Adana',
    'adiyaman'       : 'Adıyaman',
    'afyonkarahisar' : 'Afyonkarahisar',
    'agri'           : 'Ağrı ili',
    'aksaray'        : 'Aksaray',
    'amasya'         : 'Amasya',
    'ankara'         : 'Ankara',
    'antalya'        : 'Antalya',
    'ardahan'        : 'Ardahan',
    'artvin'         : 'Artvin',
    'aydin'          : 'Aydın',
    'balikesir'      : 'Balıkesir',
    'bartin'         : 'Bartın',
    'batman'         : 'Batman, Türkiye',
    'bayburt'        : 'Bayburt',
    'bilecik'        : 'Bilecik',
    'bingol'         : 'Bingöl',
    'bitlis'         : 'Bitlis',
    'bolu'           : 'Bolu',
    'burdur'         : 'Burdur',
    'bursa'          : 'Bursa',
    'canakkale'      : 'Çanakkale',
    'cankiri'        : 'Çankırı',
    'corum'          : 'Çorum',
    'denizli'        : 'Pamukkale',         // Denizli yerine Pamukkale daha ikonik
    'diyarbakir'     : 'Diyarbakır',
    'duzce'          : 'Düzce',
    'edirne'         : 'Edirne',
    'elazig'         : 'Elazığ',
    'erzincan'       : 'Erzincan',
    'erzurum'        : 'Erzurum',
    'eskisehir'      : 'Eskişehir',
    'gaziantep'      : 'Gaziantep',
    'giresun'        : 'Giresun',
    'gumushane'      : 'Gümüşhane',
    'hakkari'        : 'Hakkari',
    'hatay'          : 'Antakya',           // Hatay yerine Antakya daha ikonik
    'igdir'          : 'Iğdır',
    'isparta'        : 'Isparta',
    'istanbul'       : 'İstanbul',
    'izmir'          : 'İzmir',
    'kahramanmaras'  : 'Kahramanmaraş',
    'karabuk'        : 'Safranbolu',        // Karabük yerine Safranbolu daha ikonik
    'karaman'        : 'Karaman',
    'kars'           : 'Kars',
    'kastamonu'      : 'Kastamonu',
    'kayseri'        : 'Kayseri',
    'kilis'          : 'Kilis',
    'kirikkale'      : 'Kırıkkale',
    'kirklareli'     : 'Kırklareli',
    'kirsehir'       : 'Kırşehir',
    'kocaeli'        : 'İzmit',
    'konya'          : 'Mevlânâ Müzesi',    // Konya'nın sembolü
    'kutahya'        : 'Kütahya',
    'malatya'        : 'Malatya',
    'manisa'         : 'Manisa',
    'mardin'         : 'Mardin',
    'mersin'         : 'Mersin',
    'mugla'          : 'Bodrum',            // Muğla yerine Bodrum daha ikonik
    'mus'            : 'Muş',
    'nevsehir'       : 'Kapadokya',         // Nevşehir = Kapadokya
    'kapadokya'      : 'Kapadokya',
    'nigde'          : 'Niğde',
    'ordu'           : 'Ordu',
    'osmaniye'       : 'Osmaniye',
    'rize'           : 'Rize',
    'sakarya'        : 'Sakarya',
    'samsun'         : 'Samsun',
    'siirt'          : 'Siirt',
    'sinop'          : 'Sinop',
    'sivas'          : 'Sivas',
    'sanliurfa'      : 'Göbekli Tepe',      // Urfa'nın sembolü
    'sirnak'         : 'Şırnak',
    'tekirdag'       : 'Tekirdağ',
    'tokat'          : 'Tokat',
    'trabzon'        : 'Sümela Manastırı',  // Trabzon'un sembolü
    'tunceli'        : 'Munzur Vadisi',
    'usak'           : 'Uşak',
    'van'            : 'Akdamar Kilisesi',  // Van Gölü kilisesi
    'yalova'         : 'Yalova',
    'yozgat'         : 'Yozgat',
    'zonguldak'      : 'Zonguldak',
  };

  // ── İngilizce Wikipedia fallback başlıkları ──────────────────────
  static const Map<String, String> _enWikipediaTitles = {
    'istanbul'       : 'Istanbul',
    'kapadokya'      : 'Cappadocia',
    'nevsehir'       : 'Cappadocia',
    'trabzon'        : 'Sümela Monastery',
    'mardin'         : 'Mardin',
    'van'            : 'Akdamar Island',
    'diyarbakir'     : 'Diyarbakır',
    'sanliurfa'      : 'Göbekli Tepe',
    'adiyaman'       : 'Mount Nemrut',
    'hatay'          : 'Antakya',
    'denizli'        : 'Pamukkale',
    'mugla'          : 'Bodrum',
    'karabuk'        : 'Safranbolu',
    'konya'          : 'Mevlana Museum',
    'edirne'         : 'Edirne',
    'kars'           : 'Ani, Turkey',
    'agri'           : 'Mount Ararat',
    'igdir'          : 'Mount Ararat',
    'antalya'        : 'Antalya',
    'gaziantep'      : 'Zeugma Mosaic Museum',
    'isparta'        : 'Isparta',
    'bursa'          : 'Bursa',
    'izmir'          : 'Izmir',
    'eskisehir'      : 'Odunpazarı',
    'amasya'         : 'Amasya',
    'rize'           : 'Rize',
    'artvin'         : 'Artvin Province',
  };

  // ── Türkiye'nin 81 ili ───────────────────────────────────────────
  static const List<String> turkeyProvinces = [
    'Adana', 'Adıyaman', 'Afyonkarahisar', 'Ağrı', 'Aksaray',
    'Amasya', 'Ankara', 'Antalya', 'Ardahan', 'Artvin',
    'Aydın', 'Balıkesir', 'Bartın', 'Batman', 'Bayburt',
    'Bilecik', 'Bingöl', 'Bitlis', 'Bolu', 'Burdur',
    'Bursa', 'Çanakkale', 'Çankırı', 'Çorum', 'Denizli',
    'Diyarbakır', 'Düzce', 'Edirne', 'Elazığ', 'Erzincan',
    'Erzurum', 'Eskişehir', 'Gaziantep', 'Giresun', 'Gümüşhane',
    'Hakkari', 'Hatay', 'Iğdır', 'Isparta', 'İstanbul',
    'İzmir', 'Kahramanmaraş', 'Karabük', 'Karaman', 'Kars',
    'Kastamonu', 'Kayseri', 'Kilis', 'Kırıkkale', 'Kırklareli',
    'Kırşehir', 'Kocaeli', 'Konya', 'Kütahya', 'Malatya',
    'Manisa', 'Mardin', 'Mersin', 'Muğla', 'Muş',
    'Nevşehir', 'Niğde', 'Ordu', 'Osmaniye', 'Rize',
    'Sakarya', 'Samsun', 'Siirt', 'Sinop', 'Sivas',
    'Şanlıurfa', 'Şırnak', 'Tekirdağ', 'Tokat', 'Trabzon',
    'Tunceli', 'Uşak', 'Van', 'Yalova', 'Yozgat',
    'Zonguldak',
  ];

  static List<String> searchProvinces(String query) {
    if (query.isEmpty) return turkeyProvinces;
    final q = _norm(query);
    return turkeyProvinces.where((c) => _norm(c).contains(q)).toList();
  }
}
