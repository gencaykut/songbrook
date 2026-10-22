# Proje: BStream-Music fork'u (Mac + iOS + Android YouTube müzik uygulaması)

- Kullanıcıyla **Türkçe** konuşulur.
- Bu repo, `BryamContreras/BStream-Music` (Flutter, BSD-2) projesinin **ayrılan bir fork'u**. Upstream sürekli takip edilmiyor; yalnızca YouTube motoruna (`lib/services/youtube_music/`) gelen düzeltmeler `upstream` remote'undan cherry-pick ile alınıyor.
- Repo: `origin` = github.com/gencaykut/yt-music-app (private, geçici ad), `upstream` = BryamContreras/BStream-Music.
- Fork tabanı: upstream `8dd2a2e`. Upstream değişikliklerini görmek için: `git fetch upstream && git log --oneline main..upstream/main`.
- Proje açık kaynak olacak. Kullanıcının ücretli Apple Developer hesabı var; bunu sorma, maliyet ya da engel olarak sayma.
- Dağıtım: App Store yok. Mac için notarize edilmiş dmg/pkg, iOS için AltStore/Sideloadly (AB'de AltStore PAL), Android için APK/F-Droid.
- Upstream'e PR ya da issue açmak dışa dönük bir iş; önce kullanıcıya sor.

## Ortam

- Flutter: `~/development/flutter` (`~/.zshrc` içinde PATH'e ekli). CocoaPods, Xcode ve Rust kurulu.
- iOS simülatörü: iPhone 18 Pro, iOS 27.0, UDID `4164F7C0-8133-419B-AA72-02E6ABC9AA6F`.
- Derleme sırasında Flutter iOS deployment target'ı 15.0'a çıkarıyor ve Podfile'ları güncelliyor. Bu beklenen bir değişiklik.

## Komutlar

```bash
flutter analyze
flutter test
flutter run -d macos
flutter run -d 4164F7C0-8133-419B-AA72-02E6ABC9AA6F
flutter test integration_test/<dosya> -d 4164F7C0-8133-419B-AA72-02E6ABC9AA6F
dart run tool/claude_search_probe.dart
```

- `flutter test` macOS'ta 47 test ortam nedeniyle kalır. Bunlar kod hatası değil:
  - 43'ü veritabanı testi: SQLite FFI yalnızca Windows/Linux'ta başlatılıyor; upstream CI'ı Ubuntu'da çalışıyor.
  - 2'si `/var` ile `/private/var` yol karşılaştırması.
  - 2'si playlist senkron testi; aynı veritabanı nedeniyle.

## Araştırma araçları

- `integration_test/claude_*.dart`: Canlı YouTube'a giden araştırma testleri. Ayrıntılar: [docs/ios-duration-fix.md](docs/ios-duration-fix.md).
  - `claude_url_test.dart` imzalı stream URL'si yazdırır. Çıktısını hiçbir yere commit'leme ya da paylaşma.
- `tool/mp4/`: MP4 kutu analizi (`boxes.py`), `moov` sürelerini sıfırlama (`zero_moov.py`), AVFoundation ile süre ölçümü (`swiftc -O tool/mp4/avdur.swift -o tool/mp4/avdur`).

## Bilinmesi gerekenler

- **iOS'ta fragmented MP4 süresi:** AVFoundation, YouTube'un itag 140 m4a dosyalarının süresini 2 kat raporluyor. iOS'ta stream'ler `ClippingAudioSource(end: streamDuration − 300 ms)` ile kırpılıyor. 300 ms pay zorunlu; kaldırılırsa AVPlayer sonsuza kadar "buffering"de kalıyor. Katalog süresi kullanılamaz (saniyeye yuvarlı). Ayrıntılar: [docs/ios-duration-fix.md](docs/ios-duration-fix.md).
- **iOS'ta webm yok:** AVPlayer webm açamıyor. iOS `isAvFoundationCompatibleInnerTubeAudio` filtresiyle yalnızca AAC/MP4 seçiyor; testlerde de bu filtreyi kullan.
- **Stream çözümleme kırılgan:** Token gerektirmeyen "visionOS" istemci profiline dayanıyor. YouTube bunu kapatırsa BotGuard/PO token yedek yollarına düşülür; o yollar canlı test edilmedi.
- `developer.log` çıktıları `flutter run` loguna düşmüyor.

## Simülatör notları

- HOME tuşu uygulamayı arka plana almıyor; bunun yerine `xcrun simctl launch <UDID> com.apple.Preferences` kullan.
- Kilitlemek için `LOCK` butonu çalışıyor; kilidi açmak için alttan yukarı kaydır (y≈872).
- Ana sayfa içeriği her oturumda değişiyor. Tekrarlanabilir doğrulama için gerçek `JustAudioPlayerService` ile entegrasyon testi yaz.
- Simülatörde arama kutusuna metin girilemiyor (iOS yapıştırma izni engelliyor); uygulama hatası olduğu kanıtlanmadı.

## Açık işler

1. **Fork adı ve bundle ID.** Şu anki `com.bstream.bstreamMusic` ve App Group `group.com.bstream.bstreamMusic` kullanıcının Developer Team'inde değil. Gerçek cihaz testinden önce yeni ad seçilmeli.
2. **Gerçek iPhone testi:** İmzalama, App Group'un hem Runner'a hem `NowPlayingWidget` uzantısına eklenmesi, kilit ekranı "Şimdi Çalıyor" kartı (simülatörde hiç görünmedi), arama kutusu.
3. **İndirilmiş m4a dosyaları:** iOS'ta yerel kütüphaneden çalınırken (`_localAudioSource`) muhtemelen aynı 2 kat süre sorunu var. Düzeltilmedi.
4. **Markalama:** TikTok LIVE modülünü (`third_party/piratetok_live`) çıkar, varsayılan dili İspanyolca yerine değiştir, README'deki "iOS 13" bilgisini düzelt, macOS imzalama ve notarization.
5. **Yedek stream yolları:** BotGuard/PO token yollarını visionOS profili kapalıymış gibi zorlayarak canlı test et.
6. **Upstream'e PR:** iOS süre düzeltmeleri BStream'e gönderilebilir. Önce kullanıcıya sor.
