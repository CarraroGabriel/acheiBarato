import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:achei_barato/services/api_service.dart';
import 'package:achei_barato/telas/notificacoes.dart';

class NotificacaoService {
  static final navegador = GlobalKey<NavigatorState>();
  static final mensageiro = GlobalKey<ScaffoldMessengerState>();

  static final naoLidas = ValueNotifier<int>(0);

  static bool _disponivel = false;
  static int? _idUsuario;
  static int? _idMercado;

  static Future<void> iniciar() async {
    try {
      await Firebase.initializeApp();
      FirebaseMessaging.onMessage.listen(_aoReceberComAppAberto);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => abrirTela());
      _disponivel = true;
    } catch (e) {
      // Sem Firebase (ex.: emulador sem Google Play) o app segue sem push.
      debugPrint('Firebase indisponível: $e');
    }
  }

  static Future<void> entrarComoUsuario(int idUsuario) async {
    _idUsuario = idUsuario;
    _idMercado = null;
    await atualizarContador();
    if (!await _prepararDispositivo()) return;

    try {
      final resposta = await ApiService.get('favoritos?id_usuario=$idUsuario');
      final dados = resposta['dados'] as Map? ?? {};

      final topicos = [
        for (final m in (dados['mercados'] as List? ?? []))
          'mercado_${(m as Map)['id_mercado']}',
        for (final p in (dados['produtos'] as List? ?? []))
          'item_${(p as Map)['id_item_produto']}',
      ];
      await Future.wait(topicos.map(_inscrever));
    } catch (e) {
      debugPrint('Falha ao inscrever nos favoritos: $e');
    }
  }

  static Future<void> entrarComoMercado(int idMercado) async {
    _idMercado = idMercado;
    _idUsuario = null;
    await atualizarContador();
    if (!await _prepararDispositivo()) return;
    await _inscrever('lojista_$idMercado');
  }

  static Future<void> seguirMercado(int idMercado, bool seguir) =>
      _alterarInscricao('mercado_$idMercado', seguir);

  static Future<void> seguirItem(int idItemProduto, bool seguir) =>
      _alterarInscricao('item_$idItemProduto', seguir);

  // Ao sair da conta: apagar o token cancela todas as inscrições do aparelho.
  static Future<void> sair() async {
    _idUsuario = null;
    _idMercado = null;
    naoLidas.value = 0;
    if (!_disponivel) return;
    try {
      await FirebaseMessaging.instance.deleteToken();
    } catch (_) {}
  }

  static Future<void> atualizarContador() async {
    final filtro = _filtro;
    if (filtro == null) return;
    try {
      final resposta = await ApiService.get('notificacoes/nao_lidas?$filtro');
      naoLidas.value = ((resposta['dados'] as Map)['nao_lidas'] as num).toInt();
    } catch (_) {}
  }

  static void abrirTela() {
    if (_idUsuario == null && _idMercado == null) return;
    navegador.currentState?.push(
      MaterialPageRoute(
        builder: (_) =>
            NotificacoesTela(idUsuario: _idUsuario, idMercado: _idMercado),
      ),
    );
  }

  static String? get _filtro {
    if (_idUsuario != null) return 'id_usuario=$_idUsuario';
    if (_idMercado != null) return 'id_mercado=$_idMercado';
    return null;
  }

  static Future<bool> _prepararDispositivo() async {
    if (!_disponivel) return false;
    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();
      await messaging.deleteToken();

      final inicial = await messaging.getInitialMessage();
      if (inicial != null) abrirTela();
      return true;
    } catch (e) {
      debugPrint('Falha ao preparar notificações: $e');
      return false;
    }
  }

  static Future<void> _alterarInscricao(String topico, bool seguir) async {
    if (!_disponivel) return;
    try {
      if (seguir) {
        await _inscrever(topico);
      } else {
        await FirebaseMessaging.instance.unsubscribeFromTopic(topico);
      }
    } catch (e) {
      debugPrint('Falha ao alterar inscrição em $topico: $e');
    }
  }

  static Future<void> _inscrever(String topico) =>
      FirebaseMessaging.instance.subscribeToTopic(topico);

  static void _aoReceberComAppAberto(RemoteMessage mensagem) {
    atualizarContador();
    final notificacao = mensagem.notification;
    if (notificacao == null) return;

    mensageiro.currentState?.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notificacao.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            if (notificacao.body != null) Text(notificacao.body!),
          ],
        ),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(label: 'Ver', onPressed: abrirTela),
      ),
    );
  }
}
