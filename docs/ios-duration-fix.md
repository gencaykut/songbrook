# iOS süre düzeltmeleri

Fork'taki iOS süre düzeltmelerinin analizi. Doğrulama iOS 27.0 simülatöründe (iPhone 18 Pro) yapıldı.

## 1. iOS'ta şarkı sonu yaklaşık bir şarkı süresi kadar geç algılanıyordu

### Kök neden

- YouTube'un itag 140 m4a dosyası "fragmented MP4". Şarkı süresi hem `moov` başlığında (`mvhd`/`mdhd`/`elst`) hem de `moof` parçalarında yazıyor.
- AVFoundation ikisini topluyor ve 2 kat süre raporluyor. Örnek: 205,19 sn'lik dosya için 410,37 sn. Bu yerel dosyada, macOS'ta bile böyle. `moov` süreleri sıfırlanınca (`tool/mp4/zero_moov.py`) AVFoundation 205,18 sn diyor.
- Sonuç: AVPlayer hayali ikinci yarıyı da "çalıyor" ve "completed" olayı 3–3,7 dk geç geliyor.
- just_audio'nun iOS kodu (`third_party/just_audio` içinde iOS tarafı upstream 0.10.6 ile aynı) `onFailToComplete` ve `onItemStalled` bildirimlerini boş bırakıyor.

### Düzeltme

- YouTube'un ms hassasiyetindeki `approxDuration` süresi `streamDuration` olarak taşınıyor:
  `InnerTubeAudioResolver` → `AudioStreamResolution` → `TrackInfo` (JSON'da `stream_duration_ms`) → `remote_track_resolver` → `RemotePlaybackSource.streamDuration`.
- `JustAudioPlayerService` içinde `clipMp4ToStreamDuration` bayrağı var; varsayılanı `Platform.isIOS`.
- iOS'ta m4a/mp4 kaynaklar `ClippingAudioSource(end: streamDuration − 300 ms)` ile sarılıyor.
- 300 ms pay zorunlu. Kesme noktası tam süreye konursa AVPlayer var olmayan veriyi bekleyerek sonsuza kadar "buffering"de kalıyor.
- Katalog süresi kullanılamaz: saniyeye yuvarlandığı için gerçek süreden uzun olabiliyor.
- Önbellekteki yerel dosyalar da aynı sorunu taşıdığı için kırpılıyor.
- Doğrulama: simülatörde kilit ekranındayken iki geçiş zamanında oldu.

## 2. Katalog süresi olmayan şarkıda otomatik geçişten sonra süre "--:--" kalıyordu

Kırpmadan bağımsız, önceden var olan bir hata.

### Kök neden

- iOS'ta sıradaki şarkılar native just_audio kuyruğuna ekleniyor (`updateRemoteQueue`).
- Geçişte `_handlePrimarySequenceState` yeni öğenin süresini katalogdan alıyor; katalog süresi yoksa null yazıyor.
- Doğru süre ancak `durationStream`'den sonradan bir olay gelirse geri geliyor. Bu akış `distinct()` olduğu için, ardışık iki öğenin native süresi aynıysa olay gelmiyor ve süre null'da kalıyor.

### Düzeltme

- `_nativeSuccessorDuration(state)`, yeni öğeye geçişte `_player.playbackEvent.duration` değerini kullanıyor, ama yalnızca olayın indeksi yeni öğenin indeksiyle eşleşiyorsa.
- Denenip kaldırılan: `_sourceLoadPending` koruması. Açık yüklemeler yeni öğeyi önceden duyurduğu için erişilebilir hiçbir yolu korumuyordu.
- 4 yeni birim testi var ve mutasyonla doğrulandı.
- iOS simülatöründe süre artık null değil (3:46.779).

## 3. İndirilmiş m4a dosyaları iOS'ta da geç bitiyordu

### Kök neden

- İndirme servisi stream'in ham baytlarını dosyaya yazıyor, yani indirilen dosya aynı fragmented MP4. AVFoundation bu dosyada da 2 kat süre raporluyor (205,19 sn'lik dosyaya 410,37 sn).
- Kütüphaneden çalınan dosyalar (`_localAudioSource`) kırpılmıyordu. Simülatörde konum 206 sn'yi geçip 238 sn'ye kadar ilerledi ve "completed" olayı gelmedi.
- Kütüphanedeki süre (`duration_seconds`) saniyeye yuvarlı olduğu için kırpma noktası olarak kullanılamaz.

### Düzeltme

- `lib/services/player/fragmented_mp4_duration.dart`, dosyanın `moov/mvhd` süresini okuyor (`mvhd` 0 ise `mvex/mehd`). Yalnızca `mvex` kutusu olan, yani fragmented dosyalarda bir değer döndürüyor. Fragmented olmayan dosyaları AVFoundation doğru ölçüyor, onlar kırpılmıyor.
- `JustAudioPlayerService._localAudioSource`, iOS'ta `.m4a`/`.mp4` uzantılı yerel dosyaları `ClippingAudioSource(end: moovSüresi − 300 ms)` ile sarıyor. `content://` ve `ipod-library://` kaynakları açılmıyor.
- Okuma sonucu servis ömrü boyunca dosya yoluna göre önbellekte tutuluyor; kuyruk yeniden kurulduğunda dosya tekrar açılmıyor.
- Veritabanı değişikliği yok; eski indirmeler de düzeliyor.
- Doğrulama: gerçek dosyada okuyucu 205,191836 sn buldu (`mvhd` ile aynı). Simülatörde `claude_local_completion_test.dart` ile kırpma kapalıyken şarkı bitmedi; açıkken "completed" 204,891 sn'de geldi.
- 17 yeni birim testi var (11 okuyucu, 6 servis). Kırpma devre dışı bırakılınca servis testleri kalıyor.

### Bilinen küçük fark

- Arayüzdeki süre kütüphanedeki yuvarlı değerden geliyor (3:26). Gerçek süre 3:25,19. Çalmayı etkilemiyor.

## Araştırma testleri (`integration_test/claude_*.dart`)

Canlı YouTube'a gider; `flutter test integration_test/<dosya> -d <UDID>` ile çalıştırılır.

- `claude_completion_test.dart`: Şarkı sonunda "completed" olayının zamanlaması (kırpmalı).
- `claude_advance_duration_test.dart`: 3 öğelik native geçiş, eşit native süre reprodüksiyonu ve snapshot izi.
- `claude_kralin_test.dart`: Uygulamanın iOS format filtresiyle çözümleme ve kırpma A/B karşılaştırması.
- `claude_duration_ab_test.dart`, `claude_duration_test.dart`, `claude_search_play_test.dart`, `claude_webm_test.dart`: Yardımcı ölçümler.
- `claude_local_completion_test.dart`: Uygulamanın indirme yoluyla şarkı indirip kütüphane parçası olarak çalar; kırpma kapalı/açık bitiş zamanını karşılaştırır.
- `claude_url_test.dart`: İmzalı stream URL'sini yazdırır. Yalnızca yerel inceleme için; çıktısını paylaşma.
