import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:http/http.dart' as http;
import 'data/movie_repository.dart';
import 'logic/movie_cubit.dart';
import 'ui/movie_screen.dart';

void main() => runApp(const CineSearchApp());

class CineSearchApp extends StatelessWidget {
  const CineSearchApp({super.key, this.repository});
  final MovieRepository? repository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<http.Client>(
      create: (_) => http.Client(),
      dispose: (client) => client.close(),
      child: BlocProvider(
        create: (context) => MovieCubit(
          repository ?? MovieRepository(context.read<http.Client>()),
        )..search('', immediately: true),
        child: MaterialApp(
          title: 'CineSearch',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            scaffoldBackgroundColor: const Color(0xFF101116),
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xFFFFB26B),
              brightness: Brightness.dark,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Color(0xFF101116),
              elevation: 0,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1D1F28),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          home: const MovieScreen(),
        ),
      ),
    );
  }
}
