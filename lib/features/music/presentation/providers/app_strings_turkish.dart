// Turkish UI translations, keyed by the English text passed to
// AppStrings.choose. ZXQPH<n>X marks an interpolated value, as in
// app_strings_translation_catalog.dart; a translation may reorder them.
//
// Written for Songbrook; upstream BStream has no Turkish catalog.
const Map<String, String> turkishAppStrings = <String, String>{
  // Labels that upstream writes the same in every language.
  'Crossfade': 'Çapraz geçiş',
  'Liquid Glass Style': 'Liquid Glass stili',
  'Apple Music Style': 'Apple Music stili',
  'Animated Artwork': 'Apple hareketli kapakları',
  'ZXQPH0X s': 'ZXQPH0X sn',
  'Load more': 'Daha fazla yükle',
  'Media output': 'Ses çıkışı',
  'This phone': 'Bu telefon',
  'Cast to': 'Şuraya yayınla',
  'Media volume': 'Medya ses düzeyi',
  'Device volume': 'Cihaz ses düzeyi',
  'More system outputs': 'Diğer sistem çıkışları',
  'The system could not change the audio output.':
      'Sistem ses çıkışını değiştiremedi.',
  'Output requested': 'Çıkış istendi',
  'Connect your device and receiver to the same Wi-Fi.':
      'Cihazını ve alıcıyı aynı Wi-Fi ağına bağla.',
  'No compatible devices found.': 'Uyumlu cihaz bulunamadı.',
  'Searching for devices…': 'Cihazlar aranıyor…',
  'Find devices': 'Cihaz ara',
  'Stop casting': 'Yayını durdur',
  'Could not cast. Music continues on this device.':
      'Yayın yapılamadı. Müzik bu cihazda çalmaya devam ediyor.',
  'Could not read audio outputs.': 'Ses çıkışları okunamadı.',
  'Home': 'Ana sayfa',
  'Good morning': 'Günaydın',
  'Good afternoon': 'İyi günler',
  'Refresh recommendations': 'Önerileri yenile',
  'Refreshing recommendations': 'Öneriler yenileniyor',
  'Popular artists': 'Popüler sanatçılar',
  'Recommended artists': 'Önerilen sanatçılar',
  'Go to artist': 'Sanatçıya git',
  'Go to album': 'Albüme git',
  'The album for this song could not be found.':
      'Bu şarkının albümü bulunamadı.',
  'Artist profile': 'Sanatçı profili',
  'Popular songs': 'Popüler şarkılar',
  'Albums': 'Albümler',
  'Singles': 'Single\'lar',
  'Subscribe': 'Abone ol',
  'Unsubscribe': 'Abonelikten çık',
  'The artist profile could not be loaded.': 'Sanatçı profili yüklenemedi.',
  'The artist mix could not be started.': 'Sanatçının mix\'i başlatılamadı.',
  'The subscription could not be updated.': 'Abonelik güncellenemedi.',
  'A subscription is not available for this artist.':
      'Bu sanatçıya abone olunamıyor.',
  'Sign in to subscribe': 'Abone olmak için oturum aç',
  'YouTube Music account': 'YouTube Music hesabı',
  'YouTube Music': 'YouTube Music',
  'Sign in to YouTube Music': 'YouTube Music\'te oturum aç',
  'Unofficial integration': 'Resmî olmayan entegrasyon',
  'The YouTube Music integration uses unofficial interfaces and is not affiliated with Google. Songbrook never stores your password. YouTube may change, block, or restrict this feature.':
      'YouTube Music entegrasyonu resmî olmayan arayüzler kullanır ve Google ile bağlantılı değildir. Songbrook şifreni asla saklamaz. YouTube bu özelliği değiştirebilir, engelleyebilir veya kısıtlayabilir.',
  'I understand, continue': 'Anladım, devam et',
  'Sync now': 'Şimdi eşitle',
  'Synchronize playlists': 'Çalma listelerini eşitle',
  'Your local playlists will stay':
      'Yerel çalma listelerin Songbrook\'ta korunacak',
  'Your local playlist will stay': 'Yerel çalma listen Songbrook\'ta korunacak',
  'Your ZXQPH0X local playlists will stay':
      'ZXQPH0X yerel çalma listen Songbrook\'ta korunacak',
  'ZXQPH0X in Songbrook. Favorites will sync with YouTube Music Liked Music; unlinked local playlists are created as private playlists and remote playlists are imported here. This first sync does not delete your local playlists.':
      'ZXQPH0X. Favoriler, YouTube Music\'teki Beğenilen müziklerle eşitlenecek; henüz bağlanmamış yerel çalma listeleri gizli liste olarak oluşturulacak, YouTube Music\'teki listeler de buraya aktarılacak. Bu ilk eşitleme yerel çalma listelerinden hiçbirini silmez.',
  'Keep and synchronize': 'Koru ve eşitle',
  'Not now': 'Şimdi değil',
  'Your decision could not be saved. Synchronization was not started.':
      'Seçimin kaydedilemedi. Eşitleme başlatılmadı.',
  'Syncing playlists…': 'Çalma listeleri eşitleniyor…',
  'Playlists synchronized': 'Çalma listeleri eşitlendi',
  'Imported 1 playlist from YouTube Music.':
      'YouTube Music\'ten 1 çalma listesi aktarıldı.',
  'Imported ZXQPH0X playlists from YouTube Music.':
      'YouTube Music\'ten ZXQPH0X çalma listesi aktarıldı.',
  'Resolve conflicts': 'Çakışmaları çöz',
  'Songbrook paused these playlists to avoid repeating or overwriting uncertain changes. Choose which version to keep for each one.':
      'Songbrook, belirsiz değişiklikleri tekrarlamamak veya üzerine yazmamak için bu çalma listelerini durdurdu. Her biri için hangi sürümün kalacağını seç.',
  'Keep Songbrook': 'Songbrook\'takini koru',
  'Keep YouTube Music': 'YouTube Music\'tekini koru',
  'There are no unresolved playlist conflicts.':
      'Çözülmemiş çalma listesi çakışması yok.',
  'The conflict could not be closed. The playlist remains paused to avoid repeating an uncertain write.':
      'Çakışma kapatılamadı. Belirsiz bir yazma işlemini tekrarlamamak için çalma listesi durdurulmuş olarak kalıyor.',
  'Switch channel': 'Kanal değiştir',
  'Disconnect YouTube Music': 'YouTube Music bağlantısını kes',
  'Google blocked sign-in inside the app. For security, Songbrook cannot copy the session from your browser. You can keep using the app without an account.':
      'Google uygulama içinden oturum açmayı engelledi. Güvenlik nedeniyle Songbrook oturumu tarayıcından kopyalayamaz. Uygulamayı hesapsız kullanmaya devam edebilirsin.',
  'Continue listening': 'Dinlemeye devam et',
  'Because you listened…': 'Dinlediklerine göre…',
  'Because you listened to ZXQPH0X': 'ZXQPH0X dinlediğin için',
  'Your mixes': 'Mix\'lerin',
  'New for you': 'Senin için yeni',
  'Discovery': 'Keşfet',
  'Recently played': 'Son dinlenenler',
  'My playlists': 'Çalma listelerim',
  'This selection could not be loaded.': 'Bu seçki yüklenemedi.',
  'This selection has no available songs.':
      'Bu seçkide çalınabilecek şarkı yok.',
  'No recently played songs yet.': 'Henüz hiç şarkı dinlemedin.',
  'Search': 'Ara',
  'Clear search': 'Aramayı temizle',
  'Player': 'Oynatıcı',
  'Local': 'Cihaz',
  'Local music': 'Cihazdaki müzikler',
  'All songs': 'Tüm şarkılar',
  'Folders': 'Klasörler',
  'No local music found': 'Cihazda müzik bulunamadı',
  'Add audio files to the device or review the storage filters.':
      'Cihaza ses dosyası ekle veya depolama filtrelerini kontrol et.',
  'Allow access to your music': 'Müziklerine erişim izni ver',
  'Songbrook needs permission to show and play audio files on this device.':
      'Songbrook\'un bu cihazdaki ses dosyalarını gösterip çalabilmesi için izin gerekiyor.',
  'Allow access': 'Erişime izin ver',
  'Device music could not be read.': 'Cihazdaki müzikler okunamadı.',
  'Play all': 'Tümünü çal',
  'Refresh': 'Yenile',
  'Library': 'Kitaplık',
  'Settings': 'Ayarlar',
  'Open settings': 'Ayarları aç',
  'Song, artist, or album': 'Şarkı, sanatçı veya albüm',
  'Search songs, artists, or albums': 'Şarkı, sanatçı veya albüm ara',
  'Results will appear here.': 'Sonuçlar burada görünecek.',
  'Browse all': 'Tümüne göz at',
  'No songs were found in this category.': 'Bu kategoride şarkı bulunamadı.',
  'This category could not be loaded.': 'Bu kategori yüklenemedi.',
  'Search failed': 'Arama yapılamadı',
  'Songs': 'Şarkılar',
  'Videos': 'Videolar',
  'Artists': 'Sanatçılar',
  'No songs matched this search.': 'Bu aramayla eşleşen şarkı yok.',
  'No videos matched this search.': 'Bu aramayla eşleşen video yok.',
  'No albums matched this search.': 'Bu aramayla eşleşen albüm yok.',
  'Playlists': 'Çalma listeleri',
  'No playlists matched this search.': 'Bu aramayla eşleşen çalma listesi yok.',
  'More results could not be loaded.': 'Daha fazla sonuç yüklenemedi.',
  'No artists matched this search.': 'Bu aramayla eşleşen sanatçı yok.',
  'The YouTube Music catalog did not respond. The InnerTube video fallback was used.':
      'YouTube Music kataloğu yanıt vermedi; bunun yerine InnerTube video araması kullanıldı.',
  'This search uses the InnerTube video fallback and can only show videos.':
      'Bu arama InnerTube video aramasını kullanıyor, bu yüzden yalnızca video gösterebiliyor.',
  'Open album ZXQPH0X': 'ZXQPH0X albümünü aç',
  'Open ZXQPH0X': 'ZXQPH0X öğesini aç',
  'The album songs could not be loaded.': 'Albümün şarkıları yüklenemedi.',
  'This album has no available songs.': 'Bu albümde çalınabilecek şarkı yok.',
  '1 song': '1 şarkı',
  'ZXQPH0X songs': 'ZXQPH0X şarkı',
  'Play': 'Çal',
  'Pause': 'Duraklat',
  'Previous': 'Önceki',
  'Next': 'Sonraki',
  'Download': 'İndir',
  'Download audio': 'Sesi indir',
  'Cancel download': 'İndirmeyi iptal et',
  'Cancel downloads': 'İndirmeleri iptal et',
  'Pending downloads cancelled.': 'Bekleyen indirmeler iptal edildi.',
  'Could not queue the downloads. Try again.':
      'İndirmeler sıraya alınamadı. Tekrar dene.',
  'Could not cancel the downloads. Try again.':
      'İndirmeler iptal edilemedi. Tekrar dene.',
  'Download cancelled': 'İndirme iptal edildi',
  'Nothing playing': 'Çalan bir şey yok',
  'Now playing': 'Şimdi çalıyor',
  'Paused': 'Duraklatıldı',
  'View in list': 'Listede göster',
  'Minimize player': 'Oynatıcıyı küçült',
  'Untitled': 'Adsız',
  'Unknown': 'Bilinmiyor',
  'Playback error': 'Çalma hatası',
  'The selected audio will play, but Android did not allow the rest of the folder to be loaded.':
      'Seçtiğin ses çalınacak, ancak Android klasörün geri kalanının yüklenmesine izin vermedi.',
  'Volume': 'Ses',
  'Volume control': 'Ses düzeyi',
  'Lyrics': 'Şarkı sözleri',
  'Finding lyrics...': 'Şarkı sözleri aranıyor...',
  'We could not find lyrics for this song.': 'Bu şarkının sözlerini bulamadık.',
  'Lyrics could not be loaded.': 'Şarkı sözleri yüklenemedi.',
  'Similar lyrics': 'Benzer şarkı sözleri',
  'Finding similar lyrics...': 'Benzer şarkı sözleri aranıyor...',
  'We could not find any safe similar lyrics.':
      'Güvenle eşleşen benzer şarkı sözü bulamadık.',
  'Choose the correct match': 'Doğru eşleşmeyi seç',
  'Search by another title': 'Başka bir adla ara',
  'Search lyrics': 'Şarkı sözü ara',
  'Synchronized': 'Eşzamanlı',
  'Not synchronized': 'Eşzamanlı değil',
  'Back': 'Geri',
  'No Internet connection.': 'İnternet bağlantısı yok.',
  'This track is marked as instrumental.':
      'Bu parça enstrümantal olarak işaretlenmiş.',
  'These lyrics do not include synchronized timing.':
      'Bu şarkı sözlerinde eşzamanlama bilgisi yok.',
  'Offset': 'Kaydırma',
  'Lyrics options': 'Şarkı sözü seçenekleri',
  'Available for synchronized lyrics.':
      'Eşzamanlı şarkı sözlerinde kullanılabilir.',
  'Translate lyrics': 'Şarkı sözlerini çevir',
  'To the app language · Google Translate': 'Uygulama diline · Google Çeviri',
  'Translating…': 'Çevriliyor…',
  'Unable to translate. The original lyrics remain available.':
      'Çeviri yapılamadı. Özgün şarkı sözleri gösterilmeye devam ediyor.',
  'The lyrics are already in the app language.':
      'Şarkı sözleri zaten uygulamanın dilinde.',
  'Automatic translation: Google Translate': 'Otomatik çeviri: Google Çeviri',
  'Adjust it if the lyrics appear before or after the vocals.':
      'Sözler sesten önce veya sonra görünüyorsa bunu ayarla.',
  'Reset offset': 'Kaydırmayı sıfırla',
  'Lyrics alignment': 'Şarkı sözü hizalaması',
  'Center lyrics': 'Sözleri ortala',
  'Use normal alignment': 'Normal hizalamayı kullan',
  'Normal': 'Normal',
  'Centered': 'Ortalanmış',
  'Lyrics appearance': 'Şarkı sözü görünümü',
  'Customize lyrics animation, alignment, and romanization.':
      'Şarkı sözlerinin animasyonunu, hizalamasını ve Latin harflerine çevrilmesini özelleştir.',
  'Animation': 'Animasyon',
  'Smooth': 'Yumuşak',
  'Slide': 'Kaydırmalı',
  'Highlight': 'Vurgulu',
  'Romanization': 'Latin harfleri',
  'Romanize lyrics': 'Sözleri Latin harfleriyle göster',
  'Convert the selected languages to the Latin alphabet.':
      'Seçilen dillerdeki sözleri Latin alfabesine çevirir.',
  'Languages to romanize': 'Latin harflerine çevrilecek diller',
  'Japanese': 'Japonca',
  'Korean': 'Korece',
  'Chinese': 'Çince',
  'Cyrillic': 'Kiril',
  'Arabic': 'Arapça',
  'Hebrew': 'İbranice',
  'Preview': 'Önizleme',
  'The night begins to glow': 'Gece parlamaya başlıyor',
  'We sing this song together': 'Bu şarkıyı birlikte söylüyoruz',
  'And the rhythm starts again': 'Ve ritim yeniden başlıyor',
  'Play animation': 'Animasyonu oynat',
  'Retry': 'Tekrar dene',
  'Lyrics provided by LRCLIB': 'Şarkı sözleri LRCLIB\'den alınmıştır',
  'Tap a line to seek to that moment.': 'O ana gitmek için bir satıra dokun.',
  'Close': 'Kapat',
  'More options': 'Diğer seçenekler',
  'Share song': 'Şarkıyı paylaş',
  'Listen to "ZXQPH0X" by ZXQPH1X.': 'ZXQPH1X - "ZXQPH0X" şarkısını dinle.',
  'The song could not be shared.': 'Şarkı paylaşılamadı.',
  'Shared song': 'Paylaşılan şarkı',
  'Share playlist': 'Çalma listesini paylaş',
  'Listen to my "ZXQPH0X" playlist on YouTube Music.':
      'YouTube Music\'teki "ZXQPH0X" çalma listemi dinle.',
  'This playlist is private. To share it, its visibility will change to Unlisted. Anyone with the link can view and reshare it, but it will not appear in searches.':
      'Bu çalma listesi gizli. Paylaşmak için görünürlüğü Liste dışı olarak değiştirilecek. Bağlantıya sahip olan herkes listeyi görebilir ve yeniden paylaşabilir, ancak liste aramalarda görünmez.',
  'Change and share': 'Değiştir ve paylaş',
  'Preparing link...': 'Bağlantı hazırlanıyor...',
  'The playlist could not be changed to Unlisted. The link was not shared.':
      'Çalma listesi Liste dışı yapılamadı. Bağlantı paylaşılmadı.',
  'The playlist is now Unlisted, but the share menu could not be opened.':
      'Çalma listesi artık Liste dışı, ancak paylaşım menüsü açılamadı.',
  'The playlist could not be shared.': 'Çalma listesi paylaşılamadı.',
  'Add to playlist': 'Çalma listesine ekle',
  'Could not add to the playlist. Try again.':
      'Çalma listesine eklenemedi. Tekrar dene.',
  'Download all': 'Tümünü indir',
  'Song added to the download queue.': 'Şarkı indirme sırasına eklendi.',
  'ZXQPH0X songs added to the download queue.':
      'ZXQPH0X şarkı indirme sırasına eklendi.',
  'There are no songs left to download.': 'İndirilecek şarkı kalmadı.',
  'Could not queue the playlist download. Try again.':
      'Çalma listesi indirmesi sıraya alınamadı. Tekrar dene.',
  'Favorites': 'Favoriler',
  'Add to favorites': 'Favorilere ekle',
  'Remove from favorites': 'Favorilerden çıkar',
  'Song added to favorites.': 'Şarkı favorilere eklendi.',
  'Song removed from favorites.': 'Şarkı favorilerden çıkarıldı.',
  'Choose playlist': 'Çalma listesi seç',
  '1 song selected': '1 şarkı seçildi',
  'ZXQPH0X songs selected': 'ZXQPH0X şarkı seçildi',
  'Song added to playlist.': 'Şarkı çalma listesine eklendi.',
  'ZXQPH0X songs added to playlist.': 'ZXQPH0X şarkı çalma listesine eklendi.',
  'The selected songs are already in that playlist.':
      'Seçilen şarkılar zaten bu çalma listesinde.',
  'Create a playlist first.': 'Önce bir çalma listesi oluştur.',
  'The song could not be added to the download queue.':
      'Şarkı indirme sırasına eklenemedi.',
  'Error': 'Hata',
  'Downloads': 'İndirilenler',
  'Downloaded songs': 'İndirilen şarkılar',
  'Not downloaded; connection required':
      'İndirilmedi; internet bağlantısı gerekiyor',
  'Playback queue': 'Çalma sırası',
  'There are no songs in the current queue.': 'Çalma sırasında şarkı yok.',
  'Subscriber': 'Abone',
  'Subscribers': 'Aboneler',
  'Already downloaded': 'Zaten indirildi',
  'Playlist': 'Çalma listesi',
  'New playlist': 'Yeni çalma listesi',
  'Create playlist': 'Çalma listesi oluştur',
  'Create': 'Oluştur',
  'Cancel': 'İptal',
  'Name': 'Ad',
  'Filter songs': 'Şarkılarda ara',
  'Drag to reorder': 'Sıralamak için basılı tutup sürükle',
  'No songs to show.': 'Gösterilecek şarkı yok.',
  'There are no local playlists yet.': 'Henüz yerel çalma listesi yok.',
  'This playlist no longer exists.': 'Bu çalma listesi artık yok.',
  'Delete song': 'Şarkıyı sil',
  'Delete songs': 'Şarkıları sil',
  'The downloaded song and its file will be deleted.':
      'İndirilen şarkı ve dosyası silinecek.',
  'ZXQPH0X downloaded songs and their files will be deleted.':
      'İndirilen ZXQPH0X şarkı ve dosyaları silinecek.',
  'Song deleted.': 'Şarkı silindi.',
  'ZXQPH0X songs deleted.': 'ZXQPH0X şarkı silindi.',
  'Delete': 'Sil',
  'Rename': 'Yeniden adlandır',
  'Rename song': 'Şarkıyı yeniden adlandır',
  'Rename playlist': 'Çalma listesini yeniden adlandır',
  'Delete playlist': 'Çalma listesini sil',
  'Song renamed.': 'Şarkının adı değiştirildi.',
  'Playlist renamed.': 'Çalma listesinin adı değiştirildi.',
  'Playlist deleted.': 'Çalma listesi silindi.',
  'Remove only from Songbrook': 'Yalnızca Songbrook\'tan kaldır',
  'Also delete from YouTube Music': 'YouTube Music\'ten de sil',
  'This playlist is synced with YouTube Music. You can remove it only from Songbrook or also delete the playlist from your account. Downloaded songs will not be deleted.':
      'Bu çalma listesi YouTube Music ile eşitleniyor. Listeyi yalnızca Songbrook\'tan kaldırabilir veya hesabından da silebilirsin. İndirilen şarkılar silinmez.',
  'This playlist is linked to YouTube Music, but the active account cannot delete it there. It will only be removed from Songbrook and will not be imported automatically again.':
      'Bu çalma listesi YouTube Music\'e bağlı, ancak etkin hesap onu orada silemiyor. Liste yalnızca Songbrook\'tan kaldırılacak ve bir daha otomatik olarak aktarılmayacak.',
  'The playlist was removed from Songbrook. Its YouTube Music deletion is scheduled for the next sync.':
      'Çalma listesi Songbrook\'tan kaldırıldı. YouTube Music\'ten silinmesi bir sonraki eşitlemede yapılacak.',
  'This does not delete downloaded songs.':
      'Bu işlem indirilen şarkıları silmez.',
  'Remove from playlist': 'Çalma listesinden çıkar',
  'Remove the song from Favorites?': 'Şarkı Favorilerden çıkarılsın mı?',
  'Remove ZXQPH0X songs from Favorites?':
      'ZXQPH0X şarkı Favorilerden çıkarılsın mı?',
  'Remove the song from this playlist?':
      'Şarkı bu çalma listesinden çıkarılsın mı?',
  'Remove ZXQPH0X songs from this playlist?':
      'ZXQPH0X şarkı bu çalma listesinden çıkarılsın mı?',
  'Song removed from Favorites.': 'Şarkı Favorilerden çıkarıldı.',
  'ZXQPH0X songs removed from Favorites.':
      'ZXQPH0X şarkı Favorilerden çıkarıldı.',
  'Song removed from playlist.': 'Şarkı çalma listesinden çıkarıldı.',
  'ZXQPH0X songs removed from playlist.':
      'ZXQPH0X şarkı çalma listesinden çıkarıldı.',
  'Folder': 'Klasör',
  'Export': 'Dışa aktar',
  'Import': 'İçe aktar',
  'Import from local backup': 'Yerel yedekten geri yükle',
  'Restore and replace the library from a ZIP that includes the audio.':
      'Kitaplığı, ses dosyalarını da içeren bir ZIP\'ten geri yükler ve mevcut kitaplığın yerine koyar.',
  'Import from a .csv file': '.csv dosyasından içe aktar',
  'Merge lists and metadata; after confirmation, songs will be downloaded.':
      'Listeleri ve bilgileri birleştirir; onayladıktan sonra şarkılar indirilir.',
  'Export local backup': 'Yerel yedek oluştur',
  'Create a ZIP with the library, its data, and the audio files.':
      'Kitaplığı, bilgilerini ve ses dosyalarını içeren bir ZIP oluşturur.',
  'Export a .csv file': '.csv dosyası olarak dışa aktar',
  'Compatible with MetroList, Harmony, and common formats; no audio included.':
      'MetroList, Harmony ve yaygın biçimlerle uyumludur; ses dosyalarını içermez.',
  'Import and download songs': 'Şarkıları içe aktar ve indir',
  'ZXQPH0X songs and ZXQPH1X playlists were found. ZXQPH2X invalid rows will be skipped and ZXQPH3X repeated rows will be merged. Existing songs will be reused; missing songs will be downloaded in parallel with a safe limit.':
      'ZXQPH0X şarkı ve ZXQPH1X çalma listesi bulundu. Geçersiz ZXQPH2X satır atlanacak, tekrarlanan ZXQPH3X satır birleştirilecek. Zaten olan şarkılar yeniden kullanılacak; eksik olanlar güvenli bir sınırla aynı anda indirilecek.',
  'Downloads may use data and storage. You can stop the import after the active downloads finish.':
      'İndirmeler mobil veri ve depolama alanı kullanabilir. Devam eden indirmeler bittikten sonra içe aktarmayı durdurabilirsin.',
  'Import and download': 'İçe aktar ve indir',
  'Importing library': 'Kitaplık içe aktarılıyor',
  'ZXQPH0X of ZXQPH1X songs': 'ZXQPH0X / ZXQPH1X şarkı',
  'Stop after active downloads': 'Devam edenler bitince durdur',
  'The import will stop after the active downloads finish.':
      'İçe aktarma, devam eden indirmeler bitince duracak.',
  'Import complete': 'İçe aktarma tamamlandı',
  'ZXQPH0X downloaded, ZXQPH1X reused, ZXQPH2X failed, and ZXQPH3X playlists updated.':
      'ZXQPH0X indirildi, ZXQPH1X yeniden kullanıldı, ZXQPH2X başarısız oldu ve ZXQPH3X çalma listesi güncellendi.',
  'The import stopped. Completed items were kept.':
      'İçe aktarma durduruldu. Tamamlanan öğeler korundu.',
  'The CSV contains no compatible songs.': 'CSV dosyasında uyumlu şarkı yok.',
  'The CSV file could not be imported.': 'CSV dosyası içe aktarılamadı.',
  'CSV file format': 'CSV dosya biçimi',
  'CSV file exported.': 'CSV dosyası dışa aktarıldı.',
  'The CSV file could not be exported.': 'CSV dosyası dışa aktarılamadı.',
  'Export backup': 'Yedeği dışa aktar',
  'Import backup': 'Yedeği içe aktar',
  'Backup exported.': 'Yedek dışa aktarıldı.',
  'Backup imported.': 'Yedek içe aktarıldı.',
  'Operation cancelled.': 'İşlem iptal edildi.',
  'Backup failed.': 'Yedekleme tamamlanamadı.',
  'Replace library': 'Kitaplığı değiştir',
  'This backup will replace the current library, playlists, and audio files. This action cannot be undone.':
      'Bu yedek mevcut kitaplığın, çalma listelerinin ve ses dosyalarının yerini alacak. Bu işlem geri alınamaz.',
  'Restore and replace': 'Geri yükle ve değiştir',
  'Language': 'Dil',
  'General': 'Genel',
  'Appearance': 'Görünüm',
  'Theme': 'Tema',
  'Theme and accent color': 'Tema ve vurgu rengi',
  'System': 'Sistem',
  'Light': 'Açık',
  'Dark': 'Koyu',
  'Accent color': 'Vurgu rengi',
  'Surface effects': 'Yüzey efektleri',
  'Surface style': 'Yüzey stili',
  'App background': 'Uygulama arka planı',
  'No background': 'Arka plan yok',
  'Custom': 'Özel',
  'Could not use that photo. Try another image.':
      'Bu fotoğraf kullanılamadı. Başka bir görsel dene.',
  'Accent': 'Vurgu',
  'Transparent': 'Saydam',
  'App font': 'Uygulama yazı tipi',
  'The font already used by the app': 'Uygulamanın şu an kullandığı yazı tipi',
  'Rounded and warm': 'Yuvarlak hatlı ve sıcak',
  'Elegant, with serifs': 'Zarif, tırnaklı',
  'Monospaced and retro': 'Eşit aralıklı ve retro',
  'Rounded and playful': 'Yuvarlak hatlı ve neşeli',
  'Style': 'Stil',
  'Show codec and quality': 'Kodek ve kaliteyi göster',
  'Shows the codec, sample rate, bitrate and channels when available.':
      'Varsa kodeki, örnekleme hızını, bit hızını ve kanal sayısını gösterir.',
  'Stereo': 'Stereo',
  'ZXQPH0X channels': 'ZXQPH0X kanal',
  'Classic Vinyl': 'Klasik Plak',
  'Artwork motion': 'Hareketli kapak',
  'Adds subtle motion, depth, and zoom to the player artwork.':
      'Oynatıcıdaki kapak görseline hafif hareket, derinlik ve yakınlaştırma ekler.',
  'Artwork style': 'Kapak stili',
  'Classic': 'Klasik',
  'Expanded': 'Geniş',
  'Unavailable on Linux; the cover remains visible.':
      'Linux\'ta kullanılamaz; kapak görseli görünmeye devam eder.',
  'Mini player': 'Mini oynatıcı',
  'Floating': 'Yüzen',
  'Mini player background': 'Mini oynatıcı arka planı',
  'Artwork': 'Kapak',
  'White': 'Beyaz',
  'Green': 'Yeşil',
  'Blue': 'Mavi',
  'Purple': 'Mor',
  'Orange': 'Turuncu',
  'Red': 'Kırmızı',
  'Yellow': 'Sarı',
  'Pink': 'Pembe',
  'Teal': 'Camgöbeği',
  'Cyan': 'Açık mavi',
  'Indigo': 'Çivit',
  'Lime': 'Limon yeşili',
  'Mint': 'Nane',
  'Magenta': 'Eflatun',
  'Coral': 'Mercan',
  'Brown': 'Kahverengi',
  'Lavender': 'Lavanta',
  'Ocean': 'Okyanus',
  'Spanish': 'İspanyolca',
  'Playback': 'Çalma',
  'Album': 'Albüm',
  'Privacy and recommendations': 'Gizlilik ve öneriler',
  'Recommendation history': 'Öneri geçmişi',
  'Songbrook learns from the songs you listen to in order to personalize Home.':
      'Songbrook, Ana sayfayı sana göre düzenlemek için dinlediğin şarkılardan öğrenir.',
  'New plays will not be used to personalize Home.':
      'Yeni dinlemelerin Ana sayfayı kişiselleştirmek için kullanılmayacak.',
  'Clear history and recommendations': 'Geçmişi ve önerileri temizle',
  'Deletes local signals and the personalized cache without removing downloads, favorites, or playlists.':
      'İndirmeleri, favorileri ve çalma listelerini silmeden yerel dinleme verilerini ve kişisel öneri önbelleğini siler.',
  'Clear history and recommendations?': 'Geçmiş ve öneriler temizlensin mi?',
  'Songbrook will forget what it learned from your listening. Downloads, favorites, and playlists will remain intact.':
      'Songbrook dinlediklerinden öğrendiklerini unutacak. İndirmelerin, favorilerin ve çalma listelerin olduğu gibi kalacak.',
  'History and recommendations cleared.': 'Geçmiş ve öneriler temizlendi.',
  'Sleep timer': 'Uyku zamanlayıcısı',
  'Storage': 'Depolama',
  'Local music filters': 'Cihaz müziği filtreleri',
  'No active filters': 'Etkin filtre yok',
  '1 active filter': '1 filtre etkin',
  'ZXQPH0X active filters': 'ZXQPH0X filtre etkin',
  'Hide WhatsApp audio': 'WhatsApp seslerini gizle',
  'Hide voice notes and audio stored in WhatsApp folders.':
      'WhatsApp klasörlerindeki sesli mesajları ve ses dosyalarını gizler.',
  'Hide Telegram audio': 'Telegram seslerini gizle',
  'Hide voice notes and audio stored in Telegram folders.':
      'Telegram klasörlerindeki sesli mesajları ve ses dosyalarını gizler.',
  'Hide audio recordings': 'Ses kayıtlarını gizle',
  'Hide files saved by voice and call recorder apps.':
      'Ses ve arama kaydı uygulamalarının kaydettiği dosyaları gizler.',
  'Hide songs shorter than 30 seconds': '30 saniyeden kısa şarkıları gizle',
  'Avoid ringtones, short recordings, and other brief audio.':
      'Zil seslerini, kısa kayıtları ve diğer kısa sesleri dışarıda bırakır.',
  'Backup and restore': 'Yedekleme ve geri yükleme',
  'Export or restore your library and settings.':
      'Kitaplığını ve ayarlarını yedekle veya geri yükle.',
  'Integrations': 'Entegrasyonlar',
  'Open supported links': 'Desteklenen bağlantıları aç',
  'Choose Songbrook to open YouTube and YouTube Music links.':
      'YouTube ve YouTube Music bağlantılarını Songbrook ile açmayı seç.',
  'Could not open the supported links settings.':
      'Desteklenen bağlantılar ayarları açılamadı.',
  'Automatic shutdown': 'Otomatik kapanma',
  'Off': 'Kapalı',
  'Smoothly overlaps the end of one song with the start of the next.':
      'Bir şarkının sonunu bir sonrakinin başlangıcıyla yumuşakça birleştirir.',
  'Crossfade duration': 'Geçiş süresi',
  'Skip silence': 'Sessizliği atla',
  'Automatically shortens detected silence so songs start and transition without waiting.':
      'Algılanan sessizlikleri otomatik olarak kısaltır; şarkılar beklemeden başlar ve birbirine geçer.',
  'Normalize volume': 'Ses seviyesini dengele',
  'Autoplay': 'Otomatik oynatma',
  'Most played': 'En çok dinlediklerin',
  'Download your most played': 'En çok dinlediklerini indir',
  'On Wi-Fi, keeps your 50 most played songs of the last 90 days downloaded and removes those that drop off the list.':
      'Wi-Fi\'deyken son 90 günde en çok dinlediğin 50 şarkıyı indirilmiş tutar, listeden düşenleri siler.',
  'Downloaded automatically': 'Otomatik indirildi',
  'Not played lately': 'Bir süredir dinlemediklerin',
  'Last 30 days': 'Son 30 gün',
  'All time': 'Tüm zamanlar',
  'Played once': 'Bir kez dinlendi',
  'Played ZXQPH0X times': 'ZXQPH0X kez dinlendi',
  'Similar': 'Benzer',
  'Control this Mac\'s music from your iPhone on the same network.':
      'Aynı ağdaki iPhone\'undan bu Mac\'teki müziği yönet.',
  'Control your Mac\'s music from this device on the same network.':
      'Aynı ağdaki Mac\'inde çalan müziği bu cihazdan yönet.',
  'Add a device': 'Cihaz ekle',
  'Shows a code to pair your iPhone.':
      'iPhone\'unu eşleştirmek için bir kod gösterir.',
  'Pairing code': 'Eşleştirme kodu',
  'On your iPhone, open Settings → Songbrook Connect, tap this Mac and enter the code. It is valid for 2 minutes.':
      'iPhone\'unda Ayarlar → Songbrook Connect\'i aç, bu Mac\'e dokun ve kodu gir. Kod 2 dakika geçerli.',
  'Connected': 'Bağlı',
  'Not connected': 'Bağlı değil',
  'Remove device': 'Cihazı kaldır',
  'It will have to pair again to connect.':
      'Yeniden bağlanmak için tekrar eşleşmesi gerekecek.',
  'Looking for your Mac…': 'Mac\'in aranıyor…',
  'Open Songbrook on your Mac and turn on Songbrook Connect. Both must be on the same Wi-Fi network.':
      'Mac\'inde Songbrook\'u aç ve Songbrook Connect\'i aç. İkisi aynı Wi-Fi ağında olmalı.',
  'Tap to pair': 'Eşleştirmek için dokun',
  'Devices': 'Cihazlar',
  'This device': 'Bu cihaz',
  'Playing': 'Çalıyor',
  'Tap to play here': 'Burada çalmak için dokun',
  'Playing on ZXQPH0X': 'ZXQPH0X üzerinde çalıyor',
  'Play something first to move it to another device.':
      'Başka bir cihaza geçirmek için önce bir şey çal.',
  'Enter the code your Mac shows': 'Mac\'inde görünen kodu gir',
  'On the Mac: Settings → Songbrook Connect → Add a device.':
      'Mac\'te: Ayarlar → Songbrook Connect → Cihaz ekle.',
  'Pair': 'Eşleştir',
  'Forget': 'Unut',
  'Not on this network': 'Bu ağda değil',
  'That code is not correct.': 'Kod doğru değil.',
  'The code expired. Show a new one on your Mac.':
      'Kodun süresi doldu. Mac\'inde yeni bir kod göster.',
  'Too many attempts. Show a new code on your Mac.':
      'Çok fazla deneme yapıldı. Mac\'inde yeni bir kod göster.',
  'Your Mac is not showing a code. Tap Add a device on the Mac.':
      'Mac\'inde bir kod görünmüyor. Mac\'te Cihaz ekle\'ye dokun.',
  'Could not reach the Mac.': 'Mac\'e ulaşılamadı.',
  'Your Mac removed this device. Pair it again.':
      'Mac\'in bu cihazı kaldırdı. Yeniden eşleştir.',
  'Songbrook Connect could not start.': 'Songbrook Connect başlatılamadı.',
  'Song version': 'Şarkı sürümü',
  'Prefer song versions': 'Şarkı sürümünü tercih et',
  'Skip non-music parts': 'Müzik olmayan bölümleri atla',
  "Skips intros and talking in music videos using SponsorBlock's community data (CC BY-NC-SA 4.0).":
      'Müzik videolarındaki giriş ve konuşma bölümlerini SponsorBlock topluluk verileriyle (CC BY-NC-SA 4.0) atlar.',
  'When a music video plays, use its song version from YouTube Music if there is one.':
      'Müzik videosu çalınınca, YouTube Music\'te varsa şarkı sürümünü çalar.',
  'Stop playback when the app is closed': 'Uygulama kapatılınca çalmayı durdur',
  'Swiping the app away from recent apps stops the music.':
      'Uygulamayı son uygulamalardan kaydırıp kapatınca müzik durur.',
  'When the queue ends, keep playing similar songs.':
      'Sıra bitince benzer şarkılarla devam eder.',
  "Lowers songs mastered louder than YouTube's reference so playback stays at a steady level.":
      "YouTube'un referansından yüksek kaydedilmiş şarkıların sesini kısar; ses seviyesi dengeli kalır.",
  'Turkish interface that follows the device language until you choose one.':
      'Türkçe arayüz; sen bir dil seçene kadar cihazın dilini izler.',
  'Loud songs are lowered to a steady level, like on YouTube Music.':
      "Yüksek sesli şarkılar YouTube Music'teki gibi dengeli bir seviyeye indirilir.",
  'Search loads more results as you scroll and now finds playlists.':
      'Arama kaydırdıkça daha fazla sonuç yükler ve artık çalma listelerini de bulur.',
  'On iOS, songs now end on time and the player closes with a downward swipe.':
      "iOS'ta şarkılar artık zamanında biter; oynatıcı aşağı kaydırılarak kapanır.",
  'Playback is more reliable when YouTube changes its clients.':
      'YouTube istemcilerini değiştirdiğinde çalma daha güvenilirdir.',
  'Based on BStream Music': 'BStream Music tabanlı',
  'Songbrook is a fork of the open-source project by Bryam Contreras.':
      "Songbrook, Bryam Contreras'ın açık kaynak projesinin bir fork'udur.",
  'Version, credits, and repository': 'Sürüm, emeği geçenler ve depo',
  'Turkish, steady volume, search, and more':
      'Türkçe, dengeli ses, arama ve dahası',
  'Apply': 'Uygula',
  'Timer duration': 'Zamanlayıcı süresi',
  'Start': 'Başlat',
  'Enter a duration between 1 and 720 minutes.':
      '1 ile 720 dakika arasında bir süre gir.',
  'Connect': 'Bağlan',
  'Disconnect': 'Bağlantıyı kes',
  'connected': 'bağlı',
  'disconnected': 'bağlı değil',
  'Pending requests': 'Bekleyen istekler',
  'Browse folder': 'Klasöre göz at',
  'The downloads folder could not be saved.': 'İndirme klasörü kaydedilemedi.',
  'not found': 'bulunamadı',
  'Select downloads folder': 'İndirme klasörünü seç',
  'Queued': 'Sırada',
  'Downloading': 'İndiriliyor',
  'Completed': 'Tamamlandı',
  'Enable shuffle': 'Karıştırmayı aç',
  'Disable shuffle': 'Karıştırmayı kapat',
  'Repeat queue': 'Sırayı tekrarla',
  'Repeat one': 'Bu şarkıyı tekrarla',
  'Disable repeat': 'Tekrarı kapat',
  'The player will stop in ZXQPH0X': 'Oynatıcı ZXQPH0X sonra duracak',
  'ZXQPH0X min': 'ZXQPH0X dk',
  'Application information': 'Uygulama bilgileri',
  'About the app': 'Uygulama hakkında',
  'Version, support, and repository': 'Sürüm, destek ve kaynak kodu',
  'Version': 'Sürüm',
  'New version available': 'Yeni sürüm var',
  'Songbrook version ZXQPH0X is available. You currently have version ZXQPH1X.':
      'Songbrook\'un ZXQPH0X sürümü çıktı. Şu an ZXQPH1X sürümünü kullanıyorsun.',
  'You already have the latest version.': 'En son sürümü kullanıyorsun.',
  'Could not check for a new version.': 'Yeni sürüm denetlenemedi.',
  'The download page could not be opened.': 'İndirme sayfası açılamadı.',
  'Support development': 'Geliştirmeye destek ol',
  'Help maintain Songbrook and keep adding features.':
      'Songbrook\'un bakımına ve yeni özellikler eklenmesine katkıda bulun.',
  'The support page could not be opened.': 'Destek sayfası açılamadı.',
  'GitHub repository': 'GitHub deposu',
  'Source code and contributions': 'Kaynak kodu ve katkılar',
  'The GitHub repository could not be opened.': 'GitHub deposu açılamadı.',
  'pop music': 'pop müzik',
  'Party': 'Parti',
  'party music': 'parti şarkıları',
  'chill music': 'sakin müzik',
  'Love': 'Aşk',
  'love songs': 'aşk şarkıları',
  'Electronic': 'Elektronik',
  'electronic music': 'elektronik müzik',
  'Classical': 'Klasik',
  'classical music': 'klasik müzik',
  'Latin': 'Latin',
  'latin music': 'latin müzik',
  'hip hop music': 'hip hop müzik',
  'Workout': 'Spor',
  'workout music': 'spor için müzik',
  'Sync finished partially; YouTube Music did not return the entire library.':
      'Eşitleme kısmen tamamlandı; YouTube Music kitaplığın tamamını göndermedi.',
  'Sync completed with ZXQPH0X unresolved conflict(s).':
      'Eşitleme tamamlandı, ancak çözülmemiş ZXQPH0X çakışma var.',
  'Playlists could not be synchronized. Your local data was kept without destructive changes.':
      'Çalma listeleri eşitlenemedi. Yerel verilerin hiçbir şey silinmeden korundu.',
  'Song unavailable on YouTube Music': 'Şarkı YouTube Music\'te yok',
  'Exit Lyrics': 'Şarkı sözlerinden çık',
  'Playback timeline': 'Çalma zaman çizelgesi',
  'Track artwork': 'Şarkının kapağı',
  'Artwork for ZXQPH0X': 'ZXQPH0X kapağı',
  'Playback progress': 'Çalma ilerlemesi',
  'Instrumental break': 'Enstrümantal ara',
  'Delay lyrics by 0.50 seconds': 'Sözleri 0,50 saniye geciktir',
  'Advance lyrics by 0.50 seconds': 'Sözleri 0,50 saniye öne al',
  'What\'s new in ZXQPH0X': 'ZXQPH0X sürümündeki yenilikler',
  'Widget, customization, performance, languages, and more':
      'Widget, özelleştirme, performans, diller ve daha fazlası',
  'Checking account': 'Hesap denetleniyor',
  'The session is stored encrypted only on this device.':
      'Oturum yalnızca bu cihazda şifrelenmiş olarak saklanır.',
  'Done': 'Tamam',
  'The encrypted YouTube Music session will be removed from this device. Your local library will not be deleted.':
      'Şifrelenmiş YouTube Music oturumu bu cihazdan kaldırılacak. Yerel kitaplığın silinmeyecek.',
  'Sign in to connect your account': 'Hesabını bağlamak için oturum aç',
  'Checking account…': 'Hesap denetleniyor…',
  'Sign out': 'Oturumu kapat',
  'Sign in': 'Oturum aç',
  'Sign out?': 'Oturum kapatılsın mı?',
  'This account will be disconnected from this device. Your local library will not be deleted.':
      'Bu hesabın bu cihazla bağlantısı kesilecek. Yerel kitaplığın silinmeyecek.',
  'ZXQPH0X song': 'ZXQPH0X şarkı',
  'ZXQPH0X Song': 'ZXQPH0X Şarkı',
  'ZXQPH0X Songs': 'ZXQPH0X Şarkı',
  'Playback Queue - ZXQPH0X Song': 'Çalma sırası - ZXQPH0X şarkı',
  'Playback Queue - ZXQPH0X Songs': 'Çalma sırası - ZXQPH0X şarkı',
  'Press once to exit.': 'Çıkmak için bir kez daha bas.',
  'Press ZXQPH0X more times to exit.': 'Çıkmak için ZXQPH0X kez daha bas.',
  'ZXQPH0X: ZXQPH1X': 'ZXQPH0X: ZXQPH1X',
  'ZXQPH0X: ZXQPH1X - ZXQPH2X queued':
      'ZXQPH0X: ZXQPH1X - sırada ZXQPH2X şarkı',
  'The player widget is now available for your home screen.':
      'Oynatıcı widget\'ını artık ana ekranına ekleyebilirsin.',
  'Personalize the app background with an image from your gallery.':
      'Uygulamanın arka planını galerindeki bir görselle kişiselleştir.',
  'You can now change the font throughout the app.':
      'Artık uygulamanın tamamında yazı tipini değiştirebilirsin.',
  'Animated artwork performance has been optimized.':
      'Hareketli kapak görsellerinin performansı iyileştirildi.',
  'Select multiple songs in albums, mixes, and search results to add them to a playlist or download them.':
      'Albümlerde, mix\'lerde ve arama sonuçlarında birden fazla şarkı seçip çalma listesine ekleyebilir veya indirebilirsin.',
  'Interface performance and smoothness have been improved.':
      'Arayüz daha hızlı ve akıcı hâle getirildi.',
  'Album, mix, and artist pages now inherit colors from their cover art.':
      'Albüm, mix ve sanatçı sayfaları artık renklerini kapak görsellerinden alıyor.',
  'Portuguese, French, Korean, Chinese, and Japanese are now supported.':
      'Artık Portekizce, Fransızca, Korece, Çince ve Japonca da destekleniyor.',
};

