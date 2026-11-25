import 'package:flutter/material.dart';
import 'package:achei_barato/widgets/editor_horarios.dart';

class HorarioFuncionamento extends StatelessWidget {
  final dynamic horarios;

  const HorarioFuncionamento({super.key, required this.horarios});

  @override
  Widget build(BuildContext context) {
    final porDia = EditorHorarios.lerDaApi(horarios);
    final hoje =
        DateTime.now().weekday % 7; // DateTime: 7 = domingo; banco: 0 = domingo
    final abertoAgora = EditorHorarios.estaAberto(porDia) ?? false;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule, color: Colors.red, size: 22),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Horário de funcionamento',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              if (porDia.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: abertoAgora
                        ? Colors.green.shade50
                        : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    abertoAgora ? 'Aberto agora' : 'Fechado agora',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: abertoAgora
                          ? Colors.green.shade700
                          : Colors.red.shade700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (porDia.isEmpty)
            Text(
              'Horário não informado pelo mercado.',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
            )
          else
            ...EditorHorarios.diasSemana.entries.map(
              (dia) => _buildLinhaDia(
                dia.value,
                porDia[dia.key] ?? [],
                dia.key == hoje,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLinhaDia(String nome, List<FaixaHorario> faixas, bool ehHoje) {
    final texto = faixas.isEmpty
        ? 'Fechado'
        : faixas
              .map(
                (f) =>
                    '${EditorHorarios.formatar(f.abertura)} – ${EditorHorarios.formatar(f.fechamento)}',
              )
              .join(', ');

    final estilo = TextStyle(
      fontSize: 14,
      height: 1.6,
      fontWeight: ehHoje ? FontWeight.bold : FontWeight.normal,
      color: ehHoje ? Colors.black87 : Colors.grey.shade700,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 80, child: Text(nome, style: estilo)),
        Expanded(child: Text(texto, style: estilo)),
      ],
    );
  }
}
