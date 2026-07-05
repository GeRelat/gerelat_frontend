import 'package:shared_preferences/shared_preferences.dart';

class ServicoToken {
  static const _chaveAccessToken = 'access_token';
  static const _chaveRefreshToken = 'refresh_token';

  String? _accessToken;
  String? _refreshToken;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  bool get estaAutenticado => _accessToken != null && _accessToken!.isNotEmpty;

  Future<void> carregar() async {
    final preferencias = await SharedPreferences.getInstance();
    _accessToken = preferencias.getString(_chaveAccessToken);
    _refreshToken = preferencias.getString(_chaveRefreshToken);
  }

  Future<void> salvar({
    required String accessToken,
    required String refreshToken,
  }) async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.setString(_chaveAccessToken, accessToken);
    await preferencias.setString(_chaveRefreshToken, refreshToken);

    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  Future<void> limpar() async {
    final preferencias = await SharedPreferences.getInstance();
    await preferencias.remove(_chaveAccessToken);
    await preferencias.remove(_chaveRefreshToken);

    _accessToken = null;
    _refreshToken = null;
  }
}
