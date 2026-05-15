import 'package:flutter/material.dart';
import 'package:gerelat_frontend/nucleo/temas/cores.dart';
import 'package:gerelat_frontend/nucleo/temas/tipografia.dart';

/// Campo de busca do dashboard.
class BarraPesquisa extends StatelessWidget {
  final TextEditingController? controlador;
  final ValueChanged<String>? onChanged;

  const BarraPesquisa({super.key, this.controlador, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 256,
      height: 40,
      child: TextField(
        controller: controlador,
        onChanged: onChanged,
        style: Tipografia.bodyMedium.copyWith(color: Cores.pretoProfundo),
        decoration: InputDecoration(
          hintText: 'Pesquisar...',
          hintStyle: Tipografia.bodyMedium.copyWith(color: Cores.cinzaMedio),
          prefixIcon: const Icon(
            Icons.search_outlined,
            color: Cores.cinzaMedio,
            size: 18,
          ),
          filled: true,
          fillColor: Cores.cinzaClaro,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Cores.azulPrimario, width: 1.5),
          ),
        ),
      ),
    );
  }
}
