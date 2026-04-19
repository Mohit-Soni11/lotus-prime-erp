import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart'; // 🚀 ADDED FOR WINDOWS SQLITE

import 'firebase_options.dart';
import 'theme/dashboard/app/uv.dart';

// ✅ CORRECTED IMPORTS (Path fix: 'seeds' -> 'db')
import 'package:lotus_erp/database/db/app_database.dart';
import 'package:lotus_erp/database/seeds/database_seeder.dart';

// ✅ SCREENS IMPORT
import 'ui/auth/login_screen.dart';
import 'ui/layout/main_layout_wrapper.dart';

void main() async {
  // 1. Ensure Flutter bindings are ready
  WidgetsFlutterBinding.ensureInitialized();

  // 🚀 CRITICAL FIX: Initialize SQLite FFI for Desktop (Windows/Linux)
  if (Platform.isWindows || Platform.isLinux) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  
  // 2. Start Firebase Engine
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 3. Initialize Local Database (Singleton Instance)
  final database = AppDatabase();

  // 4. Run Intelligent Seeder (Dummy Data Logic)
  try {
    final seeder = DatabaseSeeder(database);
    await seeder.seed();
    debugPrint("✅ Database Seeding Process Completed.");
  } catch (e) {
    debugPrint("❌ Seeding Error: $e");
  }

  runApp(const LotusERPApp());
}

class LotusERPApp extends StatelessWidget {
  const LotusERPApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LOTUS ERP',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: UV.colors.bgPrimary,
        useMaterial3: true,
        fontFamily: 'Inter',
      ),
      // 🔥 GATEKEEPER (Ye Logout ko handle karega)
      home: const AuthGate(), 
    );
  }
}

// 🚪 THE GATEKEEPER (Smart Connection)
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(), 
      builder: (context, snapshot) {
        
        // 1. Connection check (Loading...)
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Colors.white)),
          );
        }

        // 2. ✅ GATE OPEN (User Login Hai -> Dashboard jao)
        if (snapshot.hasData) {
          return const MainLayoutWrapper(); 
        }

        // 3. ❌ GATE CLOSED (User Login Nahi Hai -> Login Screen jao)
        // (Jab TopBar se Logout daboge, to app yahan wapas aayega)
        return const LoginScreen();
      },
    );
  }
}