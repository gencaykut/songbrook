# Proje: Songbrook — BStream-Music fork'u (Mac + iOS + Android YouTube müzik uygulaması)

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
flutter build macos --release
bash macos/package_dmg.sh "Developer ID Application: AYKUT GENC (9K8FGUA9A3)" songbrook-notary
```

- `flutter test`: 2647 test geçer; macOS'ta 47 test ortam nedeniyle kalır. Bunlar kod hatası değil:
  - 43'ü veritabanı testi: SQLite FFI yalnızca Windows/Linux'ta başlatılıyor; upstream CI'ı Ubuntu'da çalışıyor.
  - 2'si `/var` ile `/private/var` yol karşılaştırması.
  - 2'si playlist senkron testi; aynı veritabanı nedeniyle.

## Araştırma araçları

- `integration_test/claude_*.dart`: Canlı YouTube'a giden araştırma testleri. Ayrıntılar: [docs/ios-duration-fix.md](docs/ios-duration-fix.md).
  - `claude_url_test.dart` imzalı stream URL'si yazdırır. Çıktısını hiçbir yere commit'leme ya da paylaşma.
- `tool/claude_hl_probe.dart`: Ayrıştırıcıların iki `hl` dilinde canlı YouTube Music yanıtından ne çıkardığını karşılaştırır.
- `tool/mp4/`: MP4 kutu analizi (`boxes.py`), `moov` sürelerini sıfırlama (`zero_moov.py`), AVFoundation ile süre ölçümü (`swiftc -O tool/mp4/avdur.swift -o tool/mp4/avdur`).

## Bilinmesi gerekenler

- **Mac dağıtımı:** `macos/package_dmg.sh` evrensel (arm64 + x86_64) release derlemesini `Songbrook.app` adıyla Developer ID ile imzalar, upstream'in doğrulama betiğiyle iki mimariyi denetler, notarize edip staple eder ve `dist/Songbrook-<sürüm>.dmg` üretir. Notarization için `notarytool` anahtar zinciri profili gerekir (`songbrook-notary`); profil yoksa dmg imzalı ama notarize edilmemiş olur ve başka Mac'lerde Gatekeeper engeller.

- **Türkçe arayüz:** Upstream metinleri `strings.choose('İspanyolca', 'İngilizce')` ile yazıyor. Türkçe çeviriler İngilizce metni anahtar alan `app_strings_turkish.dart` dosyasında (diğer diller `app_strings_translation_catalog.dart` içinde). `ZXQPH<n>X` değişken yer tutucusu; Türkçede sırası değişebilir. Yeni bir `choose` metni eklenirse Türkçesini de bu dosyaya ekle; `app_strings_turkish_test.dart` katalogdaki her anahtarın Türkçesini ve yer tutucuları denetler.
- **Servis mesajları:** Servisler hata/durum mesajlarını yalnızca İspanyolca üretiyor. Türkçeleri İspanyolca metni anahtar alan `app_strings_turkish_runtime.dart` dosyasında; ekrana yazılan yerde `strings.runtimeMessage(...)` ile çevriliyor (önekleri atar, iç içe mesajları da çevirir). Yeni bir mesaj gösterim noktası eklenirse ona da bağla.
- **Arayüz dili varsayılanı:** Kullanıcı Ayarlar'dan dil seçene kadar cihazın tercih ettiği ilk desteklenen dil kullanılır, yoksa İngilizce (`appLanguageForLocales`, `systemAppLanguage`); bu seçim kaydedilmez, cihaz dili değişirse uygulama da değişir. Testler `test/flutter_test_config.dart` ile upstream'in İspanyolca varsayılanına sabitlenir.
- **YouTube içerik dili:** Arama/katalog servisi Türkçe arayüzde `hl=tr`, İngilizcede `hl=en`, diğer dillerde upstream gibi `hl=es-419` istiyor (`innerTubeCatalogLanguage`, `music_providers.dart`). Ayrıştırıcıların bazı yerleri YouTube'un metnine bakıyor ("Sanatçıya git" süzgeci, "Popüler şarkılar" rafı, "Albüm"/"Single" türü, "Radyo" düğmesi, çalma listesi görünürlüğü ve şarkı sayısı, "Sonra dinlenecek bölümler"); yeni bir dil eklersen bunlara da karşılık ekle ve `dart run tool/claude_hl_probe.dart es-419 <hl>` ile canlı karşılaştır. Oynatma servisi bot/bölge uyarılarını İspanyolca/İngilizce metinden tanıdığı için dili bilerek değiştirilmedi. İndirici, dil değişince yeniden kurulmasın diye kendi katalog örneğini kullanıyor.

- **iOS'ta fragmented MP4 süresi:** AVFoundation, YouTube'un itag 140 m4a dosyalarının süresini 2 kat raporluyor. iOS'ta stream'ler ve indirilmiş dosyalar (dosyanın `moov` süresiyle) `ClippingAudioSource(end: streamDuration − 300 ms)` ile kırpılıyor. 300 ms pay zorunlu; kaldırılırsa AVPlayer sonsuza kadar "buffering"de kalıyor. Katalog süresi kullanılamaz (saniyeye yuvarlı). Ayrıntılar: [docs/ios-duration-fix.md](docs/ios-duration-fix.md).
- **iOS'ta webm yok:** AVPlayer webm açamıyor. iOS `isAvFoundationCompatibleInnerTubeAudio` filtresiyle yalnızca AAC/MP4 seçiyor; testlerde de bu filtreyi kullan.
- **Stream çözümleme kırılgan:** Token gerektirmeyen "visionOS" istemci profiline dayanıyor. Yedek sıra: `androidSdkless` ve `visionOS01` (ikisi de tokensiz), `webEmbedded` (EJS), sonra `mweb` ve `webMusic` (EJS + BotGuard PO token). EJS/PO yolları bu fork'ta canlı test edilmedi. Ayrıntılar: [docs/innertube_playback.md](docs/innertube_playback.md).
- `developer.log` çıktıları `flutter run` loguna düşmüyor.
- **Dokümanlar:** `README.md` Songbrook'un kendi README'si (İngilizce); upstream README'si referans olarak `docs/upstream-readme.md`'de. Fork değişiklikleri `CHANGELOG.md`'nin başındaki "Unreleased (Songbrook)" bölümünde. `test/core/constants/app_metadata_test.dart`, README'deki `Current version: **x+y**` satırını ve CHANGELOG'daki ilk `## x.y.z+n` başlığını `pubspec.yaml` ile karşılaştırıyor; sürüm değişince üçünü birlikte güncelle.

