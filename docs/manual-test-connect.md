# Songbrook Connect gerçek cihaz test listesi (5. aşama)

iPhone'a profil derlemesi, Mac'e `dist/connect-test/Songbrook.app` (Developer
ID ile imzalı). İki cihaz aynı Wi-Fi ağında. Liste 5 bölüm; her seferinde bir
bölüm yapılır. Her adımın altında ne olması gerektiği yazıyor. Olmazsa adımın
numarasını ve ne olduğunu not et.

Kısaltmalar: **M** = Mac, **i** = iPhone.

## Doğrulananlar

- Mac'te ve iPhone'da Connect'i açma, yerel ağ izni, iPhone'un Mac'i bulması,
  6 haneli kodla eşleşme.
- Mac'ten iPhone'a ve iPhone'dan Mac'e devretme; ikisi de kaldığı yerden
  sürüyor.
- iPhone çalarken kısa bağlantı kopması: tek cihaz çalıyor, kilit ekranı
  düğmeleri iPhone'u yönetiyor.

## Bulunan ve düzeltilenler (27 Ekim)

- Mac'te Connect başlamıyordu: Anahtar Zinciri -34018 (`4fb42c7`).
- Mac'te kod penceresini "Kapat"la kapatınca uygulama siyah ekranda kalıyordu
  (`b91e9f5`).
- Telefon görüşmesi ya da arka plandan sonra iPhone "Bağlı değil"de
  kalabiliyordu: ön plana dönünce ve Mac kartına dokununca yeniden bağlanıyor
  (`139abac`).
- iPhone'dan Mac'e devredilen şarkı baştan başlıyordu: libmpv yükleme
  sırasındaki sarmayı yok sayıyordu (`35195e6`).
- iPhone çalarken bağlantısı kısa süre kopunca iki cihaz aynı anda çalıyor,
  kilit ekranı düğmeleri Mac'e gidiyordu (`9653db8`). Telefonda doğrulandı.
- Shuffle ve repeat açık/kapalı ayırt edilmiyordu: açıkken sarı, kapalıyken
  beyaz (`48ba46e`).
- İzlemede: bir kez iPhone kilit ekranında kapak görünmedi (iki cihazın aynı
  anda çaldığı hata sürerken). Sonra doğrudan çalmada ve Mac'ten devretmede
  kapak göründü; yeniden üretilemedi. Tekrar görülürse şarkıyı ve durumu not
  et. Uygulamanın kapak sunucusunu `integration_test/claude_lockscreen_artwork_test.dart`
  dener.
- Not: macOS güncellemesinden sonra (ve bazen yeni derlemede) Yerel Ağ izni
  yeniden soruluyor; izin verilene kadar Mac Connect'i başlatmıyor.

## Bölüm 1: iPhone'dan Mac'i yönetmek

Hazırlık: Mac'te bir şarkı çal. iPhone'da Songbrook'u aç, oynatıcıyı aç.

1. [ ] iPhone oynatıcısına bak.
   Olmalı: Mac'teki şarkı görünüyor, başlıkta "<Mac adı> üzerinde çalıyor",
   süre ilerliyor, iPhone'dan ses gelmiyor.
2. [ ] iPhone'da duraklat, sonra devam et.
   Olmalı: Mac duruyor ve devam ediyor.
3. [ ] iPhone'da ileri, sonra geri düğmesine bas.
   Olmalı: Mac şarkı değiştiriyor, iPhone yeni şarkıyı gösteriyor.
4. [ ] iPhone'da ilerleme çubuğunu ortaya sürükle.
   Olmalı: Mac o yere atlıyor.
5. [ ] iPhone'da karıştırma (shuffle) ve tekrar (repeat) düğmelerine bas.
   Olmalı: Mac'in oynatıcısında da değişiyor.
6. [ ] Mac'te kendin duraklat, sonra şarkı değiştir.
   Olmalı: iPhone birkaç saniye içinde aynısını gösteriyor.

## Bölüm 2: iPhone'dan şarkı seçmek

Hazırlık: Mac'te bir şarkı çalıyor, iPhone'da Songbrook açık.

1. [ ] iPhone'da kuyruk panelini aç, listeden başka bir şarkıya dokun.
   Olmalı: Mac o şarkıya geçiyor.
2. [ ] iPhone'da Ara'dan bir şarkı bul ve dokun.
   Olmalı: şarkı Mac'te çalıyor, iPhone'da değil.
3. [ ] Kuyruk panelinin altındaki "Benzer"den bir şarkıya dokun.
   Olmalı: Mac'te çalmaya başlıyor, kuyruktaki diğer şarkılar duruyor.
4. [ ] iPhone oynatıcısında yıldız (favori) düğmesine bas.
   Olmalı: Mac'te çalan şarkı iPhone'un favorilerine ekleniyor.

## Bölüm 3: Devretme ayrıntıları

1. [ ] Mac çalarken Mac'teki cihaz düğmesine bas, iPhone'u seç.
   Olmalı: çalma iPhone'a geçiyor, aynı yerden. (Önceki denemede iPhone'dan
   seçmiştin; bu kez Mac'ten.)
2. [ ] iPhone çalarken iPhone'daki cihaz düğmesinden Mac'i seç.
   Olmalı: çalma Mac'e geçiyor, aynı yerden.
3. [ ] Bir müzik videosu çal (örneğin resmi bir klip; başlığın yanında "Şarkı
   sürümü" yazar), sonra öbür cihaza devret.
   Olmalı: öbür cihazda da "Şarkı sürümü" yazıyor.
4. [ ] Devrettikten sonra şarkının bitmesini bekle (ya da sonuna sar).
   Olmalı: sıradaki şarkı yeni cihazda kendiliğinden başlıyor.

## Bölüm 4: Kilit, arka plan, kopma

1. [ ] Mac çalarken iPhone'u kilitle, 1 dakika bekle, kilidi aç ve Songbrook'u aç.
   Olmalı: birkaç saniyede Mac'teki şarkıyı gösteriyor, düğmeler çalışıyor.
2. [ ] Mac çalarken iPhone'da başka bir uygulamaya geç, 1–2 dakika sonra dön.
   Olmalı: aynı şekilde birkaç saniyede bağlanıyor.
3. [ ] Biri seni arasın (ya da sen birini ara), görüşme bitince Songbrook'a dön.
   Olmalı: birkaç saniyede bağlanıyor.
4. [ ] iPhone çalarken Mac'te Songbrook'u kapat (Cmd+Q).
   Olmalı: iPhone çalmayı sürdürüyor.
5. [ ] Mac'te Songbrook'u yeniden aç.
   Olmalı: iPhone kod sormadan yeniden bağlanıyor, iPhone çalmayı sürdürüyor.

## Bölüm 5: Eşleşme ve genel

1. [ ] Mac'te Ayarlar → Songbrook Connect → iPhone'un yanındaki kaldır düğmesi.
   Olmalı: iPhone'da "Mac'in bu cihazı kaldırdı" yazıyor.
2. [ ] Mac'te "Cihaz ekle", iPhone'da Mac'e dokun, önce yanlış bir kod gir.
   Olmalı: "kod yanlış" uyarısı, eşleşmiyor.
3. [ ] Doğru kodu gir.
   Olmalı: yeniden eşleşiyor, Bölüm 1'in 2. adımı yine çalışıyor.
4. [ ] iPhone'da Connect'i kapat, bir şarkı çal, kilit ekranını kullan.
   Olmalı: uygulama eskisi gibi tek başına çalışıyor.
5. [ ] Yol boyunca gözüne çarpan yanlış çeviri, taşan yazı ya da yanlış ikon.
