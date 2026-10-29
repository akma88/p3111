import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/movie.dart';
import '../data/movie_repository.dart';

enum SearchStatus { initial, loading, ready, error }

class MovieState {
  const MovieState({
    this.status = SearchStatus.initial,
    this.query = '',
    this.movies = const [],
    this.error,
  });
  final SearchStatus status;
  final String query;
  final List<Movie> movies;
  final String? error;
}

class MovieCubit extends Cubit<MovieState> {
  MovieCubit(this.repository) : super(const MovieState());
  final MovieRepository repository;
  Timer? _timer;
  int _request = 0;

  void search(String text, {bool immediately = false}) {
    _timer?.cancel();
    final query = text.trim();
    final request = ++_request;
    emit(MovieState(status: SearchStatus.loading, query: query));
    if (immediately) {
      unawaited(_load(query, request));
    } else {
      _timer = Timer(
        const Duration(milliseconds: 250),
        () => _load(query, request),
      );
    }
  }

  Future<void> _load(String query, int request) async {
    try {
      final movies = await repository.search(query);
      if (!isClosed && request == _request) {
        emit(
          MovieState(status: SearchStatus.ready, query: query, movies: movies),
        );
      }
    } on MovieSearchException catch (e) {
      if (!isClosed && request == _request) {
        emit(
          MovieState(
            status: SearchStatus.error,
            query: query,
            error: e.message,
          ),
        );
      }
    }
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    _request++;
    return super.close();
  }
}
