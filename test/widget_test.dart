import 'dart:async';
import 'dart:convert';
import 'package:p3111/data/movie.dart';
import 'package:p3111/data/movie_repository.dart';
import 'package:p3111/logic/movie_cubit.dart';
import 'package:p3111/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

Map<String, dynamic> movieJson({
  String id = '1',
  String title = 'My Neighbor Totoro',
}) => {
  'id': id,
  'title': title,
  'director': 'Hayao Miyazaki',
  'release_date': '1988',
  'running_time': '86',
  'description': 'A magical encounter in the countryside.',
  'rt_score': '93',
};

void main() {
  test('Missing optional fields and invalid values remain safe', () {
    final movie = Movie.fromJson({
      'id': '1',
      'release_date': 'bad',
      'image': 'javascript:bad',
      'rt_score': '999',
    });
    expect(movie.title, 'Без названия');
    expect(movie.posterUrl, isNull);
    expect(movie.releaseYear, isNull);
    expect(movie.durationMinutes, isNull);
    expect(movie.score, isNull);
  });

  test('Movie metadata and Russian names are parsed', () {
    final movie = Movie.fromJson(movieJson());
    expect(movie.title, 'Мой сосед Тоторо');
    expect(movie.year, '1988');
    expect(movie.duration, '1 ч 26 мин');
    expect(movie.score, 93);
  });

  test(
    'Catalog caches once, deduplicates and searches Russian, English, director, year',
    () async {
      var calls = 0;
      final repository = MovieRepository(
        MockClient((request) async {
          calls++;
          expect(request.url.path, '/films');
          return http.Response(jsonEncode([movieJson(), movieJson()]), 200);
        }),
      );
      expect((await repository.search('')).length, 1);
      for (final query in ['  ТОТОРО ', 'totoro', 'Miyazaki', '1988']) {
        expect((await repository.search(query)).single.id, '1');
      }
      expect(await repository.search('nothing'), isEmpty);
      expect(calls, 1);
    },
  );

  test(
    'Concurrent searches share one request and empty catalog is safe',
    () async {
      var calls = 0;
      final pending = Completer<http.Response>();
      final repository = MovieRepository(
        MockClient((_) {
          calls++;
          return pending.future;
        }),
      );
      final first = repository.search('x');
      final second = repository.search('y');
      await Future<void>.delayed(Duration.zero);
      pending.complete(http.Response('[]', 200));
      expect(await first, isEmpty);
      expect(await second, isEmpty);
      expect(calls, 1);
    },
  );

  test('Server, malformed JSON and network errors can be retried', () async {
    for (final code in [500, 200]) {
      var calls = 0;
      final repository = MovieRepository(
        MockClient((_) async {
          calls++;
          return calls == 1
              ? http.Response('bad', code)
              : http.Response('[]', 200);
        }),
      );
      await expectLater(
        repository.search('x'),
        throwsA(isA<MovieSearchException>()),
      );
      expect(await repository.search(''), isEmpty);
    }
    final repository = MovieRepository(
      MockClient((_) async => throw http.ClientException('offline')),
    );
    await expectLater(
      repository.search('x'),
      throwsA(isA<MovieSearchException>()),
    );
  });

  test('Latest query wins when earlier request finishes', () async {
    final pending = Completer<http.Response>();
    final cubit = MovieCubit(
      MovieRepository(MockClient((_) => pending.future)),
    );
    cubit.search('missing', immediately: true);
    cubit.search('тотo', immediately: true);
    cubit.search('', immediately: true);
    pending.complete(http.Response(jsonEncode([movieJson()]), 200));
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.query, '');
    expect(cubit.state.movies.single.title, 'Мой сосед Тоторо');
    await cubit.close();
  });

  testWidgets('Phone: initial catalog, debounced search, details and clear', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final repository = MovieRepository(
      MockClient((_) async => http.Response(jsonEncode([movieJson()]), 200)),
    );
    await tester.pumpWidget(CineSearchApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('Фильмы Studio Ghibli · 1'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'тоторо');
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();
    expect(find.text('Найдено · 1'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.ensureVisible(find.text('Мой сосед Тоторо'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Мой сосед Тоторо'));
    await tester.pumpAndSettle();
    expect(find.text('О фильме'), findsOneWidget);
    expect(find.text('О чём фильм'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Очистить поиск'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Очистить поиск'));
    await tester.pumpAndSettle();
    expect(find.text('Фильмы Studio Ghibли · 1'), findsNothing);
    expect(find.text('Фильмы Studio Ghibli · 1'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('Error retry and suggestion show empty results', (tester) async {
    var calls = 0;
    final repository = MovieRepository(
      MockClient((_) async {
        calls++;
        return calls == 1 ? http.Response('{}', 500) : http.Response('[]', 200);
      }),
    );
    await tester.pumpWidget(CineSearchApp(repository: repository));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить фильмы'), findsOneWidget);
    await tester.ensureVisible(find.text('Повторить'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    expect(calls, 2);
    await tester.ensureVisible(find.text('Поньо'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Поньо'));
    await tester.pumpAndSettle();
    expect(find.text('Ничего не найдено'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
