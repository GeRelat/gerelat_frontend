import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _carregando = false;
  String? _mensagemErro;

  bool get carregando => _carregando;
  String? get mensagemErro => _mensagemErro;

  void iniciarCarregamento() {
    _carregando = true;
    _mensagemErro = null;
    notifyListeners();
  }

  void finalizarCarregamento() {
    _carregando = false;
    notifyListeners();
  }

  void definirErro(Object erro) {
    _mensagemErro = erro.toString();
    _carregando = false;
    notifyListeners();
  }
}
