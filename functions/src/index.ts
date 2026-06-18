import * as admin from "firebase-admin";
import * as functions from "firebase-functions/v1";
import { VertexAI } from "@google-cloud/vertexai";

// Firebase Admin başlat
if (admin.apps.length === 0) {
  admin.initializeApp();
}

const db = admin.firestore();

// Firebase proje ID'si (Vertex AI için)
const PROJECT_ID = process.env.GCLOUD_PROJECT || "sanalrehber-20b8e";
const LOCATION   = "us-central1";

// ─────────────────────────────────────────────────────────────
// YARDIMCI FONKSIYONLAR
// ─────────────────────────────────────────────────────────────

/**
 * Vertex AI — Gemini 2.5 Flash
 * Firebase service account kullanır, API key gerekmez.
 */
async function callGemini(prompt: string, jsonMode = true): Promise<string> {
  const vertex = new VertexAI({ project: PROJECT_ID, location: LOCATION });

  const model = vertex.getGenerativeModel({
    model: "gemini-2.5-flash",
    generationConfig: {
      temperature: 0.7,
      topP: 0.95,
      maxOutputTokens: 32768, // JSON truncation'u önlemek için yüksek limit
      responseMimeType: jsonMode ? "application/json" : "text/plain",
    },
  });

  const request = {
    contents: [{ role: "user" as const, parts: [{ text: prompt }] }],
  };

  const response = await model.generateContent(request);
  const candidate = response.response.candidates?.[0];

  // Truncation kontrolü
  if (candidate?.finishReason && candidate.finishReason !== "STOP") {
    console.warn("Gemini finishReason:", candidate.finishReason);
    if (candidate.finishReason === "MAX_TOKENS") {
      throw new Error("Yanıt token limitine ulaştı, çıktı kesildi.");
    }
  }

  const text = candidate?.content?.parts?.[0]?.text;
  if (!text) throw new Error("Vertex AI'den boş yanıt alındı.");
  return text;
}

/**
 * Gezi planı için Gemini prompt'u oluşturur
 */
function buildTripPrompt(params: {
  fromCity: string;
  toCity: string;
  startDate: string;
  endDate: string;
  durationDays: number;
  preferences: string[];
  waypoints: string[];
}): string {
  const { fromCity, toCity, startDate, durationDays, preferences, waypoints } = params;

  const waypointText = waypoints && waypoints.length > 0
    ? `\nYol güzergahında mutlaka uğranacak şehirler: ${waypoints.join(", ")}.`
    : "";

  const prefText = preferences.length > 0
    ? preferences.join(", ")
    : "Tarih, Kültür, Yemek, Doğa";

  const rule8 = waypoints && waypoints.length > 0
    ? "8. Yol üstü şehirlerde 1 gün kal, varış şehrine kalan günleri ayır (yol üstü şehirleri olarak sadece belirtilen durakları kullan)."
    : `8. Yol üstünde başka hiçbir şehirde duraklama/aktivite planlama. Tüm seyahat günlerini sadece kalkış (${fromCity}) ve varış (${toCity}) şehirlerine ayır (yol üstündeki başka hiçbir ili/ilçeyi plana dahil etme).`;

  return `Sen Türkiye'nin her köşesini bilen, 20 yıllık deneyime sahip bir uzman seyahat rehberisin.
Aşağıdaki seyahat için DETAYLI, GERÇEKÇİ ve YARATICI bir gezi planı hazırla.

SEYAHAT BİLGİLERİ:
- Kalkış: ${fromCity}
- Varış: ${toCity}
- Başlangıç tarihi: ${startDate}
- Toplam süre: ${durationDays} gün
- Seyahat tercihleri: ${prefText}${waypointText}

KESİN KURALLAR:
1. Her gün için tam olarak 5 FARKLI mekan seç
2. Her mekanın o şehirde GERÇEKTEN var olduğunu doğrula — hayali mekan ekleme
3. Gün planını dengeli dağıt: sabah → öğle → öğleden sonra → akşam
4. Her mekanın açıklaması 3 cümle olsun (kısa ve öz): mekan nedir + neden önemli + pratik tavsiye
5. Aynı kategoriden art arda iki mekan koyma — çeşitlilik sağla
6. GPS koordinatları gerçeğe yakın olsun
7. "address" alanına gerçek mahalle/semt bilgisi yaz
${rule8}

KATEGORİ SEÇENEKLERİ (tam olarak bu listeden seç):
Tarihi Yapı | Müze | Doğa & Manzara | Yemek & Mutfak | Alışveriş | Dini Yapı | Park & Bahçe | Eğlence | Sanat & Kültür | Çarşı & Pazar

SADECE aşağıdaki JSON formatında yanıt ver, başka hiçbir şey yazma:
{
  "days": [
    {
      "dayNumber": 1,
      "city": "Şehir Adı",
      "theme": "Günün teması (örn: Osmanlı mirası ve tarihi yarımada)",
      "places": [
        {
          "id": "d1p1",
          "name": "Sabah: Mekan Adı",
          "description": "5-6 cümlelik kapsamlı Türkçe açıklama. Tarihi arka plan. Mimari özellikler. Turistik önemi. Pratik tavsiye. Yakın çevre bilgisi.",
          "category": "Tarihi Yapı",
          "suggestedDuration": "1-2 saat",
          "address": "Gerçek Mahalle/Semt, İlçe, Şehir",
          "lat": 41.0082,
          "lng": 28.9784,
          "photoQuery": "Hagia Sophia Istanbul interior Byzantine dome mosaic",
          "tip": "Ziyaretçi ipucu: erken gidin, kalabalık olmadan fotoğraf çekebilirsiniz."
        }
      ]
    }
  ]
}

NOT: "photoQuery" alanı İNGİLİZCE olmalı ve o mekanın en iyi fotoğrafını bulmak için Pexels/Google gibi bir stok fotoğraf sitesinde aranabilecek özgün, açıklayıcı anahtar kelimeler içermeli. Mekan adı + şehir + mimari/doğal özellikler formatında yaz.`;
}

