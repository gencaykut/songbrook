# 1.0.0+130 iPhone manuel test listesi

Telefonda 1.2.9+129 vardı; 1.0.0 onun üzerine kuruldu (aynı bundle ID). Bu
liste 1.2.9'dan sonraki değişiklikleri kapsar. 1–9. bölümler 25 Ekim'de
denendi; 10. bölüm aynı gün sonradan eklenen özellikler içindir (`31725d6`). Sorun çıkan maddeye kısa bir not
düş: ne yaptın, ne bekledin, ne oldu.

## 1. Yükseltme ve kimlik

- [ ] Ana ekranda tek bir uygulama var, adı **Songbrook**, ikonu mavi gökyüzü + dere.
- [ ] Eski sürümdeki indirilen şarkılar, çalma listeleri ve favoriler duruyor.
- [ ] Uygulama açılışta hata göstermiyor. Güncelleme kontrolü repo private
      olduğu için sessizce başarısız olmalı; uyarı çıkmamalı.
- [ ] Başlıkta, kilit ekranında ve Denetim Merkezi'nde "Songbrook" yazıyor.
- [ ] **Ayarlar → Uygulama hakkında:** sürüm 1.0.0 (130), BStream Music'e atıf
      kartı var, "1.0.0 sürümündeki yenilikler" bu sürümü anlatıyor, GitHub bağlantısı
      `gencaykut/yt-music-app`'e gidiyor.

## 2. Dil

