# Songbrook Connect: tasarım ve plan

Durum (27 Ekim 2026): plan onaylandı; şifreleme ilk sürümde yok, eşleştirme 6 haneli kodla. 1–3. aşamalar tamam.

## İlerleme

- **1. aşama (tamam):** `lib/services/connect/` altında `connect_models.dart`, `connect_hub.dart`, `connect_client.dart`, `remote_playback.dart` ve zarf için `connect_envelope.dart`. Ariami'nin hub, istemci, model ve uzak oynatma testleri `test/services/connect/` altında; 128 test geçiyor (gerçek yerel WebSocket ile sahiplik, devretme, failover, komut tekrarı, kopma). Plandan sapma: v2 kod yolları çıkarılmadı. Songbrook istemcisi her zaman v3'ü seçiyor; v2'yi çıkarmak Ariami'nin testlerinin bir kısmını atmayı gerektirirdi, çalışma anında maliyeti yok. Ariami'ye özgü ölçüm aracı (`connect_p0_baseline`) ve sözleşme fikstürleri alınmadı. Kimlik doğrulama `identify` mesajındaki `sessionToken` alanında; 2. aşamada eşleştirme anahtarıyla üretilecek.
- **2. aşama (tamam, 26 Ekim):**
  - Mac: `ConnectHostServer` (`dart:io` `HttpServer`, `/api/ws`, önce 47821 portu) hub'ın önünde; `identify` gelmezse 20 sn'de 4008, kimlik geçersizse 4001 ile kapatır. Bonjour yayını `_songbrook._tcp` (TXT `id`, `v`), `bonsoir` 7.1.5 (MIT).
  - Eşleştirme: Mac'te Ayarlar → Songbrook Connect → Cihaz ekle; 6 haneli kod 2 dakika, tek kullanım, 5 yanlış denemede iptal (`ConnectPairingCode`). Eşleşen cihaz 32 baytlık bir anahtar alır; anahtar iki tarafta Keychain'de (`ConnectStore`).
  - Kimlik: her bağlantıda `v1.<ms>.<nonce>.<HMAC-SHA256>` belirteci (±5 dk, nonce tekrarına izin yok; `ConnectAuthVerifier`). İstemciye her yeniden bağlanmada yeni belirteç için `sessionTokenProvider` eklendi.
  - Bilinen sınırlama (şifresiz ilk sürüm kararı): eşleştirme sırasında anahtar ağda açık gider; aynı ağdaki pasif bir dinleyici o anı yakalarsa anahtarı alabilir. Sonraki bağlantılarda anahtar gönderilmez.
  - Mac bir cihazı kaldırınca bağlantısı 4001 ile kapanır, telefon Mac'i unutur ("Mac'in bu cihazı kaldırdı").
  - `ConnectController` (`connect_controller.dart`): Mac'te hub + sunucu + yayın + Mac'in kendi istemcisi (döngü adresi); telefonda keşif, kodla eşleşme, bilinen Mac'e otomatik bağlanma (Bonjour yoksa son adres). Ayar varsayılan kapalı (`SharedPreferences`). Henüz oynatma yok: cihazlar komut bildirmiyor ve durum yayınlamıyor.
  - Canlı doğrulama (26 Ekim): `integration_test/claude_connect_host_test.dart` (macOS) ile `claude_connect_client_test.dart` (iOS simülatörü) birlikte; kod bir dosya üzerinden geçer (`--dart-define=CONNECT_CODE_FILE=…`), anahtarlar bellekte. Simülatör Mac'i Bonjour'da buldu, Mac'in LAN adresine bağlandı, eşleşme + bağlantı ~0,3 sn. `claude_bonjour_probe_test.dart` Bonsoir yayınını tek başına dener.
  - macOS yerel ağ izni şart: izin verilmeden Bonjour kaydı sessizce askıda kalıyor (ne başladı ne hata olayı). Sistem Ayarları → Gizlilik ve Güvenlik → Yerel Ağ. Gerçek iPhone'la henüz denenmedi.