// ─────────────────────────────────────────────────────────────
// CLOUD FUNCTIONS
// ─────────────────────────────────────────────────────────────

/**
 * generateTrip: Gemini 2.5 Flash ile gezi planı oluşturur
 */
export const generateTrip = functions
  .region("us-central1")
  .runWith({ timeoutSeconds: 300, memory: "512MB" })
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Bu işlem için giriş yapmanız gerekiyor."
      );
    }

    const { tripId, fromCity, toCity, startDate, endDate, durationDays, preferences, waypoints } = data;

    if (!tripId || !fromCity || !toCity) {
      throw new functions.https.HttpsError("invalid-argument", "Gerekli alanlar eksik.");
    }

    try {
      const prompt = buildTripPrompt({ fromCity, toCity, startDate, endDate, durationDays, preferences, waypoints });
      const rawResponse = await callGemini(prompt, true);

      let planData: { days: object[] };
      try {
        planData = JSON.parse(rawResponse);
      } catch {
        const jsonMatch = rawResponse.match(/\{[\s\S]*\}/);
        if (!jsonMatch) throw new Error("Gemini geçersiz JSON döndürdü.");
        planData = JSON.parse(jsonMatch[0]);
      }

      await db.collection("trips").doc(tripId).update({
        days: planData.days,
        status: "ready",
        generatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { success: true, tripId };
    } catch (error) {
      console.error("generateTrip error:", error);
      await db.collection("trips").doc(tripId).update({
        status: "error",
        errorMessage: error instanceof Error ? error.message : "Bilinmeyen hata",
      });
      throw new functions.https.HttpsError("internal", "Plan oluşturulurken hata oluştu.", error);
    }
  });

/**
 * getPlaceInfo: Belirli bir mekan için Gemini 2.5 Flash ile detaylı bilgi üretir
 */
export const getPlaceInfo = functions
  .region("us-central1")
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Giriş yapmanız gerekiyor.");
    }

    const { placeName, city, category } = data;
    if (!placeName || !city) {
      throw new functions.https.HttpsError("invalid-argument", "Mekan adı ve şehir gerekli.");
    }

    const prompt = `Sen deneyimli bir Türkiye seyahat uzmanısın.
${city} şehrindeki "${placeName}" (${category || "turistik yer"}) hakkında Türkçe, akıcı ve ilgi çekici bir tanıtım yaz.

İçermesi gerekenler (sıraya uy):
1. Paragraf: Tarihi kökeni, kim tarafından ne zaman yapıldığı/keşfedildiği
2. Paragraf: Mimari, doğal veya kültürel özellikleri — göze çarpan detaylar
3. Paragraf: Neden önemli? Türkiye/dünya kültürü açısından değeri
4. Paragraf: Ziyaretçilere öneriler — en iyi zaman, ne yapılır, ne yenir, fiyat bilgisi
5. Paragraf: Yakın çevredeki diğer ilgi noktaları veya mekanla ilgili ilginç bir gerçek

Akıcı Türkçe yaz. Başlık veya madde işareti kullanma. Her paragraf 3-4 cümle olsun.`;

    const description = await callGemini(prompt, false);
    return { description };
  });

/**
 * chatWithGuide: Gemini 2.5 Flash ile seyahat rehberi sohbeti üretir
 */
export const chatWithGuide = functions
  .region("us-central1")
  .runWith({ timeoutSeconds: 60, memory: "256MB" })
  .https.onCall(async (data: any, context: functions.https.CallableContext) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Bu işlem için giriş yapmanız gerekiyor."
      );
    }

    const { messages, placeName, city, tripTheme } = data;
    if (!messages || !Array.isArray(messages)) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Geçersiz konuşma geçmişi."
      );
    }

    const systemPromptText = `Sen, seyahat asistanı "Via"sın. Kullanıcıya ${city || "Türkiye"} seyahatinde rehberlik ediyorsun.
Şu an ${placeName ? `"${placeName}"` : "seyahat planı"} hakkında konuşuyorsunuz.
${tripTheme ? `Seyahatin genel teması: "${tripTheme}".` : ""}
Kullanıcının sorularına samimi, yardımcı, bir yerel rehber sıcaklığında ve kısa (maksimum 3-4 cümle) yanıtlar ver. Türkçe konuş.`;

    try {
      const vertex = new VertexAI({ project: PROJECT_ID, location: LOCATION });
      const model = vertex.getGenerativeModel({
        model: "gemini-2.5-flash",
        generationConfig: {
          temperature: 0.7,
          topP: 0.95,
          responseMimeType: "text/plain",
        },
        systemInstruction: {
          role: "system",
          parts: [{ text: systemPromptText }]
        }
      });

      const response = await model.generateContent({
        contents: messages,
      });

      const text = response.response.candidates?.[0]?.content?.parts?.[0]?.text;
      return { response: text || "Üzgünüm, şu an yanıt veremiyorum." };
    } catch (error) {
      console.error("chatWithGuide error:", error);
      throw new functions.https.HttpsError("internal", "Sohbet işlenirken hata oluştu.");
    }
  });
