import '../models/partida_log_model.dart';

class PartidaLogFormatter {
  const PartidaLogFormatter();

  String formatDate(DateTime? timestamp) {
    if (timestamp == null) return '--';

    String two(int value) => value.toString().padLeft(2, '0');

    return '${two(timestamp.day)}/${two(timestamp.month)} '
        '${two(timestamp.hour)}:${two(timestamp.minute)}';
  }

  String title(PartidaLogModel log) {
    final tipo = log.tipoEvento.trim().toLowerCase();
    if (tipo == 'territorio_actualizado') return 'Trabajar';
    return _humanizarEvento(log.tipoEvento);
  }

  String subtitle(PartidaLogModel log) {
    final natural = _fraseNaturalDatos(log);
    if (natural != null && natural.trim().isNotEmpty) {
      return natural;
    }

    return 'Sin detalles adicionales.';
  }

  List<PartidaLogGroup> groupLogs(List<PartidaLogModel> logs) {
    final groups = <PartidaLogGroup>[];
    PartidaLogGroup? current;
    final sortedLogs =
        logs
            .where((log) => !_isRedundantRefuerzoPhase(log))
            .toList(growable: false)
          ..sort(_compareLogsGlobal);

    for (final log in sortedLogs) {
      final actor = (log.user ?? '').trim().isEmpty
          ? 'Sistema'
          : log.user!.trim();
      final isNewTurn = current == null || log.turnoNumero != current.turno;
      final isNewActor = current == null || actor != current.actor;

      if (current == null || isNewTurn || isNewActor) {
        current = PartidaLogGroup(actor: actor, turno: log.turnoNumero);
        groups.add(current);
      }

      current.items.add(log);
    }

    for (final group in groups) {
      group.items.sort(_compareStableOrder);
    }

    return groups;
  }

  int _compareLogsGlobal(PartidaLogModel a, PartidaLogModel b) {
    final stableComparison = _compareStableOrder(a, b);
    if (stableComparison != 0) return stableComparison;
    return -a.turnoNumero.compareTo(b.turnoNumero);
  }

  int _compareStableOrder(PartidaLogModel a, PartidaLogModel b) {
    final timeA = a.timestamp;
    final timeB = b.timestamp;
    if (timeA != null && timeB != null) return -timeA.compareTo(timeB);
    return -a.id.compareTo(b.id);
  }

  bool _isRedundantRefuerzoPhase(PartidaLogModel log) {
    final tipo = log.tipoEvento.trim().toLowerCase();
    if (tipo != 'cambio_fase' && tipo != 'cambio_turno') return false;

    final fase = _readDato(log.datos, const <String>[
      'fase_nueva',
      'fase',
    ])?.toLowerCase();
    if (fase != 'refuerzo') return false;

    final turnoDe = _readDato(log.datos, const <String>[
      'turno_de',
      'nuevo_turno',
    ]);
    final tropasRecibidas = _readDato(log.datos, const <String>[
      'tropas_recibidas',
      'refuerzos',
    ]);

    return turnoDe == null || tropasRecibidas == null;
  }

  String _humanizarEvento(String raw) {
    final normal = raw.replaceAll('_', ' ').toLowerCase();
    if (normal.isEmpty) return 'Evento de partida';

    final words = normal.split(' ');
    final capitalized = words
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
    return capitalized;
  }

