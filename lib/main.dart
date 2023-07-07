import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrcodegenerator/presentation/home/home_screen.dart';
import 'bloc/permission_bloc.dart';
import 'bloc/theme/theme_cubit.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => PermissionBloc(),
        ),
        BlocProvider(create: (context) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, AppTheme>(
        builder: (context, theme) {
          return MaterialApp(
            title: 'QRCode Generator',
            debugShowCheckedModeBanner: false,
            home: const QRHomePage(),
            theme: getThemeData(theme).copyWith(
              useMaterial3: true,
            ),
          );
        },
      ),
    );
  }
}
