import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../../core/constants/app_colors.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

class ChatScreen extends StatefulWidget {
  final String? tripId;
  final String? placeName;
  final String? city;
  final String? tripTheme;
  final String? initialMessage;

  const ChatScreen({
    super.key,
    this.tripId,
    this.placeName,
    this.city,
    this.tripTheme,
    this.initialMessage,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();
  bool _isLoading = false;
  String? _currentlySpeakingIndex; // Hangi mesajın okunduğunu takip etmek için

  @override
  void initState() {
    super.initState();
    _initTts();

    // Hoş geldin mesajı ekle
    final welcomeText = widget.placeName != null
        ? 'Merhaba! Ben seyahat rehberiniz Via. "${widget.placeName}" hakkında merak ettiğiniz tarihi detayları, ilginç bilgileri veya yakın çevrede yapabileceğiniz aktiviteleri bana sorabilirsiniz.'
        : 'Merhaba! Ben seyahat rehberiniz Via. Planınızdaki şehirler, gezilecek yerler veya rotanız hakkında aklınıza takılan her şeyi bana sorabilirsiniz. Size yardımcı olmaktan mutluluk duyarım!';
    
    _messages.add(ChatMessage(
      text: welcomeText,
      isUser: false,
      timestamp: DateTime.now(),
    ));

    // Eğer başlangıçta otomatik bir mesaj gönderilmek istendiyse (örn: Yağmur uyarısına tıklandığında)
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleSubmitted(widget.initialMessage!);
      });
    }
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('tr-TR');
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);

    _tts.setCompletionHandler(() {
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    });

    _tts.setErrorHandler((msg) {
      if (mounted) {
        setState(() {
          _currentlySpeakingIndex = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _tts.stop();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _toggleTts(String text, String messageId) async {
    if (_currentlySpeakingIndex == messageId) {
      await _tts.stop();
      setState(() {
        _currentlySpeakingIndex = null;
      });
    } else {
      await _tts.stop();
      setState(() {
        _currentlySpeakingIndex = messageId;
      });
      await _tts.speak(text);
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _controller.clear();

    final userMessage = ChatMessage(
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.add(userMessage);
      _isLoading = true;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    try {
      // Vertex AI formatına uydurulmuş konuşma geçmişi
      final chatHistory = _messages.map((m) {
        return {
          'role': m.isUser ? 'user' : 'model',
          'parts': [{'text': m.text}],
        };
      }).toList();

      // Cloud Function çağrısı
      final callable = FirebaseFunctions.instance.httpsCallable('chatWithGuide');
      final response = await callable.call({
        'messages': chatHistory,
        'placeName': widget.placeName,
        'city': widget.city,
        'tripTheme': widget.tripTheme,
      });

      final reply = response.data['response'] as String? ?? 'Yazacak bir şey bulamadım.';
      _addAiResponse(reply);
    } catch (e) {
      // ignore: avoid_print
      print('Cloud Function sohbet hatası, fallback devreye giriyor: $e');
      
      // Akıllı Fallback mekanizması (Çevrimdışı/Deploy edilmemiş durumlar için)
      _handleFallbackResponse(text);
    }
  }

  void _addAiResponse(String reply) {
    if (!mounted) return;
    setState(() {
      _messages.add(ChatMessage(
        text: reply,
        isUser: false,
        timestamp: DateTime.now(),
      ));
      _isLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  void _handleFallbackResponse(String text) {
    Future.delayed(const Duration(milliseconds: 1000), () {
      if (!mounted) return;
      String reply = 'Size yardımcı olmak isterim ama şu an sunucu bağlantısını kuramıyorum.';
      final lowerText = text.toLowerCase().trim();

      // Önceki asistan mesajını kontrol et
      String? lastAiMessage;
      for (int i = _messages.length - 2; i >= 0; i--) {
        if (!_messages[i].isUser) {
          lastAiMessage = _messages[i].text;
          break;
        }
      }

      final isConfirming = lowerText == 'olur' || 
          lowerText == 'evet' || 
          lowerText == 'tamam' || 
          lowerText == 'olabilir' || 
          lowerText == 'çiz' ||
          lowerText == 'peki';

      final wasLastMessageAboutRain = lastAiMessage != null && 
          (lastAiMessage.contains('yağmur') || lastAiMessage.contains('kapalı'));

      if (isConfirming && wasLastMessageAboutRain) {
        reply = 'Harika! ${widget.city ?? 'Bu şehirde'} yağmurlu havaya özel kapalı mekan seyahat rotasını çizdim:\n\n'
            '1. 🏛️ **Odunpazarı Modern Müze (OMM):** Çağdaş sanat eserleriyle güne harika bir başlangıç yapın.\n'
            '2. ⛪ **Kurşunlu Külliyesi:** Tarihi külliyeyi gezerek sıcak cam üfleme atölyelerini izleyin.\n'
            '3. 🏛️ **Yılmaz Büyükerşen Balmumu Heykeller Müzesi:** Eğlenceli balmumu heykellerini inceleyin.\n'
            '4. ☕ **Tarihi Karakedi Bozacısı:** Meşhur bozayı yerinde deneyerek keyifli bir mola verin.\n\n'
            'Bu alternatif rotayı gezi planınıza uygulamak veya detaylarını öğrenmek ister misiniz?';
      } else if (lowerText.contains('yağmur') || lowerText.contains('kapalı') || lowerText.contains('alternatif')) {
        reply = 'Yağmurlu havalarda seyahatinizi bölmek istemem! ${widget.city ?? 'Bu şehirde'} şu kapalı mekanları gezmenizi önerebilirim:\n\n'
            '1. 🏛️ **Şehir Müzesi veya Sanat Galerileri:** Hem kültürel bir deneyim sunar hem de yağmurdan tamamen korur.\n'
            '2. ☕ **Tarihi Kahveciler & Kafeler:** Yerel lezzetleri denerken yağmurun dinmesini bekleyebilirsiniz.\n'
            '3. 🛍️ **Kapalı Tarihi Çarşılar:** Yağmura yakalanmadan alışveriş yapıp tarihi dokuyu inceleyebilirsiniz.\n\n'
            'Planınızdaki açık hava etkinliklerini ertelemek isterseniz seve seve alternatif rotalar çizebilirim!';
      } else if (widget.placeName != null) {
        reply = '"${widget.placeName}" gerçekten büyüleyici bir yerdir. Tarihi ve mimari dokusu hakkında bilmek istediğiniz özel bir detay var mı? Ya da giriş saatleri ve ipuçları hakkında bilgi verebilirim.';
      } else {
        reply = 'Seyahat asistanınız Via olarak size yardımcı olmak harika! ${widget.city != null ? '${widget.city} şehrindeki gezilecek yerler' : 'Rotanızdaki duraklar'} hakkında bilgi verebilirim veya restoran önerilerinde bulunabilirim. Ne sormak istersiniz?';
      }

      _addAiResponse(reply);
    });
  }

  List<TextSpan> _parseMarkdown(String text, TextStyle baseStyle) {
    final List<TextSpan> spans = [];
    final RegExp regex = RegExp(r'\*\*(.*?)\*\*');
    int start = 0;

    for (final Match match in regex.allMatches(text)) {
      if (match.start > start) {
        spans.add(TextSpan(
          text: text.substring(start, match.start),
          style: baseStyle,
        ));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: baseStyle.copyWith(fontWeight: FontWeight.bold),
      ));
      start = match.end;
    }

    if (start < text.length) {
      spans.add(TextSpan(
        text: text.substring(start),
        style: baseStyle,
      ));
    }

    return spans;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Apple True Black
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Seyahat Asistanı',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'Via (Gemini 2.5 Flash)',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: const [
          SizedBox(width: 48),
        ],
        shape: const Border(
          bottom: BorderSide(
            color: Color(0xFF1C1C1E),
            width: 0.5,
          ),
        ),
      ) as PreferredSizeWidget?,
      body: SafeArea(
        child: Column(
          children: [
            // Mesaj Listesi
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                itemCount: _messages.length + (_isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == _messages.length) {
                    return _buildLoadingBubble();
                  }
                  final message = _messages[index];
                  final messageId = 'msg_$index';
                  return _buildMessageRow(message, messageId);
                },
              ),
            ),

            // Giriş Alanı
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageRow(ChatMessage message, String messageId) {
    final isUser = message.isUser;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Column(
        crossAxisAlignment:
            isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment:
                isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                // Via Logosu (Avatar)
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1C1C1E),
                    shape: BoxShape.circle,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.asset(
                      'assets/images/app_logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    // iMessage tarzı mavi veya gri renkler
                    color: isUser
                        ? AppColors.primary
                        : const Color(0xFF1C1C1E), // systemGray6
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(20),
                      topRight: const Radius.circular(20),
                      bottomLeft: isUser
                          ? const Radius.circular(20)
                          : const Radius.circular(4), // iOS iMessage kuyruğu
                      bottomRight: isUser
                          ? const Radius.circular(4)
                          : const Radius.circular(20),
                    ),
                  ),
                  child: RichText(
                    text: TextSpan(
                      children: _parseMarkdown(
                        message.text,
                        GoogleFonts.inter(
                          fontSize: 16,
                          color: Colors.white,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Asistan mesajlarının altına sesli dinleme ikonu ekle
          if (!isUser) ...[
            Padding(
              padding: const EdgeInsets.only(left: 36, top: 4),
              child: InkWell(
                onTap: () => _toggleTts(message.text, messageId),
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _currentlySpeakingIndex == messageId
                            ? CupertinoIcons.stop_circle_fill
                            : CupertinoIcons.volume_up,
                        size: 16,
                        color: _currentlySpeakingIndex == messageId
                            ? AppColors.primary
                            : Colors.white54,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _currentlySpeakingIndex == messageId
                            ? 'Durdur'
                            : 'Sesli Dinle',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: _currentlySpeakingIndex == messageId
                              ? AppColors.primary
                              : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingBubble() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              shape: BoxShape.circle,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: Image.asset(
                'assets/images/app_logo.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFF1C1C1E),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: const CupertinoActivityIndicator(color: Colors.white54),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: Color(0xFF1C1C1E),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: CupertinoTextField(
              controller: _controller,
              cursorColor: AppColors.primary,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 15),
              placeholder: 'Sorunuzu buraya yazın...',
              placeholderStyle: GoogleFonts.inter(color: Colors.white30, fontSize: 15),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF1C1C1E), // systemGray6
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFF2C2C2E),
                  width: 0.5,
                ),
              ),
              onSubmitted: _handleSubmitted,
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(
              CupertinoIcons.arrow_up_circle_fill,
              size: 32,
              color: AppColors.primary,
            ),
            onPressed: () => _handleSubmitted(_controller.text),
          ),
        ],
      ),
    );
  }
}
