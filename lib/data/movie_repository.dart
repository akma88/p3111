import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'movie.dart';

class MovieSearchException implements Exception {
  const MovieSearchException(this.message);
  final String message;
}

class MovieRepository {
  MovieRepository(this.client);
  final http.Client client;
  List<Movie>? _cache;
  Future<List<Movie>>? _inFlight;

  Future<List<Movie>> search(String text) async {
    final all = _cache ?? await (_inFlight ??= _load());
    final query = text.trim().toLowerCase().replaceAll('ё', 'е');
    return List.unmodifiable(
      all.where((movie) => movie.searchable.contains(query)),
    );
  }

  Future<List<Movie>> _load() async {
    try {
      final response = await client
          .get(Uri.https('ghibliapi.vercel.app', '/films'))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode != 200) {
        throw const MovieSearchException(
          'Каталог временно недоступен. Попробуйте ещё раз.',
        );
      }
      final body = jsonDecode(utf8.decode(response.bodyBytes)) as List;
      final movies = <String, Movie>{};
      for (final item in body) {
        if (item is Map<String, dynamic> &&
            item['id'] is String &&
            (item['id'] as String).isNotEmpty) {
          final movie = Movie.fromJson(item);
          movies[movie.id] = movie;
        }
      }
      final list = movies.values.toList()
        ..sort((a, b) => (b.releaseYear ?? 0).compareTo(a.releaseYear ?? 0));
      return _cache = List.unmodifiable(list);
    } on TimeoutException {
      throw const MovieSearchException(
        'Сервер долго отвечает. Попробуйте ещё раз.',
      );
    } on http.ClientException {
      throw const MovieSearchException(
        'Нет соединения с каталогом. Проверьте интернет.',
      );
    } on FormatException {
      throw const MovieSearchException('Не удалось прочитать ответ каталога.');
    } on TypeError {
      throw const MovieSearchException('Каталог вернул неожиданные данные.');
    } finally {
      _inFlight = null;
    }
  }
}
