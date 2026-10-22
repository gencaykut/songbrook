import 'package:bstream_music/features/music/presentation/providers/app_strings.dart';
import 'package:bstream_music/features/music/presentation/providers/app_strings_translation_catalog.dart';
import 'package:bstream_music/features/music/presentation/providers/app_strings_turkish.dart';
import 'package:bstream_music/features/music/presentation/providers/app_strings_turkish_runtime.dart';
import 'package:bstream_music/features/music/presentation/providers/music_providers.dart'
    show innerTubeCatalogLanguage;
import 'package:flutter_test/flutter_test.dart';

final _marker = RegExp(r'ZXQPH\d+X');

Set<String> _markers(String text) =>
    _marker.allMatches(text).map((match) => match[0]!).toSet();

void main() {
  const turkish = AppStrings(AppLanguage.turkish);

  group('Turkish UI strings', () {
    test('every catalog string has a Turkish translation', () {
      final missing = appStringTranslationKeys
          .where((english) => !turkishAppStrings.containsKey(english))
          .toList();

      expect(missing, isEmpty);
    });

    test('translations keep every interpolated value', () {
      for (final entry in turkishAppStrings.entries) {
        expect(_markers(entry.value), _markers(entry.key), reason: entry.key);
      }
    });

    test('choose returns Turkish and falls back to English', () {
      expect(turkish.search, 'Ara');
      expect(turkish.settings, 'Ayarlar');
      expect(turkish.minimizePlayer, 'Oynatıcıyı küçült');
      expect(
        turkish.choose('Sin traducción', 'Not translated'),
        'Not translated',
      );
    });

    test('interpolated strings fill and reorder their values', () {
      expect(turkish.songCount(1), '1 şarkı');
      expect(turkish.songCount(12), '12 şarkı');
      expect(turkish.playbackQueueSummary(3), 'Çalma sırası - 3 şarkı');
      expect(
        turkish.shareSongMessage('Umrumdışı', 'Mabel Matiz'),
        'Mabel Matiz - "Umrumdışı" şarkısını dinle.',
      );
      expect(
        turkish.csvImportResult(
          downloaded: 4,
          reused: 3,
          failed: 2,
          playlists: 1,
        ),
        '4 indirildi, 3 yeniden kullanıldı, 2 başarısız oldu ve 1 çalma '
        'listesi güncellendi.',
      );
    });

    test('a translated phrase composes into a longer sentence', () {
      final body = turkish.playlistSyncConsentBody(2);

      expect(body, startsWith("2 yerel çalma listen Songbrook'ta korunacak. "));
      expect(body, contains('Favoriler'));
      expect(body, isNot(contains('BStream')));
    });

    test('the language is selectable and persisted as tr', () {
      expect(AppLanguage.turkish.label, 'Türkçe');
      expect(AppLanguage.turkish.code, 'tr');
      expect(AppLanguageLabel.fromCode('tr'), AppLanguage.turkish);
    });
  });

  test('Turkish and English interfaces get matching YouTube content', () {
    expect(innerTubeCatalogLanguage(AppLanguage.turkish), 'tr');
    expect(innerTubeCatalogLanguage(AppLanguage.english), 'en');
    for (final language in AppLanguage.values) {
      if (language == AppLanguage.turkish || language == AppLanguage.english) {
        continue;
      }
      // Other languages keep upstream's catalog language.
      expect(innerTubeCatalogLanguage(language), 'es-419');
    }
  });

  group('Turkish runtime messages', () {
    test('translations keep every interpolated value', () {
      for (final entry in turkishRuntimeMessages.entries) {
        expect(_markers(entry.value), _markers(entry.key), reason: entry.key);
      }
    });

    test('translates exact messages and drops exception prefixes', () {
      expect(
        turkish.runtimeMessage(
          'El reproductor tardó demasiado en abrir el audio.',
        ),
        'Oynatıcı sesi açmakta çok gecikti.',
      );
      expect(
        turkish.runtimeMessage(
          'FormatException: El archivo no es un respaldo ZIP valido.',
        ),
        'Dosya geçerli bir ZIP yedeği değil.',
      );
    });

    test('translates the causes nested inside a message', () {
      expect(
        turkish.runtimeMessage(
          'No se pudo descargar: La transferencia dejó de recibir datos.',
        ),
        'İndirilemedi: Aktarım sırasında veri gelmesi durdu.',
      );
      expect(
        turkish.runtimeMessage('Conexión inestable. Reintentando 2/3…'),
        'Bağlantı kararsız. Yeniden deneniyor 2/3…',
      );
    });

    test('keeps unknown text, such as a server response', () {
      expect(
        turkish.runtimeMessage('HTTP 403 Forbidden'),
        'HTTP 403 Forbidden',
      );
      expect(
        turkish.runtimeMessage('No se pudo descargar: HTTP 403'),
        'İndirilemedi: HTTP 403',
      );
    });

    test('other languages keep upstream text', () {
      const message = 'El reproductor tardó demasiado en abrir el audio.';
      for (final language in AppLanguage.values) {
        if (language == AppLanguage.turkish) continue;
        expect(AppStrings(language).runtimeMessage(message), message);
      }
      expect(localizeTurkishRuntimeMessage(message), isNot(message));
    });
  });
}
