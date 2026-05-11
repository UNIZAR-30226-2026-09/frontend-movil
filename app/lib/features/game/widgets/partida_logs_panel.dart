import 'package:flutter/material.dart';

import '../../../app/theme/app_theme.dart';
import '../models/partida_log_model.dart';
import '../utils/partida_log_formatter.dart';

class PartidaLogsPanel extends StatelessWidget {
  final List<PartidaLogModel> logs;
  final bool isLoading;
  final String? error;
  final VoidCallback onRetry;
  final Color Function(String actor) colorResolver;
  final PartidaLogFormatter formatter;

  const PartidaLogsPanel({
    super.key,
    required this.logs,
    required this.isLoading,
    required this.error,
    required this.onRetry,
    required this.colorResolver,
    this.formatter = const PartidaLogFormatter(),
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && logs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppTheme.text),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (logs.isEmpty) {
      return const Center(
        child: Text(
          'No hay logs todavía.',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    final groups = formatter.groupLogs(logs);
    final participantColors = _participantColors(logs);

    return ListView.separated(
      itemCount: groups.length,
      separatorBuilder: (_, _) =>
          const Divider(height: 1, color: Color(0x338C6D3F)),
      itemBuilder: (context, index) {
        final group = groups[index];
        final chipStyle = TextStyle(
          color: AppTheme.textSecondary.withValues(alpha: 0.9),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        );

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1C1B23),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFF8C6D3F), width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.account_circle,
                        color: AppTheme.primary,
                        size: 22,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          group.actor,
                          style: TextStyle(
                            color: colorResolver(group.actor),
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _LogChip(
                        label: 'Turno ${group.turno}',
                        textStyle: chipStyle,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Column(
                    children: group.items.map((log) {
                      final subtitle = formatter.subtitle(log);

                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _iconoEvento(log.tipoEvento),
                              color: AppTheme.primary,
                              size: 18,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    formatter.title(log),
                                    style: const TextStyle(
                                      color: AppTheme.text,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  if (subtitle != 'Sin detalles adicionales.')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: _ColoredUserLogText(
                                        text: subtitle,
                                        participantColors: participantColors,
                                        baseStyle: const TextStyle(
                                          color: AppTheme.textSecondary,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              formatter.formatDate(log.timestamp),
                              style: TextStyle(
                                color: AppTheme.textSecondary.withValues(
                                  alpha: 0.7,
                                ),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Map<String, Color> _participantColors(List<PartidaLogModel> logs) {
    final names = <String>{};

    void addName(dynamic value) {
      if (value == null) return;
      if (value is List) {
        for (final item in value) {
          addName(item);
        }
        return;
      }
      final text = value.toString().trim();
      if (text.isEmpty || text.toLowerCase() == 'null') return;
      names.add(text);
    }

    const participantKeys = <String>{
      'user',
      'usuario',
      'jugador',
      'turno_de',
      'nuevo_turno',
      'primer_turno',
      'ganador',
      'eliminado',
      'jugador_eliminado',
      'por_quien',
      'atacante',
      'defensor',
      'eliminador',
      'anterior_dueno',
      'dueno_anterior',
      'jugadores',
      'participantes',
    };

    for (final log in logs) {
      addName(log.user);
      for (final entry in log.datos.entries) {
        if (participantKeys.contains(entry.key.toString())) {
          addName(entry.value);
        }
      }
    }

    return <String, Color>{for (final name in names) name: colorResolver(name)};
  }

  IconData _iconoEvento(String tipo) {
    final upper = tipo.toUpperCase();
    if (upper.contains('PAUSA')) return Icons.pause_circle_outline;
    if (upper.contains('ATAQUE')) return Icons.gavel_rounded;
    if (upper.contains('DEFENSA')) return Icons.shield_rounded;
    if (upper.contains('COMPRA') || upper.contains('TECNO')) {
      return Icons.science_rounded;
    }
    if (upper.contains('TURNO')) return Icons.hourglass_bottom_rounded;
    if (upper.contains('MOV')) return Icons.alt_route_rounded;
    return Icons.feed_rounded;
  }
}

class _ColoredUserLogText extends StatelessWidget {
  final String text;
  final Map<String, Color> participantColors;
  final TextStyle baseStyle;

  const _ColoredUserLogText({
    required this.text,
    required this.participantColors,
    required this.baseStyle,
  });

  @override
  Widget build(BuildContext context) {
    final participants =
        participantColors.keys
            .where((name) => name.trim().isNotEmpty && name != 'Sistema')
            .toList(growable: false)
          ..sort((a, b) => b.length.compareTo(a.length));

    if (participants.isEmpty ||
        !participants.any((name) => text.contains(name))) {
      return Text(text, style: baseStyle);
    }

    final spans = <TextSpan>[];
    var start = 0;
    while (start < text.length) {
      var nextIndex = -1;
      String? nextParticipant;

      for (final participant in participants) {
        final index = text.indexOf(participant, start);
        if (index < 0) continue;
        if (nextIndex == -1 ||
            index < nextIndex ||
            (index == nextIndex &&
                participant.length > (nextParticipant?.length ?? 0))) {
          nextIndex = index;
          nextParticipant = participant;
        }
      }

      if (nextIndex < 0 || nextParticipant == null) {
        if (start < text.length) {
          spans.add(TextSpan(text: text.substring(start)));
        }
        break;
      }

      if (nextIndex > start) {
        spans.add(TextSpan(text: text.substring(start, nextIndex)));
      }

      spans.add(
        TextSpan(
          text: nextParticipant,
          style: baseStyle.copyWith(
            color: participantColors[nextParticipant],
            fontWeight: FontWeight.w800,
          ),
        ),
      );
      start = nextIndex + nextParticipant.length;
    }

    return RichText(
      text: TextSpan(style: baseStyle, children: spans),
    );
  }
}

class _LogChip extends StatelessWidget {
  final String label;
  final TextStyle textStyle;

  const _LogChip({required this.label, required this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF262531),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF8C6D3F), width: 0.8),
      ),
      child: Text(label, style: textStyle),
    );
  }
}
