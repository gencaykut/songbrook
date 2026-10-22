import 'package:bstream_music/services/youtube_music/account/youtube_music_account_models.dart';
import 'package:bstream_music/services/youtube_music/account/youtube_music_account_parser.dart';
import 'package:flutter_test/flutter_test.dart';

// Songbrook asks YouTube Music for Turkish pages when the interface is
// Turkish (hl=tr), so playlist metadata arrives in Turkish.
void main() {
  test('reads Turkish playlist visibility and song counts', () {
    final summaries = YouTubeMusicAccountParser().parsePlaylistSummaries(
      _grid(<Map<String, Object?>>[
        _playlist('PL-private', 'Gizli liste', <String>['Gizli', '12 şarkı']),
        _playlist('PL-unlisted', 'Liste dışı liste', <String>[
          'Liste dışı',
          '1.204 şarkı',
        ]),
        _playlist('PL-public', 'Açık liste', <String>[
          'Herkese açık',
          '7 video',
        ]),
      ]),
    );

    expect(summaries.map((summary) => summary.visibility), const [
      RemotePlaylistVisibility.private,
      RemotePlaylistVisibility.unlisted,
      RemotePlaylistVisibility.public,
    ]);
    expect(summaries.map((summary) => summary.itemCount), const [12, 1204, 7]);
  });
}

Map<String, Object?> _grid(List<Map<String, Object?>> items) =>
    <String, Object?>{
      'contents': <Object?>[
        <String, Object?>{
          'sectionListRenderer': <String, Object?>{
            'contents': <Object?>[
              <String, Object?>{
                'gridRenderer': <String, Object?>{'items': items},
              },
            ],
          },
        },
      ],
    };

Map<String, Object?> _playlist(
  String playlistId,
  String title,
  List<String> metadata,
) => <String, Object?>{
  'musicTwoRowItemRenderer': <String, Object?>{
    'title': <String, Object?>{
      'runs': <Object?>[
        <String, Object?>{'text': title},
      ],
    },
    'subtitle': <String, Object?>{
      'runs': <Object?>[
        <String, Object?>{'text': 'Songbrook User'},
        for (final text in metadata) ...<Object?>[
          <String, Object?>{'text': ' • '},
          <String, Object?>{'text': text},
        ],
      ],
    },
    'navigationEndpoint': <String, Object?>{
      'browseEndpoint': <String, Object?>{'browseId': 'VL$playlistId'},
    },
  },
};
