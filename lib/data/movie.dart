const russianTitles = {
  'Castle in the Sky': 'Небесный замок Лапута',
  'Grave of the Fireflies': 'Могила светлячков',
  'My Neighbor Totoro': 'Мой сосед Тоторо',
  "Kiki's Delivery Service": 'Ведьмина служба доставки',
  'Only Yesterday': 'Ещё вчера',
  'Porco Rosso': 'Порко Россо',
  'Pom Poko': 'Помпоко: Война тануки',
  'Whisper of the Heart': 'Шёпот сердца',
  'Princess Mononoke': 'Принцесса Мононоке',
  'My Neighbors the Yamadas': 'Наши соседи Ямада',
  'Spirited Away': 'Унесённые призраками',
  'The Cat Returns': 'Возвращение кота',
  "Howl's Moving Castle": 'Ходячий замок',
  'Tales from Earthsea': 'Сказания Земноморья',
  'Ponyo': 'Рыбка Поньо на утёсе',
  'Arrietty': 'Ариэтти из страны лилипутов',
  'From Up on Poppy Hill': 'Со склонов Кокурико',
  'The Wind Rises': 'Ветер крепчает',
  'The Tale of the Princess Kaguya': 'Сказание о принцессе Кагуя',
  'When Marnie Was There': 'Воспоминания о Марни',
  'The Red Turtle': 'Красная черепаха',
  'Earwig and the Witch': 'Ая и ведьма',
};

class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.englishTitle,
    this.originalTitle = '',
    this.director = '',
    this.description = '',
    this.posterUrl,
    this.releaseYear,
    this.durationMinutes,
    this.score,
  });

  final String id, title, englishTitle, originalTitle, director, description;
  final String? posterUrl;
  final int? releaseYear, durationMinutes, score;
  String get genre => 'Анимация';
  String get year => releaseYear?.toString() ?? 'Год не указан';
  String get duration => durationMinutes == null
      ? 'Длительность не указана'
      : '${durationMinutes! ~/ 60} ч ${durationMinutes! % 60} мин';
  String get searchable =>
      '$title $englishTitle $originalTitle $director ${releaseYear ?? ''}'
          .toLowerCase()
          .replaceAll('ё', 'е');

  static String _text(dynamic value) => value is String ? value : '';
  static int? _number(dynamic value) => int.tryParse('$value');
  static String? _url(dynamic value) {
    final uri = Uri.tryParse(_text(value));
    if (uri == null || !uri.hasAuthority || uri.scheme != 'https') return null;
    return uri.toString();
  }

  factory Movie.fromJson(Map<String, dynamic> json) {
    final english = _text(json['title']);
    final duration = _number(json['running_time']);
    final score = _number(json['rt_score']);
    return Movie(
      id: _text(json['id']),
      title:
          russianTitles[english] ??
          (english.isEmpty ? 'Без названия' : english),
      englishTitle: english,
      originalTitle: _text(json['original_title']),
      director: _text(json['director']),
      description: _text(json['description']),
      posterUrl: _url(json['image']),
      releaseYear: _number(json['release_date']),
      durationMinutes: duration != null && duration > 0 ? duration : null,
      score: score != null && score >= 0 && score <= 100 ? score : null,
    );
  }
}
