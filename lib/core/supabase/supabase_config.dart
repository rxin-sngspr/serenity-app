import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static String get url => dotenv.env['SUPABASE_URL'] ?? '';

  static String get publishableKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, publishableKey: publishableKey);
  }
}
