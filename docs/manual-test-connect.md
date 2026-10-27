# Songbrook Connect gerçek cihaz test listesi (5. aşama)

Derleme `985b461` (27 Ekim 2026): iPhone'a profil derlemesi, Mac'e release
derlemesi. İki cihaz aynı Wi-Fi ağında olmalı. Sorun çıkan maddeye kısa bir
not düş: ne yaptın, ne bekledin, ne oldu. Zaman ölçülen maddelerde yaklaşık
süreyi de yaz.

Kısaltmalar: **M** = Mac, **i** = iPhone.

## Bulunan ve düzeltilenler (27 Ekim)

- Mac'te Connect başlamıyordu: Anahtar Zinciri -34018 (`4fb42c7`).
- Mac'te kod penceresini "Kapat"la kapatınca uygulama siyah ekranda kalıyordu
  (`b91e9f5`).
- Telefon görüşmesi ya da arka plandan sonra iPhone "Bağlı değil"de
  kalabiliyordu: ön plana dönünce ve Mac kartına dokununca yeniden bağlanıyor
  (`139abac`). Telefonda görüşmeyle henüz denenmedi.
- iPhone'dan Mac'e devredilen şarkı baştan başlıyordu: libmpv yükleme
  sırasındaki sarmayı yok sayıyordu (`35195e6`). Telefonda doğrulandı.
- iPhone çalarken bağlantısı kısa süre kopunca (kilit, Wi-Fi güç tasarrufu)
  merkez çalmayı Mac'e "çalıyor" olarak devrediyordu; iPhone ağsız çalmayı
  sürdürdüğü için iki cihaz aynı anda çalıyordu. Dönen iPhone susturulmuyor,
  Mac'i de yansıtıyordu; kilit ekranındaki duraklat/ileri Mac'e gidiyordu.
  Artık failover oturumu duraklatılmış devrediyor, dönen cihaz susturulmuyor
  ve hâlâ çalan cihaz yansıtmaya geçmek yerine sahipliği geri alıyor.
- Not: macOS güncellemesinden sonra (ve bazen yeni derlemede) Yerel Ağ izni
  yeniden soruluyor; izin verilene kadar Mac Connect'i başlatmıyor.

## 1. Açma, izin, eşleştirme

- [x] **M:** Ayarlar → Songbrook Connect anahtarını aç. macOS "yerel ağdaki
      aygıtları bulma" izni isterse izin ver. (İzin yoksa Mac ağda görünmez:
      Sistem Ayarları → Gizlilik ve Güvenlik → Yerel Ağ → Songbrook.)
- [x] **i:** Ayarlar → Songbrook Connect anahtarını aç. iOS yerel ağ izni
      isterse izin ver.
- [x] **i:** Birkaç saniye içinde Mac'in adı "Eşleştirmek için dokun" ile
      listede görünüyor.
- [x] **M:** "Cihaz ekle"ye bas; 6 haneli kod çıkıyor.
- [ ] **i:** Mac'e dokun, önce yanlış bir kod gir: "kod yanlış" uyarısı çıkıyor,
      eşleşmiyor.
- [x] **i:** Doğru kodu gir: pencere kapanıyor, Mac "Bağlı" görünüyor.
- [ ] **M:** Kod penceresi kendiliğinden kapanıyor; iPhone'un adı eşleşen
      cihazlarda "Bağlı" görünüyor. iPhone'un adı doğru mu? (Not: Ad
      iPhone'un ağ adından geliyor; ne yazdığını not et.)

## 2. Cihaz düğmesi

- [ ] **i:** Oynatıcıyı aç: başlığın sağında cihaz düğmesi var.
- [ ] **M:** Oynatıcıda da aynı düğme var.
- [ ] Hiçbir şey çalmamışken düğmeye bas: iki cihaz listeleniyor (bu cihaz
      başta), altta "Başka bir cihaza geçirmek için önce bir şey çal" yazıyor.
- [ ] Connect'i bir tarafta kapat: düğme iki tarafta da kayboluyor. Tekrar aç.

## 3. Mac çalarken iPhone kumanda

- [ ] **M:** Bir arama sonucundan şarkı çal.
- [ ] **i:** Oynatıcı ve mini oynatıcı Mac'teki şarkıyı gösteriyor; başlıkta
      "<Mac adı> üzerinde çalıyor", mini oynatıcıda aynısı. Kapak ve süre
      doğru, konum ilerliyor. iPhone'dan ses gelmiyor.
- [ ] **i:** Duraklat / devam: Mac'te hemen uygulanıyor (süre: ___).
- [ ] **i:** İleri, geri: Mac şarkı değiştiriyor, iPhone yeni şarkıyı
      gösteriyor.
- [ ] **i:** İlerleme çubuğunda sar: Mac o konuma gidiyor.
- [ ] **i:** Shuffle ve repeat: Mac'te de değişiyor (Mac oynatıcısında gör).
- [ ] **i:** Ses kaydırıcısı (varsa): Mac'in sesi değişiyor.
- [ ] **i:** Kuyruk panelini aç: Mac'in kuyruğu görünüyor. Bir şarkıya dokun:
      Mac o şarkıya atlıyor.
