import 'package:flutter/foundation.dart';

abstract class BaseViewModel extends ChangeNotifier {
  bool _carregando = false;
  String? _mensagemErro;
  bool _descartado = false;

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

  // Um `await` pendente (ex.: salvar/excluir) pode resolver depois que a tela
  // que criou este ViewModel já foi fechada e chamou `dispose()`. Sem essa
  // guarda, o `notifyListeners()` disparado por esse retorno tardio lança
  // "A ChangeNotifier was used after being disposed" e derruba o app.
  @override
  void dispose() {
    _descartado = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (_descartado) return;
    super.notifyListeners();
  }
}
