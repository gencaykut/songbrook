// Turkish versions of the Spanish messages that services and pages raise
// at runtime (errors, progress, status). Upstream writes these in Spanish
// only, so they are keyed by that Spanish text. ZXQPH<n>X marks an
// interpolated value.
//
// Written for Songbrook; upstream BStream has no Turkish catalog.
const Map<String, String> turkishRuntimeMessages = <String, String>{
  'La respuesta remota excede el límite de ZXQPH0X bytes (recibidos: ZXQPH1X).':
      'Sunucudan gelen yanıt ZXQPH0X bayt sınırını aşıyor (alınan: ZXQPH1X).',
  'La transferencia excedió su tiempo total.':
      'Aktarım toplam süre sınırını aştı.',
  'La transferencia dejó de recibir datos.':
      'Aktarım sırasında veri gelmesi durdu.',
  'No se pudo preparar la migración de descargas.':
      'İndirme klasörü taşıma işlemi hazırlanamadı.',
  'No se pudo cerrar la migración de descargas.':
      'İndirme klasörü taşıma işlemi tamamlanamadı.',
  'No se pudo guardar el directorio de descargas.':
      'İndirme klasörü kaydedilemedi.',
  'No se pudo guardar el fondo de la app.':
      'Uygulama arka planı kaydedilemedi.',
  'No se pudo quitar el fondo de la app.': 'Uygulama arka planı kaldırılamadı.',
  'La descarga finalizó sin un archivo de audio válido.':
      'İndirme bitti, ancak geçerli bir ses dosyası oluşmadı.',
  'Descarga cancelada.': 'İndirme iptal edildi.',
  'No se pudo recuperar la reproducción. Toca reproducir para reintentar.':
      'Çalma kurtarılamadı. Tekrar denemek için çal düğmesine dokun.',
  'La fuente almacenada no reemplazó la canción activa.':
      'Kaydedilmiş kaynak çalan şarkının yerine geçemedi.',
  'ZXQPH0X falló. Probando otro cliente InnerTube...':
      'ZXQPH0X başarısız oldu. Başka bir InnerTube istemcisi deneniyor...',
  'ZXQPH0X falló: ZXQPH1X. Probando otro cliente InnerTube...':
      'ZXQPH0X başarısız oldu: ZXQPH1X. Başka bir InnerTube istemcisi deneniyor...',
  'Error de reproducción.': 'Çalma hatası.',
  'Conexión inestable. Reintentando ZXQPH0X/ZXQPH1X…':
      'Bağlantı kararsız. Yeniden deneniyor ZXQPH0X/ZXQPH1X…',
  'Listo para conectar.': 'Bağlanmaya hazır.',
  'Ingresa @usuario o el link del live.':
      '@kullanıcı adını veya yayın bağlantısını gir.',
  'No hay pedidos en la cola LIVE para retirar.':
      'CANLI yayın sırasında geri alınacak istek yok.',
  'Comando no permitido para ZXQPH0X: ZXQPH1X':
      'ZXQPH0X bu komutu kullanamaz: ZXQPH1X',
  'Cola LIVE llena (máximo ZXQPH0X). Límpiala antes de agregar más pedidos.':
      'CANLI yayın sırası dolu (en fazla ZXQPH0X). Yeni istek eklemeden önce sırayı temizle.',
  'No hay una canción LIVE reproduciéndose.':
      'Çalan bir CANLI yayın şarkısı yok.',
  'Reproducción LIVE pausada.': 'CANLI yayın şarkısı duraklatıldı.',
  'No se pudo ejecutar ZXQPH0X: ZXQPH1X': 'ZXQPH0X çalıştırılamadı: ZXQPH1X',
  'La búsqueda excedió ZXQPH0X segundos.': 'Arama ZXQPH0X saniyeyi aştı.',
  'El pedido no contiene una búsqueda.': 'İstekte aranacak bir şey yok.',
  'Sin resultados': 'Sonuç yok',
  'Error desconocido': 'Bilinmeyen hata',
  'No se pudo reproducir "ZXQPH0X": ZXQPH1X': '"ZXQPH0X" çalınamadı: ZXQPH1X',
  'Lista para reproducir en streaming': 'İnternetten çalmaya hazır',
  'Agregado para reproducción remota: ZXQPH0X':
      'İnternetten çalmak için eklendi: ZXQPH0X',
  'El reproductor falló sin detalle.': 'Oynatıcı ayrıntı vermeden durdu.',
  'La playlist ya no está disponible.':
      'Bu çalma listesi artık kullanılamıyor.',
  'La migración del directorio falló y no pudo revertirse por completo: ZXQPH0X (rollback: ZXQPH1X)':
      'Klasör taşıma başarısız oldu ve tamamen geri alınamadı: ZXQPH0X (geri alma: ZXQPH1X)',
  'Debe ser una ruta absoluta no vacía.':
      'Boş olmayan, tam bir dosya yolu olmalı.',
  'La raíz del sistema de archivos no es un destino permitido.':
      'Dosya sisteminin kök dizini hedef olarak seçilemez.',
  'La ruta de referencia no corresponde al origen canónico.':
      'Başvuru yolu asıl kaynakla eşleşmiyor.',
  'El directorio raíz no puede ser un enlace simbólico.':
      'Kök dizin sembolik bağlantı olamaz.',
  'No se pueden migrar enlaces simbólicos: ZXQPH0X':
      'Sembolik bağlantılar taşınamaz: ZXQPH0X',
  'Conflicto de archivo durante la migración.':
      'Taşıma sırasında dosya çakışması oluştu.',
  'El destino cambió durante la migración: ZXQPH0X':
      'Taşıma sırasında hedef değişti: ZXQPH0X',
  'La migración intentó salir del destino administrado.':
      'Taşıma işlemi izin verilen hedefin dışına çıkmaya çalıştı.',
  'No se pueden verificar enlaces simbólicos: ZXQPH0X':
      'Sembolik bağlantılar doğrulanamaz: ZXQPH0X',
  'No se pudo leer de forma segura la sesión guardada.':
      'Kayıtlı oturum güvenli bir şekilde okunamadı.',
  'El canal seleccionado ya no está disponible.':
      'Seçilen kanal artık kullanılamıyor.',
  'El canal seleccionado no ofrece un enlace de acceso válido.':
      'Seçilen kanalın geçerli bir giriş bağlantısı yok.',
  'La sesión de YouTube Music venció. Inicia sesión nuevamente.':
      'YouTube Music oturumunun süresi doldu. Yeniden oturum aç.',
  'La cuenta se desconectó, pero no se pudo eliminar la sesión cifrada. Reintenta cerrar sesión.':
      'Hesap bağlantısı kesildi, ancak şifrelenmiş oturum silinemedi. Oturumu kapatmayı tekrar dene.',
  'YouTube Music devolvió datos de sesión inválidos o incompletos.':
      'YouTube Music geçersiz veya eksik oturum bilgisi gönderdi.',
  'No se pudo validar la cuenta de YouTube Music.':
      'YouTube Music hesabı doğrulanamadı.',
  'La overlay LIVE local solo está disponible en PC.':
      'Yerel CANLI yayın katmanı yalnızca bilgisayarda kullanılabilir.',
  'Microsoft WebView2 no está instalado en este equipo.':
      'Bu bilgisayarda Microsoft WebView2 yüklü değil.',
  'No se pudo preparar una sesión privada para iniciar sesión.':
      'Oturum açmak için gizli bir oturum hazırlanamadı.',
  'Cerrar': 'Kapat',
  'Iniciar sesión': 'Oturum aç',
  'El inicio de sesión integrado está disponible en Android, iOS, Windows y macOS. Puedes seguir usando BStream sin una cuenta.':
      'Uygulama içinden oturum açma Android, iOS, Windows ve macOS\'ta kullanılabilir. Songbrook\'u hesapsız kullanmaya devam edebilirsin.',
  'Cerrando y limpiando la sesión temporal…':
      'Geçici oturum kapatılıp temizleniyor…',
  'Reintentar preparación': 'Hazırlığı tekrar dene',
  'Preparando una sesión privada…': 'Gizli oturum hazırlanıyor…',
  'Se bloqueó una dirección que no pertenece al acceso permitido de Google o YouTube Music.':
      'Google veya YouTube Music girişine ait olmayan bir adres engellendi.',
  'No se pudo volver a YouTube Music después de la verificación.':
      'Doğrulamadan sonra YouTube Music\'e geri dönülemedi.',
  'Selecciona un canal para continuar.': 'Devam etmek için bir kanal seç.',
  'No se pudo completar el inicio de sesión de forma segura.':
      'Oturum güvenli bir şekilde açılamadı.',
  'No se pudo abrir una ventana segura del navegador para iniciar sesión.':
      'Oturum açmak için güvenli bir tarayıcı penceresi açılamadı.',
  'Se perdió la comunicación con la ventana del navegador.':
      'Tarayıcı penceresiyle bağlantı koptu.',
  'Cerrando el navegador y limpiando la sesión temporal…':
      'Tarayıcı kapatılıp geçici oturum temizleniyor…',
  'Reintentar': 'Tekrar dene',
  'Abriendo una ventana privada del navegador para iniciar sesión…':
      'Oturum açmak için gizli bir tarayıcı penceresi açılıyor…',
  'Verificando de forma segura tu sesión de YouTube Music…':
      'YouTube Music oturumun güvenli bir şekilde doğrulanıyor…',
  'Completa el inicio de sesión en la ventana del navegador.\n\nBStream detectará cuando regreses a YouTube Music. La ventana usa un perfil temporal que se eliminará al terminar o cancelar.':
      'Tarayıcı penceresinde oturum açma işlemini tamamla.\n\nYouTube Music\'e döndüğünde Songbrook bunu algılayacak. Pencere, iş bittiğinde veya iptal edildiğinde silinecek geçici bir profil kullanır.',
  'Cancelar': 'İptal',
  'No se pudo mostrar la ventana del navegador.':
      'Tarayıcı penceresi gösterilemedi.',
  'No se pudo reiniciar el acceso en el navegador.':
      'Tarayıcıda giriş yeniden başlatılamadı.',
  'Reproducción pausada': 'Çalma duraklatıldı',
  'No se pudo leer el archivo seleccionado.': 'Seçilen dosya okunamadı.',
  'Elige un canal': 'Bir kanal seç',
  'YouTube Music devolvió un canal distinto al seleccionado.':
      'YouTube Music seçilenden farklı bir kanal döndürdü.',
  'YouTube Music devolvió un enlace de cambio de canal no permitido.':
      'YouTube Music izin verilmeyen bir kanal değiştirme bağlantısı döndürdü.',
  'No se pudieron limpiar las cookies de la sesión anterior de YouTube Music.':
      'Önceki YouTube Music oturumunun çerezleri temizlenemedi.',
  'No se pudo verificar una sesión completa de YouTube Music.':
      'Tam bir YouTube Music oturumu doğrulanamadı.',
  'YouTube Music intentó abrir una dirección no permitida.':
      'YouTube Music izin verilmeyen bir adresi açmaya çalıştı.',
  'La validación de cuenta de YouTube Music aún no está configurada.':
      'YouTube Music hesap doğrulaması henüz yapılandırılmadı.',
  'El inicio de sesión externo solo está disponible en Linux y Windows.':
      'Harici tarayıcıyla oturum açma yalnızca Linux ve Windows\'ta kullanılabilir.',
  'No se encontró Microsoft Edge, Google Chrome, Brave o Chromium.':
      'Microsoft Edge, Google Chrome, Brave veya Chromium bulunamadı.',
  'No se pudo proteger el perfil temporal del navegador.':
      'Tarayıcının geçici profili korunamadı.',
  'El navegador no publicó una pestaña de inicio de sesión.':
      'Tarayıcı bir oturum açma sekmesi sunmadı.',
  'No se pudo conectar de forma privada con el navegador.':
      'Tarayıcıyla gizli bağlantı kurulamadı.',
  'No se pudo eliminar el perfil temporal de la sesión anterior.':
      'Önceki oturumun geçici profili silinemedi.',
  'El navegador no identificó el documento principal de acceso.':
      'Tarayıcı ana giriş sayfasını tanıyamadı.',
  'La pestaña privada se cerró durante la preparación.':
      'Gizli sekme hazırlık sırasında kapandı.',
  'No se pudo abrir una sesión privada en el navegador.':
      'Tarayıcıda gizli bir oturum açılamadı.',
  'La pestaña privada de inicio de sesión se cerró.':
      'Oturum açma için açılan gizli sekme kapandı.',
  'El navegador no pudo abrir la dirección de inicio de sesión.':
      'Tarayıcı oturum açma adresini açamadı.',
  'El historial contenía una dirección no permitida.':
      'Geçmişte izin verilmeyen bir adres vardı.',
  'No se pudo minimizar la ventana de inicio de sesión.':
      'Oturum açma penceresi simge durumuna küçültülemedi.',
  'YouTube Music devolvió una lista de playlists incompleta (ZXQPH0X).':
      'YouTube Music çalma listelerini eksik gönderdi (ZXQPH0X).',
  'La playlist necesita un título.': 'Çalma listesinin bir adı olmalı.',
  'La playlist contiene una referencia remota inválida.':
      'Çalma listesinde geçersiz bir uzak bağlantı var.',
  'YouTube creó la playlist, pero la cuenta cambió antes de confirmar el estado local.':
      'YouTube çalma listesini oluşturdu, ancak yerel durum onaylanmadan önce hesap değişti.',
  'No fue posible confirmar la creación remota.':
      'Çalma listesinin YouTube Music\'te oluşturulduğu doğrulanamadı.',
  'La playlist remota no tiene un identificador válido.':
      'YouTube Music\'teki çalma listesinin geçerli bir kimliği yok.',
  'La playlist observada no coincide con la deseada.':
      'Görülen çalma listesi istenenle eşleşmiyor.',
  'La playlist remota es de solo lectura.':
      'YouTube Music\'teki çalma listesi salt okunur.',
  'La playlist deseada contiene ocurrencias inválidas.':
      'İstenen çalma listesinde geçersiz kayıtlar var.',
  'YouTube no proporcionó identificadores suficientes para editar duplicados de forma segura.':
      'YouTube, tekrarlanan şarkıları güvenle düzenlemek için yeterli kimlik bilgisi vermedi.',
  'La lectura posterior a la escritura quedó incompleta; no se intentará ordenar a ciegas.':
      'Yazmadan sonraki okuma eksik kaldı; sıralama körü körüne denenmeyecek.',
  'YouTube confirmó cambios, pero la sesión no pudo verificarlos antes de ordenar.':
      'YouTube değişiklikleri onayladı, ancak oturum sıralamadan önce bunları doğrulayamadı.',
  'YouTube confirmó cambios, pero no se pudo verificar su estado antes de ordenar.':
      'YouTube değişiklikleri onayladı, ancak sıralamadan önce son durum doğrulanamadı.',
  'La lectura posterior no coincide todavía con las ocurrencias esperadas; no se repetirá ninguna escritura.':
      'Sonraki okuma henüz beklenen kayıtlarla eşleşmiyor; hiçbir yazma işlemi tekrarlanmayacak.',
  'La playlist cambió mientras se estaba ordenando.':
      'Çalma listesi sıralanırken değişti.',
  'La colección de favoritos no tiene un identificador válido.':
      'Favoriler koleksiyonunun geçerli bir kimliği yok.',
  'YouTube Music devolvió una playlist incompleta (ZXQPH0X).':
      'YouTube Music çalma listesini eksik gönderdi (ZXQPH0X).',
  'YouTube Music no devolvió metadatos verificables de la playlist.':
      'YouTube Music doğrulanabilir çalma listesi bilgisi göndermedi.',
  'La sesión activa ya no pertenece a esta cola de sincronización.':
      'Etkin oturum artık bu eşitleme sırasına ait değil.',
  'La cuenta o el canal cambió durante la sincronización.':
      'Eşitleme sırasında hesap veya kanal değişti.',
  'No fue posible confirmar la operación remota.':
      'YouTube Music\'teki işlem doğrulanamadı.',
  'La playlist quedó parcialmente modificada: ZXQPH0X':
      'Çalma listesi kısmen değişti: ZXQPH0X',
  'El título cambió de forma distinta local y remotamente.':
      'Ad, burada ve YouTube Music\'te farklı şekilde değiştirildi.',
  'El orden cambió de forma incompatible en ambos lados.':
      'Sıralama, iki tarafta birbiriyle uyumsuz şekilde değiştirildi.',
  'No existe un vínculo sincronizable.': 'Eşitlenebilecek bir bağlantı yok.',
  'La sincronización está congelada hasta resolver el conflicto.':
      'Çakışma çözülene kadar eşitleme duraklatıldı.',
  'La playlist se eliminó sólo de este dispositivo; la copia remota y su vínculo se conservaron.':
      'Çalma listesi yalnızca bu cihazdan silindi; YouTube Music\'teki kopyası ve bağlantısı korundu.',
  'La sincronización está esperando su backoff controlado.':
      'Eşitleme, belirlenen bekleme süresinin dolmasını bekliyor.',
  'No existe una copia remota que pueda conservarse como resolución.':
      'Çözüm olarak korunabilecek bir YouTube Music kopyası yok.',
  'La playlist cambió durante la verificación del borrado.':
      'Silme doğrulanırken çalma listesi değişti.',
  'No se pudo confirmar el borrado anterior; BStream no lo repetirá automáticamente.':
      'Önceki silme işlemi doğrulanamadı; Songbrook bunu otomatik olarak tekrarlamayacak.',
  'La playlist remota desapareció; no se recreó automáticamente.':
      'YouTube Music\'teki çalma listesi kayboldu; otomatik olarak yeniden oluşturulmadı.',
  'La playlist volvió a cambiar durante la verificación.':
      'Çalma listesi doğrulama sırasında yeniden değişti.',
  'La escritura anterior fue confirmada; los cambios locales más recientes siguen pendientes.':
      'Önceki yazma işlemi onaylandı; yerelde yapılan daha yeni değişiklikler hâlâ bekliyor.',
  'No se pudo confirmar la escritura anterior; se detuvo para evitar duplicarla.':
      'Önceki yazma işlemi doğrulanamadı; tekrarlanmaması için eşitleme durduruldu.',
  'YouTube devolvió ocurrencias que no coinciden con el orden verificado; no se modificó la playlist local.':
      'YouTube, doğrulanan sıralamayla eşleşmeyen kayıtlar gönderdi; yerel çalma listesi değiştirilmedi.',
  'La playlist remota no permite aplicar cambios.':
      'YouTube Music\'teki çalma listesi değişiklik yapılmasına izin vermiyor.',
  'YouTube Music rechazó la modificación.':
      'YouTube Music değişikliği reddetti.',
  'La playlist cambió durante la sincronización.':
      'Çalma listesi eşitleme sırasında değişti.',
  'La creación anterior quedó sin ID remoto; no se repetirá automáticamente.':
      'Önceki oluşturma işlemi YouTube Music kimliği alamadı; otomatik olarak tekrarlanmayacak.',
  'La creación quedó pendiente de verificación.':
      'Oluşturma işlemi doğrulanmayı bekliyor.',
  'YouTube Music rechazó la creación.':
      'YouTube Music oluşturma isteğini reddetti.',
  'YouTube no devolvió un ID verificable.':
      'YouTube doğrulanabilir bir kimlik göndermedi.',
  'La sesión cambió tras crear la playlist.':
      'Çalma listesi oluşturulduktan sonra oturum değişti.',
  'La playlist remota no permite confirmar una eliminación.':
      'YouTube Music\'teki çalma listesi silme işleminin doğrulanmasına izin vermiyor.',
  'YouTube Music rechazó la eliminación.':
      'YouTube Music silme isteğini reddetti.',
  'La sesión cambió tras eliminar.': 'Silme işleminden sonra oturum değişti.',
  'La sesión cambió antes de confirmar la eliminación.':
      'Silme işlemi doğrulanmadan önce oturum değişti.',
  'La playlist local cambió tras eliminar la copia remota.':
      'YouTube Music\'teki kopya silindikten sonra yerel çalma listesi değişti.',
  'La sesión cambió tras eliminar la copia remota.':
      'YouTube Music\'teki kopya silindikten sonra oturum değişti.',
  'La playlist aún existe después de la eliminación.':
      'Silme işleminden sonra çalma listesi hâlâ duruyor.',
  'YouTube Music rechazó el cambio de favoritos.':
      'YouTube Music favori değişikliğini reddetti.',
  'La sesión cambió tras la escritura.':
      'Yazma işleminden sonra oturum değişti.',
  'La escritura quedó pendiente de verificación.':
      'Yazma işlemi doğrulanmayı bekliyor.',
  'La sesión cambió antes de confirmar la escritura.':
      'Yazma işlemi doğrulanmadan önce oturum değişti.',
  'La escritura quedó pendiente de verificación segura.':
      'Yazma işlemi güvenli doğrulamayı bekliyor.',
  'El resultado remoto no coincide todavía.':
      'YouTube Music\'teki sonuç henüz eşleşmiyor.',
  'La escritura no se repetirá hasta resolver su estado.':
      'Durumu netleşene kadar yazma işlemi tekrarlanmayacak.',
  'La playlist local cambió tras la escritura remota.':
      'YouTube Music\'e yazıldıktan sonra yerel çalma listesi değişti.',
  'La sesión cambió tras la escritura remota.':
      'YouTube Music\'e yazıldıktan sonra oturum değişti.',
  'Sin conexión; los cambios quedaron pendientes.':
      'İnternet bağlantısı yok; değişiklikler bekletiliyor.',
  'No se pudieron preparar los encabezados de sesión.':
      'Oturum bilgileri hazırlanamadı.',
  'YouTube no confirmó si aplicó la operación.':
      'YouTube işlemi uygulayıp uygulamadığını doğrulamadı.',
  'YouTube rechazó la operación.': 'YouTube işlemi reddetti.',
  'La respuesta no permitió confirmar el resultado.':
      'Yanıttan sonucun ne olduğu anlaşılamadı.',
  'La operación no llegó a enviarse.': 'İşlem gönderilemedi.',
  'La conexión se perdió sin confirmar la operación.':
      'İşlem doğrulanmadan bağlantı koptu.',
  'No fue posible confirmar la operación.': 'İşlem doğrulanamadı.',
  'YouTube Music no devolvió un perfil de cuenta válido.':
      'YouTube Music geçerli bir hesap profili göndermedi.',
  'YouTube Music no devolvió una identidad de canal estable.':
      'YouTube Music kalıcı bir kanal kimliği göndermedi.',
  'YouTube Music devolvió canales sin una identidad estable.':
      'YouTube Music kalıcı kimliği olmayan kanallar gönderdi.',
  'No se pudieron consultar los canales de YouTube Music.':
      'YouTube Music kanalları alınamadı.',
  'La sesión de YouTube Music ya no es válida.':
      'YouTube Music oturumu artık geçerli değil.',
  'YouTube Music no está disponible temporalmente.':
      'YouTube Music geçici olarak kullanılamıyor.',
  'YouTube Music devolvió una respuesta de cuenta no válida.':
      'YouTube Music geçersiz bir hesap yanıtı gönderdi.',
  'La referencia no contiene un video de YouTube válido.':
      'Bağlantı geçerli bir YouTube videosu içermiyor.',
  'Preparando descarga con InnerTube': 'İndirme InnerTube ile hazırlanıyor',
  'Descarga completada con InnerTube': 'İndirme InnerTube ile tamamlandı',
  'No se pudo descargar: ZXQPH0X': 'İndirilemedi: ZXQPH0X',
  'No se pudo descargar el audio con InnerTube.':
      'Ses InnerTube ile indirilemedi.',
  'No se encontró un nombre de archivo libre.':
      'Boşta bir dosya adı bulunamadı.',
  'Fila ZXQPH0X': 'Satır ZXQPH0X',
  'El archivo CSV está vacío o excede el límite de 16 MiB.':
      'CSV dosyası boş veya 16 MiB sınırını aşıyor.',
  'El CSV no tiene una estructura válida.': 'CSV dosyasının yapısı geçersiz.',
  'El CSV excede el límite de 10000 filas.':
      'CSV dosyası 10000 satır sınırını aşıyor.',
  'El CSV excede el límite de 128 columnas.':
      'CSV dosyası 128 sütun sınırını aşıyor.',
  'Una celda del CSV excede el límite permitido.':
      'CSV dosyasındaki bir hücre izin verilen sınırı aşıyor.',
  'No se reconocen las columnas de título o YouTube del CSV.':
      'CSV dosyasında başlık veya YouTube sütunları tanınamadı.',
  'Fila ZXQPH0X: falta título o ID de YouTube.':
      'Satır ZXQPH0X: başlık veya YouTube kimliği eksik.',
  'El CSV no contiene canciones válidas.': 'CSV dosyasında geçerli şarkı yok.',
  'El CSV UTF-16 está truncado.': 'UTF-16 CSV dosyası eksik.',
  'El respaldo no contiene una base de datos válida.':
      'Yedekte geçerli bir veritabanı yok.',
  'La base de datos del respaldo esta corrupta.': 'Yedekteki veritabanı bozuk.',
  'La versión de la base de datos del respaldo no es compatible.':
      'Yedekteki veritabanının sürümü uyumlu değil.',
  'La base de datos del respaldo no contiene la biblioteca requerida.':
      'Yedekteki veritabanında gerekli kitaplık bilgileri yok.',
  'No se pudo validar la base de datos del respaldo.':
      'Yedekteki veritabanı doğrulanamadı.',
  'No se pudo restaurar la ruta de medios de ZXQPH0X.':
      'ZXQPH0X için medya yolu geri yüklenemedi.',
  'La base de datos activa no contiene la biblioteca requerida.':
      'Etkin veritabanında gerekli kitaplık bilgileri yok.',
  'La base de datos no contiene las tablas de biblioteca requeridas.':
      'Veritabanında gerekli kitaplık tabloları yok.',
  'La base de datos no contiene el orden de la biblioteca requerido.':
      'Veritabanında gerekli kitaplık sıralaması yok.',
  'La biblioteca está ocupada con una operación de mantenimiento (ZXQPH0X). Espera a que termine e intenta nuevamente.':
      'Kitaplıkta şu an bir bakım işlemi sürüyor (ZXQPH0X). Bitmesini bekleyip tekrar dene.',
  'No hay una operación exclusiva pendiente.': 'Bekleyen özel bir işlem yok.',
  'No se pudo actualizar la playlist: ZXQPH0X':
      'Çalma listesi güncellenemedi: ZXQPH0X',
  'La fila no tiene información para buscar.': 'Satırda aranacak bilgi yok.',
  'No se encontraron resultados seguros.': 'Güvenle eşleşen sonuç bulunamadı.',
  'No hubo una coincidencia suficientemente segura para descargar.':
      'İndirmek için yeterince güvenilir bir eşleşme bulunamadı.',
  'El presupuesto del respaldo no es valido.':
      'Yedeğin boyut sınırları geçersiz.',
  'Un archivo del respaldo excede el limite permitido.':
      'Yedekteki bir dosya izin verilen sınırı aşıyor.',
  'El respaldo excede los limites permitidos.':
      'Yedek izin verilen sınırları aşıyor.',
  'El respaldo tiene una relacion de compresion no segura.':
      'Yedeğin sıkıştırma oranı güvenli değil.',
  'El archivo de respaldo no existe o está vacío.':
      'Yedek dosyası yok veya boş.',
  'El respaldo no contiene la base de datos.': 'Yedekte veritabanı yok.',
  'La restauración falló y no se pudo recuperar completamente la biblioteca anterior. Restauración: ZXQPH0X. Recuperación: ZXQPH1X':
      'Geri yükleme başarısız oldu ve önceki kitaplık tamamen kurtarılamadı. Geri yükleme: ZXQPH0X. Kurtarma: ZXQPH1X',
  'El respaldo no puede contener enlaces simbolicos.':
      'Yedek sembolik bağlantı içeremez.',
  'El respaldo contiene una entrada duplicada: ZXQPH0X':
      'Yedekte tekrarlanan bir kayıt var: ZXQPH0X',
  'El respaldo contiene un archivo truncado: ZXQPH0X':
      'Yedekte eksik bir dosya var: ZXQPH0X',
  'El archivo no es un respaldo ZIP valido.':
      'Dosya geçerli bir ZIP yedeği değil.',
  'El directorio del respaldo ZIP esta incompleto.':
      'ZIP yedeğinin dizini eksik.',
  'El respaldo no puede contener archivos cifrados.':
      'Yedek şifrelenmiş dosya içeremez.',
  'El respaldo usa una compresion ZIP no compatible: ZXQPH0X':
      'Yedek desteklenmeyen bir ZIP sıkıştırması kullanıyor: ZXQPH0X',
  'Un archivo del respaldo excede el tamano declarado.':
      'Yedekteki bir dosya bildirilen boyutu aşıyor.',
  'El manifiesto del respaldo excede el límite permitido.':
      'Yedeğin bilgi dosyası izin verilen sınırı aşıyor.',
  'El manifiesto del respaldo no es compatible.':
      'Yedeğin bilgi dosyası uyumlu değil.',
  'El manifiesto del respaldo no es válido.': 'Yedeğin bilgi dosyası geçersiz.',
  'Nuevos para ti': 'Senin için yeni',
  'Descubrimiento para ti': 'Senin için keşifler',
  'Falló la conexión directa con TikTok LIVE: ZXQPH0X':
      'TikTok LIVE ile doğrudan bağlantı kurulamadı: ZXQPH0X',
  'La conexión LIVE se cerró. Reconectando...':
      'CANLI yayın bağlantısı kapandı. Yeniden bağlanılıyor...',
  'No se confirmó la conexión LIVE. Reintentando (ZXQPH0X/ZXQPH1X)...':
      'CANLI yayın bağlantısı doğrulanamadı. Yeniden deneniyor (ZXQPH0X/ZXQPH1X)...',
  'No se pudo mantener la conexión con TikTok LIVE.':
      'TikTok LIVE bağlantısı sürdürülemedi.',
  'No se pudo conectar a TikTok LIVE: ZXQPH0X':
      'TikTok LIVE\'a bağlanılamadı: ZXQPH0X',
  'No encontré un LIVE activo para @ZXQPH0X. ZXQPH1X':
      '@ZXQPH0X için etkin bir CANLI yayın bulunamadı. ZXQPH1X',
  'El LIVE finalizó.': 'CANLI yayın sona erdi.',
  'No se pudo iniciar ZXQPH0X porque el puerto ZXQPH1X ya está en uso.':
      'ZXQPH0X başlatılamadı, çünkü ZXQPH1X numaralı bağlantı noktası kullanımda.',
  'No se pudo iniciar ZXQPH0X porque Windows denegó o reservó el puerto ZXQPH1X.':
      'ZXQPH0X başlatılamadı, çünkü Windows ZXQPH1X numaralı bağlantı noktasını engelledi veya ayırdı.',
  'No se pudo iniciar ZXQPH0X.': 'ZXQPH0X başlatılamadı.',
  'Windows configuró el dominio local, pero BStream no pudo verificar de forma segura http://ZXQPH0X/health.':
      'Windows yerel alan adını yapılandırdı, ancak Songbrook http://ZXQPH0X/health adresini güvenli bir şekilde doğrulayamadı.',
  'No hay una URL reproducible. Obtén la información del track primero.':
      'Çalınabilecek bir URL yok. Önce parçanın bilgilerini al.',
  'La URL reproducible no es válida.': 'Çalınabilecek URL geçersiz.',
  'El reproductor tardó demasiado en abrir el audio.':
      'Oynatıcı sesi açmakta çok gecikti.',
  'falló al verificar la URL': 'URL doğrulanamadı',
  'Error desconocido de reproducción.': 'Bilinmeyen çalma hatası.',
  'Ya hay una transferencia CSV en curso.': 'Zaten süren bir CSV aktarımı var.',
  'El origen y el destino deben ser directorios diferentes.':
      'Kaynak ve hedef farklı klasörler olmalı.',
  'El origen y el destino no pueden estar anidados.':
      'Kaynak ve hedef iç içe olamaz.',
  'El subdirectorio administrado no es un directorio: ZXQPH0X':
      'Yönetilen alt klasör bir klasör değil: ZXQPH0X',
  'La ruta debe apuntar a un directorio.': 'Yol bir klasörü göstermeli.',
  'La ruta atraviesa una entidad que no es un directorio.':
      'Yol, klasör olmayan bir öğenin içinden geçiyor.',
  'Tipo de archivo no compatible: ZXQPH0X':
      'Desteklenmeyen dosya türü: ZXQPH0X',
  'Ya existe un archivo diferente en el destino: ZXQPH0X':
      'Hedefte farklı bir dosya zaten var: ZXQPH0X',
  'La copia temporal no coincide: ZXQPH0X': 'Geçici kopya eşleşmiyor: ZXQPH0X',
  'Conflicto al activar el archivo: ZXQPH0X':
      'Dosya etkinleştirilirken çakışma oluştu: ZXQPH0X',
  'El archivo activado no coincide: ZXQPH0X':
      'Etkinleştirilen dosya eşleşmiyor: ZXQPH0X',
  'El destino administrado no es un directorio seguro.':
      'Yönetilen hedef güvenli bir klasör değil.',
  'La ruta de destino contiene un enlace o archivo: ZXQPH0X':
      'Hedef yolda bir bağlantı veya dosya var: ZXQPH0X',
  'El origen administrado no es un directorio.':
      'Yönetilen kaynak bir klasör değil.',
  'Falta el directorio ZXQPH0X en la copia verificada.':
      'Doğrulanan kopyada ZXQPH0X klasörü eksik.',
  'Falta el archivo ZXQPH0X en la copia verificada.':
      'Doğrulanan kopyada ZXQPH0X dosyası eksik.',
  'El archivo ZXQPH0X no coincide con el original.':
      'ZXQPH0X dosyası asıl dosyayla eşleşmiyor.',
  'No fue posible identificar todas las ocurrencias remotas de forma segura.':
      'YouTube Music\'teki kayıtların tamamı güvenle belirlenemedi.',
  'La escritura anterior coincide en contenido, pero sus ocurrencias no pudieron verificarse de forma segura.':
      'Önceki yazma işleminin içeriği eşleşiyor, ancak kayıtları güvenle doğrulanamadı.',
  'El contenido remoto coincide, pero no sus ocurrencias.':
      'YouTube Music\'teki içerik eşleşiyor, ancak kayıtları eşleşmiyor.',
  'Contenido no disponible': 'İçerik kullanılamıyor',
  'Descargando con InnerTube (ZXQPH0X)': 'InnerTube ile indiriliyor (ZXQPH0X)',
  'Continuando con ZXQPH0X': 'ZXQPH0X ile devam ediliyor',
  'Descargando con ZXQPH0X ZXQPH1X%': 'ZXQPH0X ile indiriliyor %ZXQPH1X',
  'Descargando con ZXQPH0X': 'ZXQPH0X ile indiriliyor',
  'El gestor de descargas ya fue cerrado.':
      'İndirme yöneticisi zaten kapatıldı.',
  'El archivo CSV no existe.': 'CSV dosyası bulunamadı.',
  'El CSV no contiene filas.': 'CSV dosyasında satır yok.',
  'La base de datos no contiene la tabla ZXQPH0X.':
      'Veritabanında ZXQPH0X tablosu yok.',
  'La tabla ZXQPH0X no contiene las columnas requeridas: ZXQPH1X.':
      'ZXQPH0X tablosunda gerekli sütunlar yok: ZXQPH1X.',
  'La tabla ZXQPH0X no tiene la clave primaria requerida.':
      'ZXQPH0X tablosunda gerekli birincil anahtar yok.',
  'Debe ser mayor que cero.': 'Sıfırdan büyük olmalı.',
  'Los respaldos ZIP divididos no son compatibles.':
      'Parçalara bölünmüş ZIP yedekleri desteklenmiyor.',
  'ZXQPH0X no pudo decodificar la respuesta': 'ZXQPH0X yanıtın sesini çözemedi',
  'MediaKit no pudo abrir el audio.': 'MediaKit sesi açamadı.',
  'Volver a intentar': 'Tekrar dene',
  'Volver al navegador': 'Tarayıcıya dön',
  'Reiniciar acceso': 'Girişi yeniden başlat',
  'Mostrar navegador': 'Tarayıcıyı göster',
  'Reproduciendo': 'Çalıyor',
};

