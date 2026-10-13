import 'package:achei_barato/services/notificacao_service.dart';
import 'package:achei_barato/telas/login.dart';
import 'package:flutter/material.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificacaoService.iniciar();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Mercado',
      debugShowCheckedModeBanner: false,
      navigatorKey: NotificacaoService.navegador,
      scaffoldMessengerKey: NotificacaoService.mensageiro,
      home: const Login(),
    );
  }
}
