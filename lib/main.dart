import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qrcodegenerator/views/home/home_screen.dart';

import 'bloc/permission_bloc.dart';
import 'cubit/theme_cubit.dart';
import 'cubit/theme_state.dart';

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
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, state) {
          return MaterialApp(
            title: 'QR Scanner',
            debugShowCheckedModeBanner: false,
            home: const QRHomePage(),
            theme: state.themeData,
          );
        },
      ),
    );
  }
}
