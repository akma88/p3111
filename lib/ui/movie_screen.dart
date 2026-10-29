import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../data/movie.dart';
import '../logic/movie_cubit.dart';

const accent = Color(0xFFFFB26B);
const muted = Color(0xFFA3A5B4);

class MovieScreen extends StatefulWidget {
  const MovieScreen({super.key});
  @override
  State<MovieScreen> createState() => _MovieScreenState();
}

class _MovieScreenState extends State<MovieScreen> {
  final _controller = TextEditingController();
  void _search(String query) {
    _controller.text = query;
    FocusScope.of(context).unfocus();
    context.read<MovieCubit>().search(query, immediately: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.movie_filter_outlined, color: accent),
            SizedBox(width: 10),
            Flexible(
              child: Text(
                'CineSearch',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                ),
              ),
            ),
          ],
        ),
        actions: [
          if (MediaQuery.sizeOf(context).width > 430)
            const Padding(
              padding: EdgeInsets.only(right: 20),
              child: Text(
                'КИНОКАТАЛОГ',
                style: TextStyle(fontSize: 10, letterSpacing: 2, color: muted),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.search,
                          onChanged: (value) =>
                              context.read<MovieCubit>().search(value),
                          onSubmitted: _search,
                          decoration: InputDecoration(
                            hintText: 'Название, режиссёр или год',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: muted,
                            ),
                            prefixIcon: const Icon(Icons.search, color: accent),
                            suffixIcon: IconButton(
                              tooltip: 'Очистить поиск',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _controller.clear();
                                context.read<MovieCubit>().search('');
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final title in [
                              'Тоторо',
                              'Ходячий замок',
                              'Поньо',
                              'Все фильмы',
                            ])
                              ActionChip(
                                label: Text(title),
                                onPressed: () =>
                                    _search(title == 'Все фильмы' ? '' : title),
                              ),
                          ],
                        ),
                        const SizedBox(height: 26),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<MovieCubit, MovieState>(
                  builder: (context, state) {
                    if (state.status == SearchStatus.initial) {
                      return const SliverToBoxAdapter(
                        child: _Message(
                          icon: Icons.local_movies_outlined,
                          title: 'Твой следующий фильм — здесь',
                          description:
                              'Введи название или выбери одну из подсказок.\nПоиск на русском и английском.',
                        ),
                      );
                    }
                    if (state.status == SearchStatus.loading) {
                      return const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.all(64),
                          child: Center(
                            child: CircularProgressIndicator(color: accent),
                          ),
                        ),
                      );
                    }
                    if (state.status == SearchStatus.error) {
                      return SliverToBoxAdapter(
                        child: _Message(
                          icon: Icons.wifi_off_rounded,
                          title: 'Не удалось загрузить фильмы',
                          description: state.error ?? 'Попробуйте ещё раз.',
                          action: FilledButton(
                            onPressed: () => _search(state.query),
                            child: const Text('Повторить'),
                          ),
                        ),
                      );
                    }
                    if (state.movies.isEmpty) {
                      return const SliverToBoxAdapter(
                        child: _Message(
                          icon: Icons.search_off,
                          title: 'Ничего не найдено',
                          description:
                              'Попробуй другое название, режиссёра или год.\nВ каталоге только фильмы Studio Ghibli.',
                        ),
                      );
                    }
                    return SliverPadding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      sliver: SliverMainAxisGroup(
                        slivers: [
                          SliverToBoxAdapter(
                            child: Padding(
                              padding: const EdgeInsets.only(bottom: 18),
                              child: Text(
                                '${state.query.isEmpty ? 'Фильмы Studio Ghibli' : 'Найдено'} · ${state.movies.length}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                          SliverLayoutBuilder(
                            builder: (context, constraints) {
                              final columns = constraints.crossAxisExtent > 850
                                  ? 4
                                  : constraints.crossAxisExtent > 580
                                  ? 3
                                  : 2;
                              final scale = MediaQuery.textScalerOf(
                                context,
                              ).scale(1);
                              return SliverGrid(
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: columns,
                                      crossAxisSpacing: 14,
                                      mainAxisSpacing: 18,
                                      mainAxisExtent:
                                          ((constraints.crossAxisExtent -
                                                      (columns - 1) * 14) /
                                                  columns) *
                                              1.5 +
                                          110 * scale,
                                    ),
                                delegate: SliverChildBuilderDelegate(
                                  (context, index) =>
                                      _MovieCard(movie: state.movies[index]),
                                  childCount: state.movies.length,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'Данные: Studio Ghibli API · Неофициальный каталог\nПоиск на русском и английском. Каталог может быть неполным.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: muted, fontSize: 11, height: 1.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.title,
    required this.description,
    this.action,
  });
  final IconData icon;
  final String title, description;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 35),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFF242028),
            borderRadius: BorderRadius.circular(26),
          ),
          child: Icon(icon, size: 38, color: accent),
        ),
        const SizedBox(height: 22),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        Text(
          description,
          textAlign: TextAlign.center,
          style: const TextStyle(color: muted, height: 1.6),
        ),
        if (action != null) ...[const SizedBox(height: 16), action!],
      ],
    ),
  );
}

class MoviePoster extends StatelessWidget {
  const MoviePoster({super.key, required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) {
    final placeholder = ColoredBox(
      color: const Color(0xFF292B37),
      child: Center(
        child: Icon(
          Icons.movie_outlined,
          size: 48,
          color: accent.withValues(alpha: 0.5),
        ),
      ),
    );
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 2 / 3,
        child: movie.posterUrl == null
            ? placeholder
            : Image.network(
                movie.posterUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, error, stack) => placeholder,
                loadingBuilder: (_, child, progress) =>
                    progress == null ? child : placeholder,
              ),
      ),
    );
  }
}

class _MovieCard extends StatelessWidget {
  const _MovieCard({required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: () => Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => MovieDetailScreen(movie: movie)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MoviePoster(movie: movie),
        const SizedBox(height: 10),
        Text(
          movie.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700, height: 1.3),
        ),
        const SizedBox(height: 5),
        Text(
          '${movie.year} · ${movie.genre}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11, color: muted),
        ),
      ],
    ),
  );
}

class MovieDetailScreen extends StatelessWidget {
  const MovieDetailScreen({super.key, required this.movie});
  final Movie movie;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('О фильме')),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 650),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: SizedBox(width: 220, child: MoviePoster(movie: movie)),
              ),

              const SizedBox(height: 24),
              Text(
                movie.title,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final label in [
                    movie.year,
                    movie.genre,
                    movie.duration,
                    if (movie.score != null) 'RT ${movie.score}%',
                  ])
                    if (label.isNotEmpty) Chip(label: Text(label)),
                ],
              ),
              if (movie.director.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'Режиссёр: ${movie.director}',
                    style: const TextStyle(color: muted),
                  ),
                ),
              const SizedBox(height: 28),
              const Text(
                'О чём фильм',
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                movie.description.isEmpty
                    ? 'Описание пока отсутствует.'
                    : movie.description,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.65,
                  color: Color(0xFFD1D2DB),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Описание на английском предоставлено Studio Ghibli API. RT — оценка Rotten Tomatoes из каталога; она может отличаться от текущей.',
                style: TextStyle(color: muted, fontSize: 12, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
