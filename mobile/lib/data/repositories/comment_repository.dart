import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../api/api_client.dart';
import '../models/comment.dart';

class CommentRepository {
  Future<List<Comment>> fetchComments(
    String episodeId, {
    String? token,
  }) async {
    final client = createApiClient(token: token);
    final response = await client.getComments(episodeId);
    return response
        .map(
          (item) => Comment.fromJson(
            Map<String, dynamic>.from(item as Map),
          ),
        )
        .toList();
  }

  Future<Comment> createComment({
    required String episodeId,
    required String text,
    required String token,
  }) async {
    final client = createApiClient(token: token);
    final response = await client.createComment(
      episodeId,
      {'text': text},
    );
    final commentMap =
        Map<String, dynamic>.from(response['comment'] as Map<String, dynamic>);
    return Comment.fromJson(commentMap);
  }
}

final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(),
);
