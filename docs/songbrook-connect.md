# Songbrook Connect: tasarım ve plan

Durum (26 Ekim 2026): plan onaylandı; şifreleme ilk sürümde yok, eşleştirme 6 haneli kodla. 1. aşama tamam.

## İlerleme

- **1. aşama (tamam):** `lib/services/connect/` altında `connect_models.dart`, `connect_hub.dart`, `connect_client.dart`, `remote_playback.dart` ve zarf için `connect_envelope.dart`. Ariami'nin hub, istemci, model ve uzak oynatma testleri `test/services/connect/` altında; 128 test geçiyor (gerçek yerel WebSocket ile sahiplik, devretme, failover, komut tekrarı, kopma). Plandan sapma: v2 kod yolları çıkarılmadı. Songbrook istemcisi her zaman v3'ü seçiyor; v2'yi çıkarmak Ariami'nin testlerinin bir kısmını atmayı gerektirirdi, çalışma anında maliyeti yok. Ariami'ye özgü ölçüm aracı (`connect_p0_baseline`) ve sözleşme fikstürleri alınmadı. Kimlik doğrulama `identify` mesajındaki `sessionToken` alanında; 2. aşamada eşleştirme anahtarıyla üretilecek.

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