  String? _fraseNaturalDatos(PartidaLogModel log) {
    final datos = log.datos;

    String? str(List<String> keys) {
      return _readDato(datos, keys);
    }

    String textOr(String? value, String fallback) {
      final text = value?.trim();
      return text == null || text.isEmpty ? fallback : text;
    }

    final tipo = log.tipoEvento.trim().toLowerCase();
    final actor = _nombreUsuario(
      str(const <String>['user', 'usuario', 'jugador']) ?? log.user,
    );

    final jugadores = str(const <String>['jugadores', 'participantes']);
    final primerTurno = str(const <String>['primer_turno', 'turno_de']);

    final ganador = str(const <String>['ganador']);
    final eliminado = str(const <String>['eliminado', 'jugador_eliminado']);
    final porQuien = str(const <String>['por_quien', 'atacante', 'eliminador']);

    final origen = str(const <String>[
      'origen',
      'territorio_origen',
      'territorio_origen_id',
    ]);
    final destino = str(const <String>[
      'destino',
      'territorio_destino',
      'territorio_destino_id',
      'objetivo',
    ]);
    final bajasAtacante = str(const <String>['bajas_atacante']);
    final bajasDefensor = str(const <String>['bajas_defensor']);

    final conquistado = str(const <String>[
      'territorio_conquistado',
      'conquistado',
      'territorio',
    ]);
    final anterior = str(const <String>['anterior_dueno', 'dueno_anterior']);

    final tropas = str(const <String>['tropas', 'cantidad']);
    final territorio = str(const <String>[
      'territorio',
      'comarca',
      'territorio_id',
      'territorio_trabajado',
    ]);
    final cantidad = str(const <String>['cantidad', 'tropas']);

    final turnoDe = str(const <String>['turno_de', 'nuevo_turno']);
    final tropasRecibidas = str(const <String>[
      'tropas_recibidas',
      'refuerzos',
    ]);
    final faseNueva = str(const <String>['fase_nueva', 'fase']);

    final tecnologia = str(const <String>[
      'tecnologia',
      'tecnologia_id',
      'habilidad_id',
      'habilidad',
    ]);
    final precio = str(const <String>['precio', 'coste', 'costo']);
    final tipoAtaque = str(const <String>[
      'tipo_ataque',
      'ataque_id',
      'ataque',
      'habilidad_id',
    ]);

    if (tipo == 'partida_iniciada') {
      return 'La Guerra por la Soberanía ha comenzado. Participantes: ${textOr(_listaTexto(datos['jugadores']) ?? jugadores, 'los jugadores')}. Las fuerzas de ${_nombreUsuario(primerTurno)} toman la iniciativa.';
    }

    if (tipo == 'partida_finalizada' || tipo == 'fin_partida') {
      return '¡Conflicto concluido! ${_nombreUsuario(ganador)} ha sometido al resto de facciones y reclama el control absoluto.';
    }

    if (tipo == 'jugador_eliminado') {
      if (porQuien == null) {
        return '¡Caída de un imperio! Las defensas de ${_nombreUsuario(eliminado)} han colapsado por desgaste.';
      }
      return '¡Caída de un imperio! Las defensas de ${_nombreUsuario(eliminado)} han colapsado a manos de ${_nombreUsuario(porQuien)}.';
    }

    if (tipo == 'abandonar_partida') {
      return '${_nombreUsuario(str(const <String>['usuario']) ?? actor)} ha desertado antes de que comience el conflicto.';
    }

    if (tipo == 'ataque_resultado' || tipo == 'ataque_convencional') {
      return '$actor lanza una ofensiva desde ${_nombreComarca(origen) ?? 'origen desconocido'} hacia ${_nombreComarca(destino) ?? 'destino desconocido'}. Causa ${textOr(bajasDefensor, '0')} bajas, sufriendo ${textOr(bajasAtacante, '0')} pérdidas.';
    }

    if (tipo == 'conquista') {
      return '¡Victoria decisiva! Las tropas de $actor han ocupado ${_nombreComarca(conquistado) ?? 'el territorio conquistado'}, expulsando a las fuerzas de ${_nombreUsuario(anterior)}.';
    }

    if (tipo == 'movimiento_conquista' ||
        tipo == 'mover_conquista' ||
        tipo == 'fortificacion' ||
        tipo == 'fortificación' ||
        tipo == 'fortificar') {
      return '$actor redespliega tácticamente ${textOr(tropas, '0')} batallones desde ${_nombreComarca(origen) ?? 'origen desconocido'} hacia ${_nombreComarca(destino) ?? 'destino desconocido'}.';
    }

    if (tipo == 'tropas_colocadas' || tipo == 'colocar_tropas') {
      return '$actor ha reforzado el frente en ${_nombreComarca(territorio) ?? 'territorio desconocido'} desplegando ${textOr(cantidad, '0')} nuevas divisiones.';
    }

    if (tipo == 'cambio_fase' || tipo == 'cambio_turno') {
      if (turnoDe != null && tropasRecibidas != null) {
        return 'Alto mando: Inicia el turno de ${_nombreUsuario(turnoDe)}. Se movilizan $tropasRecibidas brigadas de refuerzo.';
      }
      return '$actor avanza su campaña: las fuerzas entran en fase de ${textOr(faseNueva, log.fase)}.';
    }

    if (tipo == 'trabajar' || tipo == 'territorio_actualizado') {
      return '$actor ha movilizado a la población de ${_nombreComarca(territorio) ?? 'territorio desconocido'} para acelerar la producción de recursos.';
    }

    if (tipo == 'investigar') {
      return '$actor ha ordenado a las instalaciones de ${_nombreComarca(territorio) ?? 'territorio desconocido'} iniciar un desarrollo confidencial.';
    }

    if (tipo == 'comprar_tecnologia') {
      return "$actor ha financiado la tecnología militar '${_nombreTipoAtaque(tecnologia) ?? 'desconocida'}' por un coste de ${textOr(precio, '0')} de oro.";
    }

    if (tipo == 'ataque_especial') {
      return "¡Lanzamiento táctico! $actor ejecuta la operación '${_nombreTipoAtaque(tipoAtaque) ?? 'desconocida'}' con objetivo en ${_nombreComarca(destino) ?? 'destino desconocido'}.";
    }

    if (datos.isEmpty) return null;
    return _fraseGenericaDatos(datos);
  }

