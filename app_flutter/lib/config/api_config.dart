class ApiConfig {
  static const String baseUrl =
      'http://200.19.1.19/20232GR.ADS0011/acheibarato/public/index.php';

  static String urlArquivo(String caminho) {
    if (caminho.startsWith('http')) return caminho;
    return '${baseUrl.replaceFirst('/index.php', '')}/$caminho';
  }
}
