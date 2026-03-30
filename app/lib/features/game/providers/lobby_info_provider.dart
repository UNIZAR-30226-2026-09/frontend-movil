import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../models/jugador_partida_model.dart';

class LobbyInfoState {
  final int? partidaId;
  final String? creador;
  final List<JugadorPartidaModel> jugadoresEnSala;
  final String? codigoInvitacion;
  final int? maxPlayers;
  final String? visibility;

  const LobbyInfoState({
    this.partidaId,
    this.creador,
    this.jugadoresEnSala = const [],
    this.codigoInvitacion,
    this.maxPlayers,
    this.visibility,
  });

  LobbyInfoState copyWith({
    int? partidaId,
    Object? creador = _noChange,
    List<JugadorPartidaModel>? jugadoresEnSala,
    Object? codigoInvitacion = _noChange,
    int? maxPlayers,
    Object? visibility = _noChange,
  }) {
    return LobbyInfoState(
      partidaId: partidaId ?? this.partidaId,
      creador: creador == _noChange ? this.creador : creador as String?,
      jugadoresEnSala: jugadoresEnSala ?? this.jugadoresEnSala,
      codigoInvitacion: codigoInvitacion == _noChange
          ? this.codigoInvitacion
          : codigoInvitacion as String?,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      visibility:
          visibility == _noChange ? this.visibility : visibility as String?,
    );
  }
}

const _noChange = Object();

class LobbyInfoNotifier extends StateNotifier<LobbyInfoState> {
  LobbyInfoNotifier() : super(const LobbyInfoState());

  void setFromJoinResponse({
    required int partidaId,
    required String creador,
    required List<JugadorPartidaModel> jugadoresEnSala,
  }) {
    state = state.copyWith(
      partidaId: partidaId,
      creador: creador,
      jugadoresEnSala: jugadoresEnSala,
    );
  }

  void setFromCreatedMatch({
    required int partidaId,
    required String creador,
    required String codigoInvitacion,
    required int maxPlayers,
    required String visibility,
    required List<JugadorPartidaModel> jugadoresEnSala,
  }) {
    state = state.copyWith(
      partidaId: partidaId,
      creador: creador,
      codigoInvitacion: codigoInvitacion,
      maxPlayers: maxPlayers,
      visibility: visibility,
      jugadoresEnSala: jugadoresEnSala,
    );
  }

  void clear() {
    state = const LobbyInfoState();
  }
}

final lobbyInfoProvider =
    StateNotifierProvider<LobbyInfoNotifier, LobbyInfoState>(
  (ref) => LobbyInfoNotifier(),
);