  String? _readDato(Map<String, dynamic> datos, List<String> keys) {
    for (final key in keys) {
      final value = datos[key];
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty && text.toLowerCase() != 'null') return text;
    }
    return null;
  }

  String _fraseGenericaDatos(Map<String, dynamic> datos) {
    final entries = datos.entries
        .where((entry) {
          final key = entry.key.toString().toLowerCase();
          if (key.contains('turno_de')) return false;
          return true;
        })
        .toList(growable: false);

    if (entries.isEmpty) return 'Sin detalles adicionales.';

    final fragments = entries
        .map((entry) {
          final keyLabel = _humanizarClave(entry.key.toString());
          final valueLabel = _humanizarValor(entry.value);
          if (valueLabel.isEmpty) return keyLabel;
          return '$keyLabel $valueLabel';
        })
        .where((fragment) => fragment.trim().isNotEmpty)
        .toList(growable: false);

    if (fragments.isEmpty) return 'Sin detalles adicionales.';
    return 'Ocurrió lo siguiente: ${fragments.join(', ')}.';
  }

  String _humanizarClave(String raw) {
    final normalized = raw.replaceAll('_', ' ').trim();
    if (normalized.isEmpty) return 'Detalle';
    return _titleCase(normalized);
  }

  String _humanizarValor(dynamic value) {
    if (value == null) return '';
    if (value is bool) return value ? 'sí' : 'no';
    final text = value.toString().trim();
    if (text.isEmpty) return '';

    final looksLikeComarca = text.contains('_');
    if (looksLikeComarca) {
      return _titleCase(text.replaceAll('_', ' '));
    }
    return text;
  }

  String? _listaTexto(dynamic value) {
    if (value is List) {
      final items = value
          .map((item) => item.toString().trim())
          .where((item) => item.isNotEmpty)
          .toList(growable: false);
      if (items.isEmpty) return null;
      return items.join(', ');
    }
    return null;
  }

  String? _nombreComarca(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    return _titleCase(cleaned.replaceAll('_', ' '));
  }

  String _nombreUsuario(String? raw) {
    if (raw == null) return 'Jugador';
    final cleaned = raw.trim();
    return cleaned.isEmpty ? 'Jugador' : cleaned;
  }

  String? _nombreTipoAtaque(String? raw) {
    if (raw == null) return null;
    final cleaned = raw.trim();
    if (cleaned.isEmpty) return null;
    return _titleCase(cleaned.replaceAll('_', ' '));
  }

  String _titleCase(String input) {
    final parts = input.split(' ');
    return parts
        .map((part) {
          if (part.isEmpty) return part;
          final lower = part.toLowerCase();
          return '${lower[0].toUpperCase()}${lower.substring(1)}';
        })
        .join(' ');
  }
}

class PartidaLogGroup {
  final String actor;
  final int turno;
  final List<PartidaLogModel> items = <PartidaLogModel>[];

  PartidaLogGroup({required this.actor, required this.turno});
}
