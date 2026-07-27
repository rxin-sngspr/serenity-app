import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/app_theme.dart';

final onboardedProvider = StateProvider<bool>((ref) => false);
final themeModeProvider = StateProvider<AppTheme>((ref) => AppTheme.rose);
final brightnessProvider = StateProvider<Brightness>((ref) => Brightness.dark);
