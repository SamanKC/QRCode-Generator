import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

enum AppTheme {
  light,
  dark,
}

class ThemeCubit extends Cubit<AppTheme> {
  ThemeCubit() : super(AppTheme.dark);

  void toggleTheme() {
    if (state == AppTheme.light) {
      emit(AppTheme.dark);
    } else {
      emit(AppTheme.light);
    }
  }
}

ThemeData getThemeData(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return ThemeData.light().copyWith();
    case AppTheme.dark:
      return ThemeData.dark().copyWith();
  }
}

String getThemeName(AppTheme theme) {
  switch (theme) {
    case AppTheme.light:
      return 'Light Theme';
    case AppTheme.dark:
      return 'Dark Theme';
  }
}
