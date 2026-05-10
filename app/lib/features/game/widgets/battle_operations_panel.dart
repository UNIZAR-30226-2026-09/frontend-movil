import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import 'battle_operations_card.dart';

class BattleOperationsPanel extends StatelessWidget {
  const BattleOperationsPanel({
    super.key,
    required this.onQuickMatch,
    required this.onCreateMatch,
    required this.onJoinMatch,
  });

  final VoidCallback onQuickMatch;
  final VoidCallback onCreateMatch;
  final VoidCallback onJoinMatch;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 980),
        child: Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(64, 32, 28, 28),
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
          decoration: BoxDecoration(
            color: AppTheme.surface.withValues(alpha: 0.94),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.borderGold,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.42),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'OPERACIONES',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppTheme.borderGold,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Times New Roman',
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 18),
              Container(
                height: 1,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppTheme.borderBronze.withValues(alpha: 0.45),
                      AppTheme.borderGoldVivo.withValues(alpha: 0.65),
                      AppTheme.borderGoldVivo.withValues(alpha: 0.65),
                      AppTheme.borderBronze.withValues(alpha: 0.45),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.10, 0.34, 0.66, 0.90, 1],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: BattleOperationCard(
                      title: 'Partida rápida',
                      description:
                          'Busca una sala pública disponible.',
                      buttonText: 'Iniciar',
                      onPressed: onQuickMatch,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BattleOperationCard(
                      title: 'Crear partida',
                      description:
                          'Establece una nueva sala con tu configuración y genera un código para tus contrincantes.',
                      buttonText: 'Fundar',
                      onPressed: onCreateMatch,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: BattleOperationCard(
                      title: 'Unirse a partida',
                      description:
                          'Introduce un código de invitación o visita tus partidas pausadas.',
                      buttonText: 'Infiltrarse',
                      onPressed: onJoinMatch,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}