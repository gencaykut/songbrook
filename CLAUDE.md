# Proje: BStream-Music fork'u (Mac + iOS + Android YouTube müzik uygulaması)

- Kullanıcıyla **Türkçe** konuşulur.
- Bu repo, `BryamContreras/BStream-Music` (Flutter, BSD-2) projesinin **ayrılan bir fork'u**. Upstream sürekli takip edilmiyor; yalnızca YouTube motoruna (`lib/services/youtube_music/`) gelen düzeltmeler `upstream` remote'undan cherry-pick ile alınıyor.
- Repo: `origin` = github.com/gencaykut/yt-music-app (private, geçici ad), `upstream` = BryamContreras/BStream-Music.
- Fork tabanı: upstream `8dd2a2e`; upstream `7d54c36`'ya kadar birleştirildi. Upstream değişikliklerini görmek için: `git fetch upstream && git log --oneline main..upstream/main`.
- Proje açık kaynak olacak. Kullanıcının ücretli Apple Developer hesabı var; bunu sorma, maliyet ya da engel olarak sayma.
- Dağıtım: App Store yok. Mac için notarize edilmiş dmg/pkg, iOS için AltStore/Sideloadly (AB'de AltStore PAL), Android için APK/F-Droid.
- Upstream'e PR ya da issue açmak dışa dönük bir iş; önce kullanıcıya sor.
- **Push toplu yapılır:** Düzeltmeleri yerelde ayrı commit'ler olarak biriktir; her adımdan sonra push etme. Kullanıcı istediğinde ya da bir iş paketi bittiğinde tek `git push` yap.

## Ortam

- Flutter: `~/development/flutter` (`~/.zshrc` içinde PATH'e ekli). CocoaPods, Xcode ve Rust kurulu.
- iOS simülatörü: iPhone 18 Pro, iOS 27.0, UDID `4164F7C0-8133-419B-AA72-02E6ABC9AA6F`.
- `ios/Podfile.lock` ve `macos/Podfile.lock` upstream'de olduğu gibi takip edilmiyor.
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

- `flutter test`: 2596 test geçer; macOS'ta 47 test ortam nedeniyle kalır. Bunlar kod hatası değil:
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

## İş sırası

Sırayla yapılır. Push yalnızca 7. adımda, tek seferde.

1. ~~**Upstream'in yeni commit'ini al:** `7d54c36`~~ Tamamlandı. Analyze temiz, 2596 test geçti, macOS debug derlemesi başarılı.
2. **Ad, bundle ID ve App Group** (karar kullanıcının). Yalnızca kimlikleri değiştir: `ios/`, `macos/Runner.xcodeproj`, `android/app/build.gradle.kts`, entitlements ve App Group. `com.bstream...` ile başlayan method channel adlarına dokunma; bunlar kullanıcıya görünmüyor ve upstream'le gereksiz fark yaratır.
3. **İndirilmiş m4a'larda iOS'taki 2 kat süre:** `_localAudioSource` için de kırpma. Önce indirme sırasında `streamDuration`'ın kaydedilip kaydedilmediğine bak. Simülatörde yapılabilir; 2. adımı beklemez.
4. **Gerçek iPhone testi:** İmzalama, App Group'un hem Runner'a hem `NowPlayingWidget` uzantısına eklenmesi, kilit ekranı "Şimdi Çalıyor" kartı (simülatörde hiç görünmedi), arama kutusu, 1. ve 3. adımdaki düzeltmelerin gerçek AVPlayer'da doğrulanması.
5. **Yedek stream yolları:** BotGuard/PO token yollarını visionOS profili kapalıymış gibi zorlayarak canlı test et.
6. **Markalama:** Varsayılan dili değiştir ve README'yi güncelle (yanlış "iOS 13" bilgisi dahil). TikTok LIVE 13 dosyaya, bu arada çakışma sıcak noktası `player_controller.dart`'a yayılmış; silmek yerine arayüzden gizle ya da kapat.
7. **Dağıtım ve paylaşım:** macOS notarize dmg, iOS ipa (AltStore/Sideloadly), toplu `git push`, repoyu public yapma kararı, upstream'e PR. Repoyu public yapmak ve PR açmak için önce kullanıcıya sor.
