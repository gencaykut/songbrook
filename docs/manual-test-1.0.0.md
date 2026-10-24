# 1.0.0+130 iPhone manuel test listesi

Telefonda 1.2.9+129 vardı; 1.0.0 onun üzerine kuruldu (aynı bundle ID). Bu
liste 1.2.9'dan sonraki değişiklikleri kapsar. Sorun çıkan maddeye kısa bir not
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