final List<_TurkishTemplate> _turkishTemplates = () {
  final templates = turkishAppStrings.entries
      .where((entry) => entry.key.contains('ZXQPH'))
      .map(_TurkishTemplate.new)
      .toList();
  // Prefer the most specific template when several could match.
  templates.sort(
    (left, right) => right.english.length.compareTo(left.english.length),
  );
  return List<_TurkishTemplate>.unmodifiable(templates);
}();

final RegExp _marker = RegExp(r'ZXQPH(\d+)X');

/// Returns the Turkish text for [english], or null when it has none.
String? translateTurkishAppString(String english) {
  final exact = turkishAppStrings[english];
  if (exact != null) return exact;
  for (final template in _turkishTemplates) {
    final match = template.matcher.firstMatch(english);
    if (match == null) continue;
    final values = <int, String>{
      for (var i = 0; i < template.markers.length; i++)
        template.markers[i]: match.group(i + 1) ?? '',
    };
    return template.turkish.replaceAllMapped(
      _marker,
      (marker) => values[int.parse(marker.group(1)!)] ?? marker[0]!,
    );
  }
  return null;
}

class _TurkishTemplate {
  _TurkishTemplate(MapEntry<String, String> entry)
    : english = entry.key,
      turkish = entry.value,
      markers = _marker
          .allMatches(entry.key)
          .map((match) => int.parse(match.group(1)!))
          .toList(growable: false),
      matcher = RegExp(
        '^${entry.key.split(RegExp(r'ZXQPH\d+X')).map(RegExp.escape).join('(.*?)')}\$',
        dotAll: true,
      );

  final String english;
  final String turkish;
  final List<int> markers;
  final RegExp matcher;
}
