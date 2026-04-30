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

    for (final log in logs) {
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

    return groups;
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
    if (datos.isEmpty) return null;

    String? str(String key) {
      final value = datos[key];
      if (value == null) return null;
      final text = value.toString().trim();
      return text.isEmpty ? null : text;
    }

    String? boolText(String key) {
      final value = datos[key];
      if (value is bool) return value ? 'victoria' : 'derrota';
      if (value is String) {
        final normalized = value.toLowerCase();
        if (normalized == 'true' || normalized == 'si') return 'victoria';
        if (normalized == 'false' || normalized == 'no') return 'derrota';
      }
      return null;
    }

    final tipo = log.tipoEvento.toLowerCase();
    final actor = (log.user ?? '').trim();

    final origen = str('origen');
    final destino = str('destino');
    final defensor = str('defensor');
    final bajasAtacante = str('bajas_atacante');
    final bajasDefensor = str('bajas_defensor');
    final victoria = boolText('victoria');

    final conquistado = str('territorio_conquistado');
    final anterior = str('anterior_dueno');

    final tipoAtaque = str('tipo_ataque');

    final eliminado = str('eliminado');
    final ganador = str('ganador');
    final turnoDe = str('turno_de');

    if (tipo == 'cambio_turno') {
      if (turnoDe != null) {
        return 'Empieza el turno de ${_nombreUsuario(turnoDe)}.';
      }
      return 'Empieza un nuevo turno.';
    }

    if (tipo == 'ataque_convencional') {
      final destinoNombre = _nombreComarca(destino);
      final origenNombre = _nombreComarca(origen);
      final defensorNombre = _nombreUsuario(defensor);
      final partes = <String>[];
      if (destinoNombre != null && origenNombre != null) {
        partes.add('Atacó $destinoNombre desde $origenNombre');
      } else if (destinoNombre != null) {
        partes.add('Atacó $destinoNombre');
      }
      if (defensorNombre != null) {
        partes.add('y se encontró con la defensa de $defensorNombre.');
      }
      if (bajasAtacante != null || bajasDefensor != null) {
        final bajas = <String>[];
        if (bajasAtacante != null) {
          final label = bajasAtacante == '1' ? 'baja' : 'bajas';
          bajas.add('$bajasAtacante $label del atacante');
        }
        if (bajasDefensor != null) {
          final label = bajasDefensor == '1' ? 'baja' : 'bajas';
          bajas.add('$bajasDefensor $label del defensor');
        }
        partes.add('Hubo ${bajas.join(' y ')}');
      }
      if (victoria != null) {
        partes.add('y terminó en $victoria');
      }
      if (partes.isNotEmpty) return partes.join(' ');
    }

    if (tipo == 'conquista') {
      final territorioNombre = _nombreComarca(conquistado);
      final anteriorNombre = _nombreUsuario(anterior);
      final actorNombre = _nombreUsuario(actor);
      if (territorioNombre != null && anteriorNombre != null) {
        return '$actorNombre conquistó $territorioNombre y lo arrebató a $anteriorNombre.';
      }
      if (territorioNombre != null) {
        return '$actorNombre conquistó $territorioNombre.';
      }
    }

    if (tipo == 'ataque_especial') {
      final ataque = _nombreTipoAtaque(tipoAtaque);
      final destinoNombre = _nombreComarca(destino);
      final origenNombre = _nombreComarca(origen);
      if (ataque != null && destinoNombre != null && origenNombre != null) {
        return 'Lanza $ataque desde $origenNombre hacia $destinoNombre.';
      }
      if (ataque != null && destinoNombre != null) {
        return 'Lanza $ataque sobre $destinoNombre.';
      }
      if (ataque != null) {
        return 'Lanza $ataque.';
      }
    }

    if (tipo == 'jugador_eliminado') {
      if (eliminado != null) {
        return '${_nombreUsuario(eliminado)} queda fuera de la partida.';
      }
      return 'Un jugador queda fuera de la partida.';
    }

    if (tipo == 'fin_partida') {
      if (ganador != null) {
        return 'La partida termina y gana ${_nombreUsuario(ganador)}.';
      }
      return 'La partida termina.';
    }

    return _fraseGenericaDatos(datos);
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
