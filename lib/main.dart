import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/app.dart';
import 'core/config/env_config.dart';

void main() async {
  // Initialize Flutter bindings
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize environment configuration
  // Default to development, can be overridden with flavor
  await EnvConfig.init(environment: 'development');

  // TODO: Initialize services
  // - Firebase (optional)
  // - Local storage (Isar)
  // - Logger
  // - Analytics

  runApp(
    // Wrap dengan ProviderScope untuk Riverpod
    const ProviderScope(
      child: MomoApp(),
    ),
  );
}