const List<String> _exceptionPrefixes = <String>[
  'Exception: ',
  'FormatException: ',
  'Bad state: ',
  'Invalid argument(s): ',
  'FileSystemException: ',
  'TimeoutException: ',
];

final List<_RuntimeTemplate> _runtimeTemplates = () {
  final templates = turkishRuntimeMessages.entries
      .where((entry) => entry.key.contains('ZXQPH'))
      .map(_RuntimeTemplate.new)
      .toList();
  templates.sort(
    (left, right) => right.fixedLength.compareTo(left.fixedLength),
  );
  return List<_RuntimeTemplate>.unmodifiable(templates);
}();

final List<String> _runtimeLiterals = () {
  final literals = turkishRuntimeMessages.keys
      .where((key) => !key.contains('ZXQPH'))
      .toList();
  literals.sort((left, right) => right.length.compareTo(left.length));
  return List<String>.unmodifiable(literals);
}();

final RegExp _runtimeMarker = RegExp(r'ZXQPH(\d+)X');

/// Translates the Spanish messages that services raise into Turkish.
///
/// Messages arrive composed (`No se pudo descargar: <cause>`) and wrapped by
/// exception prefixes, so known messages are replaced wherever they occur and
/// a template's captured values are translated in turn. Unknown text, such as
/// a server's own wording, is left as it is.
String localizeTurkishRuntimeMessage(String message) {
  var text = message;
  for (final prefix in _exceptionPrefixes) {
    if (text.startsWith(prefix)) {
      text = text.substring(prefix.length);
      break;
    }
  }
  return _translate(text, 0);
}