- [ ] Telefon dili Türkçeyse arayüz Türkçe açılıyor (Ayarlar'da dil seçilmediyse).
- [ ] Ana sayfa, arama ve şarkı/albüm adları YouTube Music'ten Türkçe geliyor.
- [ ] Ayarlar'da dili İngilizce yap: arayüz ve YouTube içerikleri İngilizceye
      geçiyor. Sonra Türkçeye geri al.
- [ ] Gezdiğin ekranlarda İspanyolca kalmış metin yok (görürsen ekranını not et).

## 3. Oynatma ve süre (iOS düzeltmeleri)

- [ ] Bir şarkıyı sonuna kadar dinle (ya da sonuna sar): şarkı zamanında
      bitiyor ve sıradakine geçiyor; birkaç dakika sessiz beklemiyor.
- [ ] Ekran kilitliyken en az iki şarkı geçişi zamanında oluyor.
- [ ] Otomatik geçişten sonra süre `--:--` değil, gerçek süre görünüyor.
- [ ] Kilit ekranından oynat/duraklat, ileri, geri çalışıyor.
- [ ] Bir şarkıyı indir, uçak modunda kitaplıktan çal: zamanında bitiyor.

## 4. Ses seviyesi dengeleme

- [ ] **Ayarlar → Çalma:** "Ses seviyesini dengele" anahtarı var ve açık.
- [ ] Yüksek sesli bir şarkıdan (ör. güncel bir pop) sakin bir şarkıya geç:
      açıkken ses farkı belirgin biçimde azalıyor.
- [ ] Anahtarı kapat: yüksek şarkı yine yüksek çalıyor. Tekrar aç.
- [ ] Kısık şarkılar yükseltilmiyor (bu beklenen davranış).
- [ ] Crossfade açıksa geçişte ses sıçraması yok.

## 5. Arama

- [ ] Bir sanatçı ara, Şarkılar sekmesinde aşağı kaydır: yeni sayfalar
      ekleniyor, aynı şarkı iki kez görünmüyor.
- [ ] Uzun kaydırmada en fazla ~200 sonuçta duruyor, takılmıyor.
- [ ] İnterneti kısa süre kesip kaydır: "Tekrar dene" çıkıyor ve bağlantı
      gelince çalışıyor.
- [ ] **Çalma listeleri** sekmesi topluluk listelerini gösteriyor; birine
      dokununca listenin şarkıları açılıyor ve çalınabiliyor.
- [ ] Not: simülatörde arama kutusuna yazılamıyordu; telefonda yazılabildiğini
      doğrula.

## 6. Oynatıcı ekranı

- [ ] Tam oynatıcıda sol üstteki küçültme oku oynatıcıyı kapatıyor.
- [ ] İçerik en üstteyken aşağı çekince oynatıcı kapanıyor; içerik
      kaydırılmışken aşağı çekmek önce içeriği kaydırıyor.
- [ ] Şarkı sözleri ekranında geri oku ve aşağı çekme çalışıyor.
- [ ] Sağ üstteki menü simgesi koyu kapakta da görünüyor (görünmüyorsa oynatıcı
      stilini, temayı ve kapağı not et).

## 7. Kuyruk

- [ ] Arama sonucundan bir şarkı çal: sıradakiler kuyrukta, otomatik geçiyor.
- [ ] İleri/geri, karıştırma ve tekrar (tümü/tek) çalışıyor.
- [ ] Kuyruk bitince radyo benzer şarkılarla devam ediyor.
- [ ] Bir şarkı otomatik geçtikten hemen sonra İleri'ye bas: ilk basış yok
      sayılabilir (bilinen davranış, 900 ms). Bir saniye sonra basınca geçmeli.
      (Kuyruk artık ayrı sayfa değil, panel: bkz. 10. bölüm.)

## 8. Kaldırılan özellik: TikTok LIVE

- [ ] Ayarlar'da LIVE bağlantısı, komut izinleri ya da "Entegrasyonlar" grubu yok.
- [ ] Kitaplık'ta LIVE kuyruğu girişi yok.

## 9. Diğer

- [ ] Ana ekran widget'ı: widget'ı ekle, bir şarkı çal; widget şarkıyı ve
      kapağı gösteriyor, düğmeleri çalışıyor. (App Group adı değişti; eski
      widget boş kalırsa kaldırıp yeniden ekle.)
- [ ] AirPlay / "Şuraya yayınla" menüsü açılıyor.
- [ ] YouTube Music hesabıyla giriş (kullanıyorsan) çalışıyor, listeler senkron.
- [ ] Uygulamayı arka plana al, 10 dakika sonra dön: çalma kesilmemiş.

## 10. Sonradan eklenenler (25 Ekim, `31725d6`)

### Sıradakiler paneli
- [ ] Oynatıcıyı yukarı çek: kuyruk aşağıdan açılan panel olarak geliyor,
      oynatıcının başlığı açıkta kalıyor. Aşağı savurunca kapanıyor.
- [ ] Başlıktaki kuyruk düğmesi aynı paneli açıyor; dört oynatıcı stilinde de
      dene (Ayarlar → Görünüm).
- [ ] Paneldeki "Otomatik oynatma" kapalıyken kuyruk son şarkıda duruyor;
      açınca radyo hemen devam ediyor. Ayarlar → Çalma'daki anahtar aynı ayar.
- [ ] Panelin altındaki "Benzer" bölümünden bir şarkıya dokun: çalanın
      arkasına eklenip çalıyor, kuyruğun geri kalanı yerinde. Radyo sonradan
      şarkı eklediğinde eklenen şarkı yerinde kalıyor ve iki kez görünmüyor.

### Müzik videoları
- [ ] Ara → Videolar'dan resmi bir klip çal ("Tarkan Verme", "Despacito"):
      videonun girişi yerine şarkı sürümü baştan çalıyor, süre şarkının süresi.
- [ ] Ayarlar → Çalma → "Şarkı sürümünü tercih et"i kapat, yeni bir klip çal:
      video çalıyor ve müzik dışı girişi atlanıyor (Despacito'da ilk ~22 sn).
      Son 20 dakikada çalınan bir klipte ayar hemen yansımayabilir.
- [ ] Bir klip sıradaki şarkı olarak otomatik başladığında ya da kilit
      ekranındayken atlama çalışıyor mu? (Simülatörde doğrulanmadı.)
- [ ] Ayarlar → Çalma'da "Müzik olmayan bölümleri atla" anahtarı ve açıklamada
      SponsorBlock atfı (CC BY-NC-SA 4.0) var.

### Hız
- [ ] Bir şarkının başlaması telefonda hâlâ ~3 sn mi? Müzik videolarında ilk
      dokunuşta +0,5–1 sn bekleniyor.

## 11. 29–31 Ekim: hata düzeltmeleri ve dinleme verisi

1 Kasım'da telefonda test edildi; bulunan tek sorun (widget tuşları
uygulamayı açıyordu) düzeltildi, bkz. 12. bölüm.

Simülatörde ya da testlerle doğrulananlar burada telefonda yeniden denenir.
Android ile ilgili maddeler Android telefonda, diğerleri iPhone'da (ve
mümkünse Android'de de).

### Hata düzeltmeleri
- [ ] Ara: şarkı sonuçlarını aşağı kaydır, sonraki sayfa yüklenirken
      "Çalma listeleri" sekmesine geç, sonra "Şarkılar"a dön ve yine kaydır:
      yeni sayfa geliyor, yükleniyor halkası sonsuza dek dönmüyor.
- [ ] Şarkı sözleri → çeviriyi aç (arayüz Türkçe): yabancı dildeki bir şarkının
      sözleri Türkçeye çevriliyor. Türkçe bir şarkıda "zaten Türkçe" diyor.
- [ ] Ayarlar → Depolama → yedek al, bir çalma listesine şarkı ekle, yedeği
      geri yükle: Kitaplık'ta listenin içeriği yedekteki haliyle görünüyor,
      uygulamayı kapatıp açmadan.
- [ ] (Mac + iPhone) Connect'te iPhone'dan Mac'i "Unut", hemen ardından
      yeniden bağlanmayı dene: unutulan Mac listede geri belirmiyor.

### Kitaplık: dinleme listeleri
- [ ] Kitaplık'ta "En çok dinlediklerin" girişi görünüyor; altında şarkı sayısı
      ve ilk üç şarkı. Açınca "Son 30 gün"/"Tüm zamanlar" geçişi çalışıyor,
      seçili sekmede onay işareti var, her şarkıda "N kez dinlendi" yazıyor.
- [ ] Listede bir şarkıya dokun: o şarkıdan başlayarak liste çalıyor, sonunda
      benzer şarkılarla devam ediyor.
- [ ] "Bir süredir dinlemediklerin" (en az 3 kez dinlenip 60 gündür
      çalınmayanlar) yeterli geçmiş varsa görünüyor; yoksa giriş hiç yok.
- [ ] Ayarlar → "Öneri geçmişi" kapalıyken bu girişler kayboluyor.

### Atlamalar ve kişiselleştirme
- [ ] Bir radyo kuyruğunda aynı şarkıyı birkaç saniye dinleyip iki kez geç
      (farklı günlerde ya da iki ayrı oturumda). Sonra o şarkının radyosu
      çıkan bir şarkı başlat: atlanan şarkı yeni eklenen radyoda, "Benzer"de
      ve ana sayfa önerilerinde yok. "Dinlemeye devam et"te hâlâ görünebilir
      (kendi geçmişin).
- [ ] Çok dinlediğin bir sanatçının şarkıları radyoda ve "Benzer"de birkaç sıra
      öne geliyor (belirgin olmayabilir; en fazla 3 sıra).
- [ ] Duraklat ya da durdur, uygulamayı kapat: bunlar atlama sayılmıyor (fark
      edilmez; sorun görürsen not al).

### Açılışta ön hazırlık
- [ ] Uygulamayı kapatıp aç, ana sayfa gelince 2–3 sn bekle ve "Dinlemeye devam
      et"in ilk şarkısına dokun: başlama, soğuk bir şarkıya göre biraz daha
      hızlı (fark küçük, simülatörde ortanca ~0,1–0,5 sn).

### En çok dinlediklerini indir
- [ ] Ayarlar → Depolama → "En çok dinlediklerini indir"i Wi-Fi'deyken aç:
      birkaç saniye içinde indirmeler başlıyor; İndirilen şarkılar'da bu
      şarkıların adının yanında küçük indirme simgesi var.
- [ ] Wi-Fi'yi kapat (mobil veride kal): yeni otomatik indirme başlamıyor,
      süren indirmeler iptal ediliyor. Wi-Fi'yi açınca devam ediyor.
- [ ] Otomatik indirilen bir şarkıyı favorilere ekle: listeden düşse bile
      silinmiyor (bunu denemek zaman alır; görürsen not al).
- [ ] Elle indirdiğin şarkılar simgesiz ve hiç silinmiyor.
- [ ] Ayarı kapat: süren otomatik indirmeler duruyor, indirilmiş olanlar
      yerinde kalıyor.

### Android
- [ ] Android telefonda uygulamayı son uygulamalardan kaydırıp kapat: çalma
      duruyor (Ayarlar → Çalma'daki anahtar açıkken).
- [ ] Android'de "En çok dinlediklerini indir" Wi-Fi'de çalışıyor ve mobil
      veride beklemeye geçiyor (connectivity_plus Android'de denenmedi).

## 12. Ana ekran widget'ı (1 Kasım)

Widget tuşları iOS 17 ve üstünde uygulamayı açmadan çalışıyor (simülatörde
uygulama arka plandayken beşi de denendi).
- [ ] Uygulama arka plandayken (çalarken ve duraklatılmışken) orta ve büyük
      widget'ta önceki, tekrar, çal/duraklat, sonraki, favori: uygulama öne
      gelmiyor, widget yeni durumu gösteriyor.
- [ ] Kilitli ekrandan dönüp aynı tuşlar: çalışıyor.
- [ ] Uygulamayı son uygulamalardan kaydırıp tamamen kapat, sonra widget'ta
      çal'a bas: uygulama açılıyor ve komut uygulanıyor (simülatörde
      denenemedi; açılmazsa ya da komut kaybolursa not al).
- [ ] Küçük widget'a dokununca uygulama açılıyor (bilerek değişmedi).
- [ ] Android widget'ında tekrar ve favori: uygulama açılmıyor, widget yeni
      durumu gösteriyor (önceki/çal/sonraki zaten açmıyordu). Uygulama
      tamamen kapalıyken de dene (yalnız derlendi, cihazda denenmedi).