## Simülatör notları

- HOME tuşu uygulamayı arka plana almıyor; bunun yerine `xcrun simctl launch <UDID> com.apple.Preferences` kullan.
- Kilitlemek için `LOCK` butonu çalışıyor; kilidi açmak için alttan yukarı kaydır (y≈872).
- Ana sayfa içeriği her oturumda değişiyor. Tekrarlanabilir doğrulama için gerçek `JustAudioPlayerService` ile entegrasyon testi yaz.
- Simülatörde arama kutusuna metin girilemiyor (iOS yapıştırma izni engelliyor); uygulama hatası olduğu kanıtlanmadı.

## Son durum (22 Ekim 2026)

- Yerel `main` GitHub'dan önde, **push edilmedi** (kullanıcı topluca push istiyor; sayı için `git status -sb`).
- iPhone'da (UDID `00008140-0018303E2128401C`, iPhone17,2) Türkçe sürüm kurulu; son iki değişiklik (cihaz dili varsayılanı, `hl=en`) henüz telefonda ve dmg'de yok.
- Mac: `dist/Songbrook-1.2.9.dmg` notarize edilmiş ve staple'lı (cihaz dili değişikliğinden önceki sürüm). `songbrook-notary` profili anahtar zincirinde kayıtlı.
- Uygulama sürümü hâlâ upstream'in `1.2.9+129` numarası (`pubspec.yaml`).

### Kullanıcıdan bekleyen kararlar