String _translate(String text, int depth) {
  if (text.isEmpty || depth > 4) return text;
  final exact = turkishRuntimeMessages[text];
  if (exact != null) return exact;
  for (final template in _runtimeTemplates) {
    final match = template.matcher.firstMatch(text);
    if (match == null) continue;
    final values = <int, String>{
      for (var i = 0; i < template.markers.length; i++)
        template.markers[i]: _translate(match.group(i + 1) ?? '', depth + 1),
    };
    final translated = template.turkish.replaceAllMapped(
      _runtimeMarker,
      (marker) => values[int.parse(marker.group(1)!)] ?? marker[0]!,
    );
    return _translate(text.substring(0, match.start), depth + 1) +
        translated +
        _translate(text.substring(match.end), depth + 1);
  }
  var result = text;
  for (final literal in _runtimeLiterals) {
    if (result.contains(literal)) {
      result = result.replaceAll(literal, turkishRuntimeMessages[literal]!);
    }
  }
  return result;
}

class _RuntimeTemplate {
  _RuntimeTemplate(MapEntry<String, String> entry)
    : turkish = entry.value,
      fixedLength = entry.key.replaceAll(_runtimeMarker, '').length,
      markers = _runtimeMarker
          .allMatches(entry.key)
          .map((match) => int.parse(match.group(1)!))
          .toList(growable: false),
      matcher = RegExp(_pattern(entry.key), dotAll: true);

  final String turkish;
  final int fixedLength;
  final List<int> markers;
  final RegExp matcher;

  static String _pattern(String key) {
    final chunks = key.split(_runtimeMarker);
    final buffer = StringBuffer();
    for (var i = 0; i < chunks.length; i++) {
      buffer.write(RegExp.escape(chunks[i]));
      if (i < chunks.length - 1) {
        // A trailing value runs to the end of the message.
        buffer.write(
          i == chunks.length - 2 && chunks.last.isEmpty ? '(.+)' : '(.+?)',
        );
      }
    }
    return buffer.toString();
  }
}
