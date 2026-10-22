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
2. ~~**Ad, bundle ID ve App Group**~~ Tamamlandı. Ad **Songbrook**. Bundle ID `io.github.gencaykut.songbrook` (iOS, macOS, Android `applicationId`), widget `io.github.gencaykut.songbrook.NowPlayingWidget`, App Group `group.io.github.gencaykut.songbrook`. Görünen ad, izin metinleri ve widget adı değişti.
   - Bilerek değiştirilmeyenler (upstream'le farkı küçük tutmak için): Dart paket adı `bstream_music`, Android `namespace` ve Kotlin paketleri, method channel ve DispatchQueue adları, `bstreammusic://` URL şeması.
   - `AppConstants.appName` hâlâ "BStream Music": yedek dosyaları bu adla doğrulanıyor (`backup_service.dart`). Değiştirirken eski yedekleri de kabul et.
   - Uygulama içi metinler, Windows/Linux kimlikleri ve macOS `PRODUCT_NAME` (`bstream_music.app`) 6. adımda.
3. ~~**İndirilmiş m4a'larda iOS'taki 2 kat süre**~~ Tamamlandı: yerel dosyalar `moov` süresine göre kırpılıyor (bkz. docs/ios-duration-fix.md §3).
4. ~~**Gerçek iPhone testi**~~ Tamamlandı (iPhone17,2). Team `9K8FGUA9A3` projede; Xcode bundle ID'yi ve App Group'u portala kaydetti.
   - Cihazda doğrulananlar: stream ve indirilmiş dosya kırpması (completed 204,891 sn), arama, kilit ekranı kartı, otomatik geçiş, widget.
   - Bulunan ve düzeltilen: varsayılan "BStream Music" oynatıcı stilinde iOS'ta oynatıcıdan çıkış yoktu (gezinme çubuğu gizli, sistem geri tuşu yok). Başlığa küçültme oku eklendi; içerik en üstteyken aşağı çekince/fırlatınca da kapanıyor (`_PullDownToCollapse`, parmak hareketinden ölçülüyor). Şarkı sözlerinin telefon düzeninde de görünür bir geri oku yoktu; eklendi.
   - Cihazda çalıştırılamayan: `claude_advance_duration_test.dart` (debug başlatma Xcode'da takıldı); elle otomatik geçiş kontrolü geçti.
   - Cihaza kurulum: `flutter build ios --profile` sonra `xcrun devicectl device install app --device <UDID> build/ios/Profile-iphoneos/Runner.app`. Debug derleme ana ekrandan açılmaz.
   - Gözlem (6. adım): oynatıcının sağ üstündeki menü simgesi koyu arka planda neredeyse görünmüyor.
4a. **"Sıradakiler" paneli (YouTube Music benzeri):** Kullanıcı isteği. Oynatıcının altında yukarı kaydırılınca açılan, çalma kuyruğunu ve benzer parçaları gösteren panel. Var olanlar: `_PlaybackQueuePanel` (şu an ayrı bir sayfa), `related_radio_queue_extender.dart` (YouTube radio ile kuyruğu uzatma). Yok olanlar: otomatik oynatma açma/kapama ayarı, `next` yanıtındaki filtre çipleri (Tümü/Bilinen/Popüler/Keşif) — `innertube_search_service.dart` çipleri ayrıştırmıyor.
5. **Yedek stream yolları:** BotGuard/PO token yollarını visionOS profili kapalıymış gibi zorlayarak canlı test et.
6. **Markalama:** ~~Türkçe arayüz~~ (tamamlandı, varsayılan dil henüz İspanyolca; ilk açılışta cihaz diline göre seçilebilir). README'yi güncelle (yanlış "iOS 13" bilgisi dahil). Uygulama içi "BStream Music" yazıları (`AppConstants.appName` yedek doğrulamasında kullanılıyor, dikkat). TikTok LIVE 13 dosyaya, bu arada çakışma sıcak noktası `player_controller.dart`'a yayılmış; silmek yerine arayüzden gizle ya da kapat. Oynatıcının sağ üst menü simgesi koyu arka planda neredeyse görünmüyor.
7. **Dağıtım ve paylaşım:** macOS notarize dmg, iOS ipa (AltStore/Sideloadly), toplu `git push`, repoyu public yapma kararı, upstream'e PR. Repoyu public yapmak ve PR açmak için önce kullanıcıya sor.
