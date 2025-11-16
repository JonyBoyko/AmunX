import 'package:flutter_test/flutter_test.dart';
import 'package:moweton_flutter/data/models/episode.dart';
import 'package:moweton_flutter/presentation/providers/author_directory_provider.dart';

Episode _episode(String id, String authorId) {
  return Episode(
    id: id,
    authorId: authorId,
    visibility: 'public',
    status: 'public',
    mask: 'none',
    quality: 'clean',
    createdAt: DateTime.utc(2024, 1, 1),
  );
}

void main() {
  test('syncWithEpisodes registers new authors', () {
    final notifier = AuthorDirectoryNotifier();
    expect(notifier.state.containsKey('author-x'), isFalse);

    notifier.syncWithEpisodes([_episode('e1', 'author-x')]);
    expect(notifier.state.containsKey('author-x'), isTrue);
  });

  test('toggleFollow flips follow state and adjusts followers', () {
    final notifier = AuthorDirectoryNotifier();
    notifier.syncWithEpisodes([_episode('e1', 'author-z')]);

    final before = notifier.state['author-z']!;
    notifier.toggleFollow('author-z');
    final after = notifier.state['author-z']!;

    expect(after.isFollowed, isNot(equals(before.isFollowed)));
    if (before.isFollowed) {
      expect(after.followers, lessThan(before.followers));
    } else {
      expect(after.followers, greaterThan(before.followers));
    }
  });
}
