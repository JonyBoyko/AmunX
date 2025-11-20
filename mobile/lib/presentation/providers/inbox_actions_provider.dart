import 'package:flutter_riverpod/flutter_riverpod.dart';

class InboxActionsState {
  const InboxActionsState({
    this.listened = const <String>{},
    this.saved = const <String>{},
  });

  final Set<String> listened;
  final Set<String> saved;

  InboxActionsState copyWith({
    Set<String>? listened,
    Set<String>? saved,
  }) {
    return InboxActionsState(
      listened: listened ?? this.listened,
      saved: saved ?? this.saved,
    );
  }

  bool isListened(String episodeId) => listened.contains(episodeId);
  bool isSaved(String episodeId) => saved.contains(episodeId);
}

class InboxActionsNotifier extends StateNotifier<InboxActionsState> {
  InboxActionsNotifier() : super(const InboxActionsState());

  bool markListened(String episodeId) {
    if (state.listened.contains(episodeId)) {
      return false;
    }
    final updated = <String>{...state.listened, episodeId};
    state = state.copyWith(listened: updated);
    return true;
  }

  bool toggleSaved(String episodeId) {
    final updated = <String>{...state.saved};
    bool isSaved;
    if (updated.contains(episodeId)) {
      updated.remove(episodeId);
      isSaved = false;
    } else {
      updated.add(episodeId);
      isSaved = true;
    }
    state = state.copyWith(saved: updated);
    return isSaved;
  }
}

final inboxActionsProvider =
    StateNotifierProvider<InboxActionsNotifier, InboxActionsState>(
  (ref) => InboxActionsNotifier(),
);