- **GitHub Actions:** `Nightly native smoke` her gün kalıyor (GitHub'ın Android emülatörü açılmıyor; upstream'de de aynı, kodla ilgisiz). Öneri: günlük zamanlamayı kapat, elle çalıştırılabilir kalsın; `Release installers` yalnızca `v*` etiketlerinde ve elle çalışsın (private repo, Actions dakika kotası). Kullanıcı henüz cevap vermedi.
- **Android:** Bu Mac'te APK derlenemiyor: Java yok, Android `cmdline-tools` yok (SDK'nın bir kısmı `~/Library/Android/sdk` altında). Öneri: Homebrew ile JDK 17 ve Android komut satırı araçları, repo dışında (`~/.songbrook/`) kalıcı bir imza anahtarı (parolayı kullanıcı terminalde girer), `android/key.properties` ile release APK. Google Play geliştirici hesabı gerekmiyor (Play Store'a çıkılmayacak). Kullanıcıya Google'ın Play dışı kurulumlar için geliştirici doğrulaması planı anlatıldı (2026 sonbaharında birkaç ülkede, 2027'den itibaren dünya geneli; ADB kurulumu muaf); ayrıntılar değişmiş olabilir.

## İş sırası

1. ~~Upstream `7d54c36`'yı al~~ Tamamlandı.
2. ~~Ad, bundle ID ve App Group~~ Tamamlandı. Ad **Songbrook**; bundle ID `io.github.gencaykut.songbrook` (iOS, macOS, Android `applicationId`), widget `…songbrook.NowPlayingWidget`, App Group `group.io.github.gencaykut.songbrook`.
   - Bilerek değiştirilmeyenler (upstream farkını küçük tutmak için): Dart paket adı `bstream_music`, Android `namespace` ve Kotlin paketleri, method channel ve DispatchQueue adları, `bstreammusic://` URL şeması, macOS `PRODUCT_NAME` (`bstream_music.app`; dmg içinde `Songbrook.app` olarak adlandırılıyor).
   - `AppConstants.appName` hâlâ "BStream Music": yedek dosyaları bu adla doğrulanıyor (`backup_service.dart`). Değiştirirken eski yedekleri de kabul et.
3. ~~İndirilmiş m4a'larda iOS'taki 2 kat süre~~ Tamamlandı (docs/ios-duration-fix.md §3).
4. ~~Gerçek iPhone testi~~ Tamamlandı. Team `9K8FGUA9A3` projede.
   - Doğrulananlar: süre kırpması, arama, kilit ekranı kartı, otomatik geçiş, widget.
   - Düzeltilenler: varsayılan oynatıcı stilinde ve şarkı sözlerinde iOS'ta geri dönüş yoktu → küçültme oku ve içerik en üstteyken aşağı çekerek kapatma (`_PullDownToCollapse`).
   - Cihaza kurulum: `flutter build ios --profile` sonra `xcrun devicectl device install app --device <UDID> build/ios/iphoneos/Runner.app` (yoksa `build/ios/Profile-iphoneos/Runner.app`). Debug derleme ana ekrandan açılmaz.
5. **"Sıradakiler" paneli (YouTube Music benzeri, kullanıcı isteği):** Oynatıcının altında yukarı çekilen panel.
   - Aşama 1: mevcut `_PlaybackQueuePanel` (şu an ayrı sayfa) oynatıcının altına çekilen panel olarak.
   - Aşama 2: otomatik oynatma açma/kapama (şu an radyo uzatması `related_radio_queue_extender.dart` hep açık).
   - Aşama 3: tek bir **"Benzer"** başlığı (kullanıcının fikri; YouTube'un Tümü/Popüler/Keşif çipleri yerine). Kaynak: radyonun kuyruğa henüz eklenmemiş şarkıları + sanatçı araması (limit 20), kuyruktakiler ve tekrarlar çıkarılır; sanatçı araması sanatçı başına önbelleklenir. Canlı denemede yalnızca şarkı adıyla arama gürültülü, şarkı+sanatçı araması sanatçının diğer şarkılarını veriyor; benzer sanatçıları yalnızca radyo veriyor.
6. **Yedek stream yolları:** BotGuard/PO token yollarını visionOS profili kapalıymış gibi zorlayarak canlı test et.
7. **Markalama:** ~~Türkçe arayüz~~, ~~cihaz dili varsayılanı~~ tamamlandı. Kalanlar: uygulama içi "BStream Music" yazıları (başlık, mini oynatıcı; `AppConstants.appName` dikkat), "Yeni sürüm var" kontrolü upstream sürümlerine bakıyor, ~~README~~, TikTok LIVE'ı arayüzden gizle (13 dosyaya ve `player_controller.dart`'a yayılmış; silme), oynatıcının sağ üst menü simgesi koyu arka planda neredeyse görünmüyor, kendi sürüm numaralandırması.
8. **Dağıtım ve paylaşım:**
   - ~~macOS notarize dmg~~ (`macos/package_dmg.sh`); yeni sürümde yeniden üret.
   - Android APK (yukarıdaki karara bağlı), iOS ipa (AltStore/Sideloadly).
   - Toplu `git push`, repoyu public yapma kararı, upstream'e PR. Public yapmak ve PR açmak için önce kullanıcıya sor.

### Yeni özellikler (24 Ekim 2026 değerlendirmesi, öncelik sırasıyla)

BStream çekirdek olarak kalıyor; başka bir oynatıcı reposuna geçilmiyor. 9 ve 10 küçük işler, 5'ten önce de yapılabilir. 11, 5'ten sonra gelmeli (kuyruk modeline dayanıyor). Kullanıcının verdiği referanslar (Ariami Connect, YouPipe Music, PlayerVF) bulunamadı; bağlantıları gelmeden lisans ve mimari varsayma.

9. **Ses seviyesi dengeleme:** YouTube'un player yanıtındaki `loudnessDb`'yi oku (şu an okunmuyor), `setVolume` ile yalnızca kısarak uygula. iOS'ta AVPlayer 1.0'ın üstüne çıkmadığı için yükseltme yok. DSP gerekmez, her platformda çalışır.
10. **Arama sayfalaması:** Arama 20 sonuçla sınırlı (`InnerTubeSearchService.maxResults`). Continuation altyapısı ana sayfa ve tür/ruh hali sayfalarında var; aramaya bağla, Playlists filtresini ekle (`searchArtists` zaten var). Kod upstream'den cherry-pick alınan `lib/services/youtube_music/` içinde; çakışmayı azaltmak için upstream'e PR düşünülebilir (önce kullanıcıya sor). RustyPipe (GPL) kodu alınmaz.
11. **Songbrook Connect:** Cihazlar arasında yalnızca `videoId`, kuyruk, konum, shuffle/repeat senkronize edilir; hedef cihaz stream'i kendi resolver'ıyla çözer. Yerel ağda Bonjour/mDNS keşfi + WebSocket (iOS'ta yerel ağ izni yeterli, multicast entitlement gerekmez). Ağlar arası devretme sunucu ister; kapsam dışı. iOS çalmıyorken askıya alındığı için alıcı olamaz, kumanda olarak çalışır.
12. **Şarkı/video eşleştirme + SponsorBlock:** Müzik videosu çalınınca YouTube Music'in şarkı (ATV) karşılığına geçmek asıl kazanç. SponsorBlock `music_offtopic` kategorisi tamamlayıcı; veri CC BY-NC-SA 4.0 (atıf gerekli), gizlilik için hash önekli sorgu kullan. Sessizlik atlama yalnızca Android'de var.
13. **Android Auto:** `audio_service`'in MediaBrowserService'i manifestte var ama göz atma ağacı (`getChildren`) ve `automotive_app_desc` yok. Play dışı kurulumda Auto, kullanıcı geliştirici ayarlarında "Bilinmeyen kaynaklar"ı açmadıkça uygulamayı göstermiyor. Chromecast/DLNA zaten var (`lib/services/casting/`, docs/audio-routing.md); yeni kod değil, gerçek alıcıyla test gerekiyor.
14. **EQ / DSP:** Android'de vendored just_audio'nun `AndroidEqualizer`/`AndroidLoudnessEnhancer`'ı, Mac'te media_kit/libmpv `af` filtreleri ile kolay. iOS'ta AVPlayer'da EQ yok; `MTAudioProcessingTap` gerekir ve süre kırpmasıyla etkileşir.
    - Şimdilik önerilmeyenler: MusicBrainz (uygulama dosyalara etiket yazmıyor), pitch/reverb, kelime düzeyinde karaoke (LRCLIB yalnızca satır zamanlaması veriyor).