- **3. aşama (tamam, 27 Ekim):** Oynatıcı Connect'e bağlı; arayüz henüz yok (4. aşama).
  - Köprü `connect_playback.dart` (`ConnectPlayback`, `PlayerConnectPlayback`): `ConnectController` her bağlantıda istemciye anlık görüntüyü, komutları ve devretme adımlarını buradan verir. Testlerde `connectPlaybackProvider` sahteyle değiştirilir.
  - Yayın: kuyruk `PlayerControllerConnect.connectQueue` (`player/player_connect.dart`) ile okunur. Kuyruk değişmedikçe aynı liste kalır, ve v3 kuyruğu yalnızca değişince gönderir. Şarkı alanları: `id` (videoId), `title`, `artist`, `album`, `thumbnail`, `durationMs`, `url`. Yalnızca bu cihazdaki dosyalar (videoId'si olmayan yerel/dış dosya) `localOnly: true` ile gönderilir ve başka cihazda atlanır. Shuffle kuyruğu yeniden sıralamadığı için `backingOrder` hep sıralı. `isPlaying` = `wantsToPlay`. Durum değişince yayınlanır; konum saniyede en fazla bir kez gönderilir.
  - Sahiplik: bu cihazda çalma başlayınca (`wantsToPlay` false→true) cihaz sahip değilse `requestLocalTakeover`. Bağlanırken zaten çalıyorsa da bu çağrılır. Onaydan önce duraklatılırsa `cancelLocalTakeover`. Sahiplik başka cihaza geçince `pauseForTransfer` → `pause()`.
  - Komutlar: play, pause, toggle, next, previous, seek, set_volume, toggle_shuffle, cycle_repeat, play_queue_index, play_context. Kuyruk düzenleme (remove/insert/clear) henüz bildirilmiyor. Çalmayı başlatan komutlar beklenmeden çalıştırılır (`_start`); şarkının açılması saniyeler sürebilir ve gönderen cihaz o arada komutu tekrarlardı.
  - Hazırla: `PlayerController.prepareRemoteQueue(queue, index, position:)` kuyruğu kurar ve şarkıyı duraklatılmış gösterir. Kaynak yüklenmez; durum, şarkı başlamadan duraklatıldığındakiyle aynıdır (`_holdPausedSelection`). Stream burada çözümlenir: bu cihazın çalamadığı şarkıda devretme başarısız olur, öbür cihaz çalmayı sürdürür. Onay geldiğinde istemci `seek` (ertelenmiş konumu günceller) ve `play` (`resume` yükler, sonra o konuma sarar) gönderir. İptalde `apply`, bu cihazın yayınladığı anlık görüntüyle çağrılır; köprü bunu `Expando` ile `connectRestorePoint()`'e eşler. Önceki kuyruk, yerel dosyalarıyla birlikte aynen geri konur (`restoreConnectPoint`).
  - `ConnectController.sendCommand`/`transferTo` ve `ConnectState.playback` (sahibin son anlık görüntüsü) 4. aşamanın arayüzü için hazır.
  - Testler: `connect_controller_test.dart` (sahte oynatıcıyla sahiplik, komut, devretme, devralma), `player_controller_test.dart` "Songbrook Connect" grubu (gerçek denetleyiciyle hazırla, çözümleme hatası, yayın biçimi, geri alma, komutlar).
  - Canlı doğrulama (27 Ekim, `integration_test/claude_connect_playback_test.dart`, macOS): Mac'in gerçek oynatıcısı canlı arama kuyruğunu çalıyor. İkinci bir Connect cihazı gerçek yerel WebSocket üzerinden bağlanıyor; iPhone yerine kayıt tutan bir oynatıcı kullanılıyor. Bu cihaz duraklattı, devam ettirdi, sonraki şarkıya geçti ve sardı; her komut ölçüm aralığı olan 100 ms içinde uygulandı. Telefona devretmede telefon şarkıyı duraklatılmış hazırladı, sonra başladı; Mac sustu. Mac'e geri devretmede Mac aynı şarkı ve konumdan devam etti (1:02 + telefonda geçen 2 sn → 1:04). Gerçek iPhone ya da simülatörle denenmedi.
  - Bilinen: Bir şarkının ilk anlarında yapılan sarma, oynatıcının kendisinde kayboluyor; doğrudan `seek` de aynı anda kayboluyor, yani Connect'e özgü değil. Devretme hedefinde şarkı yüklendikten sonra sarıldığı için baştan bir an duyulabilir. Henüz çözümlenmemiş bir şarkıyı devretmek normal başlatma süresi kadar sürer (~1–3 sn).

## Amaç

Aynı yerel ağdaki Songbrook cihazları tek bir oynatıcı gibi davranır:

- Aynı anda yalnızca bir cihaz çalar (**sahip**). Diğerleri onun şarkısını, kuyruğunu ve konumunu canlı gösterir (**yansıtma**) ve komut gönderir: çal/duraklat, ileri/geri, sarma, shuffle/repeat, ses, kuyrukta bir şarkıya atlama.
- **Devretme:** Cihaz seçicide başka bir cihaza dokununca çalma aynı şarkı, konum ve kuyrukla oraya geçer; eski cihaz susar.
- Yansıtan cihazda yeni bir şey seçmek (arama sonucu, albüm) sahip cihazda çalar.
- Cihazlar arasında ses gönderilmez. Yalnızca şarkı kimliği (`videoId`) ve görünen bilgiler gider; çalan cihaz stream'i kendisi çözümler.

Kapsam dışı: ağlar arası (mobil veriden eve) bağlanma, çoklu oda eşzamanlı çalma, Android (derleme ortamı yok), Windows/Linux.

## Kaynak: Ariami Connect

[Ariami](https://github.com/picccassso/Ariami) (MIT, incelenen sürüm `9b8d27e`, 26 Ekim 2026) aynı modeli üretimde kullanıyor:

- `ariami_core/lib/models/connect_models.dart` (821 satır): mesaj modelleri, doğrulama, sınırlar.
- `ariami_core/lib/services/connect/connect_hub.dart` (1974 satır): hub; saf Dart, yalnızca `web_socket_channel`.
- `ariami_core/lib/services/connect/connect_client.dart` (1692 satır): istemci; yeniden bağlanma, komut tekrarı, sahiplik çiti.
- Testler ~6.300 satır; `docs/connect/` protokol belgesi ve 42 maddelik tuzak listesi.

Bu üç dosya MIT atfıyla uyarlanır (THIRD_PARTY_NOTICES'a eklenir). Songbrook'a göre sadeleştirme:

| Ariami'de | Songbrook'ta |
| --- | --- |
| Ayrı sunucu, hesap/oturum belirteci | Hub Mac uygulamasının içinde; eşleştirme anahtarı ile kimlik |
| Protokol v2 + v3 | Yalnızca v3 (kuyruk ayrı mesajda, değişince) |
| Kullanıcı başına oturum | Tek oturum (eşleşmiş cihazlarının hepsi) |
| `preserve_cast_handoff` | Yok (Cast ile Connect birlikte çalışmaz, ilk sürümde) |
| Kütüphane şarkı kimliği + stream bileti | YouTube `videoId`; her cihaz kendi çözümler |

Korunacak kurallar (belgeden, değiştirilmeden): `ownerEpoch` çiti, sahipliği kaybeden cihazın önce duraklayıp beklemesi, hazırla → onayla → iptal devretmesi, komutların tekrar edilmesi ve `commandId` ile çiftlemenin önlenmesi, gelen mesajların tek sırada işlenmesi, just_audio `play()`'inin beklenmemesi, sesli sahibin gönüllü yeniden bağlanmaması.

## Mimari

```
iPhone (Songbrook)  ──WebSocket──┐
                                 ├──►  Mac (Songbrook) içinde hub  ◄── Mac'in kendi istemcisi
iPad / ikinci Mac   ──WebSocket──┘
```

- **Hub Mac'te çalışır.** Mac uygulaması açıkken hub da açıktır. iPhone hub olamaz: iOS, çalmayan uygulamayı arka planda askıya alır. Mac kapalıysa her cihaz eskisi gibi tek başına çalar.
- Mac'in kendi oynatıcısı da hub'a sıradan bir istemci olarak bağlanır (süreç içinde, ağ yok).
- **Keşif:** Mac, yerel ağda Bonjour ile `_songbrook._tcp` hizmeti yayınlar; iPhone bunu bulur. Paket önerisi: `bonsoir` (lisansı eklemeden önce kontrol edilecek). iOS'ta `NSBonjourServices`'e `_songbrook._tcp` eklenir; yerel ağ izni metni zaten var (Cast için), Connect'i de anacak şekilde güncellenir. macOS 15'ten itibaren Mac için de yerel ağ izni metni gerekebilir.
- **Eşleştirme:** Mac'te Ayarlar → Songbrook Connect → "Cihaz ekle" 6 haneli bir kod gösterir (2 dakika geçerli). iPhone'da kod girilir. Bu, iki cihaz arasında kalıcı bir anahtar üretir (Keychain / `flutter_secure_storage`). Sonraki bağlantılarda hub, anahtarla imzalanmış bir sınamayla (HMAC) cihazı tanır; kod tekrar sorulmaz. Eşleşmeyen cihaz bağlanamaz. QR sonra eklenebilir.
- **Şifreleme:** İlk sürümde düz WebSocket (yerel ağ). Gidenler yalnızca şarkı kimliği, adı, kapak URL'si ve çalma durumu; parola ya da stream URL'si gitmez. TLS ikinci aşamaya bırakılabilir; karar senin.

## Oynatıcıyla bağlantı

Songbrook'ta arayüz `playerControllerProvider`'ı (4000 satırlık `PlayerController`) ve `playbackQueueProvider`'ı okuyor. Plan:

1. **Sahipken yayın:** Denetleyicinin kuyruğu (`TrackInfo` → `{id, title, artist, album, thumbnail, durationMs}`), sıradaki indeks, konum, çalıyor mu, shuffle/repeat, ses düzeyi hub'a gönderilir. Kuyruk yalnızca değişince, durum saniyede en fazla bir kez ve her anlamlı değişiklikte.
2. **Komutları çalıştırma:** Gelen komutlar denetleyicinin var olan yöntemlerine bağlanır: `pause`, `resume`, `togglePlayPause`, `playNext`, `playPrevious`, `seek`, `toggleShuffle`, `cycleRepeatMode`, `setVolume`, `playQueueIndex`. `play_context` (yansıtan cihazda yeni şey seçmek) `playRemote(track, queue: …)`'ye gider.
3. **Devretmede hazırlık:** Hedef cihaz kuyruğu yükleyip konuma gitmeli ama çalmamalı. Denetleyicide bu yok; yeni bir "hazırla" yöntemi gerekir (`prepareRemoteQueue(queue, index, position)`). Mevcut çalma yolunu bozmadan eklenmesi bu işin en dikkat isteyen kısmı.
4. **Yansıtma:** Başka cihaz çalarken denetleyici bir "uzak oturum" kipine geçer: `state` uzak cihazın durumunu, kuyruk paneli uzak kuyruğu gösterir; konum, son mesajın geliş anından ileri hesaplanır. Çal/duraklat, ileri, sarma gibi yöntemler yerel motoru değil komut göndermeyi çağırır. Yerel kuyruk alttan korunur, oturum bitince geri gelir. Böylece widget'ların çoğu değişmez.
5. **Arayüz:** Oynatıcıya bir Connect düğmesi ve cihaz seçici; yansıtırken "Mac'te çalıyor" şeridi; Ayarlar'da eşleşmiş cihazlar, eşleştirme ve cihaz adı.

## Aşamalar

Her aşama ayrı commit'ler ve kendi testleriyle biter.

1. **Protokol çekirdeği (cihaz gerekmez):** Ariami'nin modelleri, hub'ı ve istemcisi uyarlanır (`lib/services/connect/`), v2 ve hesap kısmı çıkarılır. Ariami'nin hub/istemci testleri uyarlanıp çalıştırılır; bellek içi iki istemciyle sahiplik, devretme, failover ve komut tekrarı denenir.
2. **Ağ ve eşleştirme:** Mac'te WebSocket sunucusu (`dart:io` `HttpServer`) ve Bonjour yayını; iPhone'da keşif, kodla eşleştirme, anahtar saklama, yeniden bağlanma. Ayarlar'da cihaz listesi. Doğrulama: Mac ve iPhone birbirini görüyor ve bağlı kalıyor.
3. **Sahip tarafı:** Denetleyici durumu ve kuyruğu yayınlıyor, komutları çalıştırıyor, "hazırla"yı destekliyor. Doğrulama: Mac'te çalan müziği iPhone'dan (geçici bir test ekranıyla) duraklatıp geçebilmek.
4. **Yansıtma ve devretme arayüzü:** Uzak oturum kipi, Connect düğmesi, cihaz seçici, yansıtan cihazdan yeni şarkı başlatma, devretme ve failover.
5. **Gerçek cihaz testi:** Mac + iPhone ile `docs/manual-test-1.0.0.md` biçiminde bir liste: her iki yöne devretme, Mac kapanınca iPhone'un tek başına sürmesi, iPhone arka plandayken ve kilitliyken komutlar, ağ kopması, şarkı sürümü ve SponsorBlock'un hedef cihazda da çalışması.

Kaba boyut: 1. aşama ~2.500–3.000 satır kod + test (çoğu uyarlama), 2. aşama ~1.000, 3–4. aşamalar denetleyiciye dokunduğu için en riskli olanlar.

## Bilinen riskler

- **iOS arka planı:** iPhone duraklatılmış ve arka plandaysa askıya alınır, bağlantı düşer. Sahipse hub hemen failover yapar; çalmadığı için oturum Mac'e duraklatılmış olarak geçer, ses başlamaz. Yansıtan iPhone uygulamaya dönünce yeniden bağlanır.
- **Mac uyuyunca:** Hub kaybolur, iPhone kendi başına devam eder; Mac uyanınca oturum sıfırdan kurulur.
- **Denetleyici karmaşıklığı:** Yansıtma kipi `PlayerController`'ın birçok yöntemine dokunur. Mevcut 2490 test ve yeni testler korunacak.
- **Gecikme:** Hedef cihaz şarkıyı kendisi çözümlediği için devretme ~1–3 sn sürer (normal başlatma süresi kadar).
- **Upstream farkı:** Connect tamamen fork'a ait yeni dosyalarda tutulur; denetleyicideki değişiklikler küçük kancalarla sınırlanır.