- [ ] **i:** Aramadan yeni bir şarkı seç: Mac'te çalmaya başlıyor (iPhone'da
      değil), kuyruk da arama sonuçları oluyor.
- [ ] **i:** Kuyruğun altındaki "Benzer"den bir şarkıya dokun: Mac'te,
      çalanın arkasına eklenip çalıyor.
- [ ] **M:** Mac'te elle duraklat / şarkı değiştir: iPhone birkaç saniye
      içinde aynısını gösteriyor.
- [ ] **i:** Kalp/favori: favoriler listesine Mac'te çalan şarkı ekleniyor.

## 4. Devretme

- [x] **M çalıyor → i:** iPhone'da cihaz düğmesi → "Bu cihaz". iPhone aynı
      şarkıyı yaklaşık aynı konumdan çalmaya başlıyor, Mac susuyor
      (süre: ___). Arada iki cihaz aynı anda çalmıyor.
- [ ] **M:** Mac'in oynatıcısı artık "<iPhone adı> üzerinde çalıyor"
      gösteriyor; Mac'ten duraklat/ileri iPhone'u yönetiyor.
- [x] **i çalıyor → M:** Mac'te cihaz düğmesi → "Bu cihaz". Mac aynı yerden
      devam ediyor, iPhone susuyor ve Mac'i yansıtmaya başlıyor.
- [ ] Devretmeyi kumandadan yap: Mac çalarken Mac'te cihaz düğmesi →
      iPhone'a dokun (ve tersi).
- [ ] Müzik videosu (şarkı sürümüne geçen bir video, ör. resmi klip) çalarken
      devret: hedef cihaz da şarkı sürümünü çalıyor, başlıkta "Şarkı sürümü".
- [ ] SponsorBlock'lu bir video (ör. Despacito'nun resmi klibi, şarkı sürümü
      tercihi kapalıyken) devredilince hedef cihaz girişi yine atlıyor.
- [ ] Devretmeden sonra kuyruk aynı; sıradaki şarkıya otomatik geçiş hedef
      cihazda oluyor.
- [ ] Bir cihazda yeni bir şarkıyı kendisi çalmaya başlatırsa (yansıtırken
      değil, örneğin bağlantı kurulmadan önce) çalma o cihaza geçiyor, öbürü
      susuyor.

## 5. iPhone arka planda ve kilitli

- [ ] **M çalıyor**, iPhone kilitli: kilidi açınca iPhone birkaç saniyede
      güncel şarkıyı gösteriyor ve komutlar çalışıyor.
- [ ] **i çalıyor**, ekran kilitli: Mac'ten duraklat / ileri iPhone'da
      uygulanıyor (iOS çalan uygulamayı askıya almaz).
- [ ] **i çalıyor**, iPhone'da duraklat, uygulamayı arka plana at, 1–2 dakika
      bekle: Mac'te ne görünüyor? (Beklenen: iOS uygulamayı askıya alır,
      bağlantı düşer; Mac kendi çalmasına döner ya da oturumu duraklatılmış
      alır, ses başlamaz.)
- [ ] Bilinen eksik, yalnızca not et: yansıtan iPhone'un kilit ekranı kendi
      (duraklatılmış) şarkısını gösteriyor, Mac'i kilit ekranından
      yönetemiyorsun.

## 6. Kopma ve yeniden bağlanma

- [ ] **i çalıyor**, Mac'te Songbrook'u kapat: iPhone çalmayı kesintisiz
      sürdürüyor; cihaz düğmesi kayboluyor.
- [ ] Mac'te Songbrook'u yeniden aç: iPhone kod sormadan yeniden bağlanıyor.
- [ ] **M çalıyor**, iPhone'da Wi-Fi'yi kapat: iPhone kendi çalmasını
      gösteriyor (duraklatılmış), Mac çalmayı sürdürüyor. Wi-Fi'yi aç: iPhone
      yeniden Mac'i yansıtıyor.
- [ ] **i çalıyor**, iPhone'da Wi-Fi'yi kapat: iPhone çalmayı sürdürüyor; Mac
      ne gösteriyor? (Not et.)
- [ ] Mac uykudan uyanınca iPhone yeniden bağlanıyor.

## 7. Eşleşmeyi kaldırma

- [ ] **M:** Ayarlar'da iPhone'u kaldır: iPhone'da "Mac'in bu cihazı kaldırdı"
      uyarısı, bağlantı kesiliyor.
- [ ] **i:** Yeniden kodla eşleş; her şey yine çalışıyor.
- [ ] **i:** iPhone tarafında "Unut": Mac'e bağlanmıyor, yeniden kod istiyor.

## 8. Genel

- [ ] Connect kapalıyken uygulama eskisi gibi çalışıyor (tek cihazda çalma,
      kilit ekranı, kuyruk).
- [ ] Gözüne çarpan Türkçe/çeviri hatası, taşan metin, yanlış ikon.
