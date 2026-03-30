import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/api/dio_provider.dart';
import '../models/partida_publica_model.dart';
import '../services/matchmaking_service.dart';
import '../models/respuesta_unirse_partida.dart';

final matchmakingServiceProvider = Provider<MatchmakingService>((ref) {
  final dio = ref.read(dioProvider);
  return MatchmakingService(dio);
});

class MatchmakingState {
  final bool isLoading;
  final List<PublicMatchModel> matches;
  final String? errorMessage;
  final bool isJoining;
  final bool isCreating;
  final bool isLeaving;

  const MatchmakingState({
    required this.isLoading,
    required this.matches,
    this.errorMessage,
    required this.isJoining,
    required this.isCreating,
    required this.isLeaving,
  });

  MatchmakingState copyWith({
    bool? isLoading,
    List<PublicMatchModel>? matches,
    Object? errorMessage = _noChange,
    bool? isJoining,
    bool? isCreating,
    bool? isLeaving,
  }) {
    return MatchmakingState(
      isLoading: isLoading ?? this.isLoading,
      matches: matches ?? this.matches,
      errorMessage: errorMessage == _noChange
          ? this.errorMessage
          : errorMessage as String?,
      isJoining: isJoining ?? this.isJoining,
      isCreating: isCreating ?? this.isCreating,
      isLeaving: isLeaving ?? this.isLeaving,
    );
  }
}

const _noChange = Object();

class MatchmakingNotifier extends StateNotifier<MatchmakingState> {
  final MatchmakingService matchmakingService;

  MatchmakingNotifier({
    required this.matchmakingService,
  }) : super(
          const MatchmakingState(
            isLoading: false,
            matches: [],
            errorMessage: null,
            isJoining: false,
            isCreating: false,
            isLeaving: false,
          ),
        );

  Future<void> loadMatches() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
    );

    try {
      final matches = await matchmakingService.getPublicMatches();
      state = state.copyWith(
        isLoading: false,
        matches: matches,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error al cargar las partidas públicas',
      );
    }
  }

  Future<void> refreshMatches() async {
    try {
      final matches = await matchmakingService.getPublicMatches();
      state = state.copyWith(
        matches: matches,
        errorMessage: null,
      );
    } catch (_) {
      state = state.copyWith(
        errorMessage: 'Error al actualizar las partidas públicas',
      );
    }
  }

  Future<RespuestaUnirsePartida?> joinMatch(String codigo) async {
    state = state.copyWith(
      isJoining: true,
      errorMessage: null,
    );

    try {
      final joinResponse = await matchmakingService.joinMatchByCode(codigo);
      state = state.copyWith(
        isJoining: false,
        errorMessage: null,
      );
      return joinResponse;
    } catch (_) {
      state = state.copyWith(
        isJoining: false,
        errorMessage: 'Error al unirse a la partida',
      );
      return null;
    }
  }

  Future<PublicMatchModel?> createMatch({
    required int maxPlayers,
    required String visibility,
    required int timerSeconds,
  }) async {
    state = state.copyWith(
      isCreating: true,
      errorMessage: null,
    );

    try {
      final match = await matchmakingService.createMatch(
        maxPlayers: maxPlayers,
        visibility: visibility,
        timerSeconds: timerSeconds,
      );

      state = state.copyWith(
        isCreating: false,
        errorMessage: null,
      );

      return match;
    } catch (_) {
      state = state.copyWith(
        isCreating: false,
        errorMessage: 'Error al crear la partida',
      );
      return null;
    }
  }

  Future<bool> leaveMatch(int partidaId) async {
    state = state.copyWith(
      isLeaving: true,
      errorMessage: null,
    );
  
    try {
      await matchmakingService.leaveMatch(partidaId);
  
      state = state.copyWith(
        isLeaving: false,
        errorMessage: null,
      );
  
      return true;
    } catch (_) {
      state = state.copyWith(
        isLeaving: false,
        errorMessage: 'No se pudo abandonar la partida',
      );
      return false;
    }
  }
}



final matchmakingProvider =
    StateNotifierProvider<MatchmakingNotifier, MatchmakingState>((ref) {
  final matchmakingService = ref.read(matchmakingServiceProvider);
  return MatchmakingNotifier(matchmakingService: matchmakingService);
});