import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';

import '../../../shared/api/dio_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/profile_service.dart';

final profileServiceProvider = Provider<ProfileService>((ref) {
  final dio = ref.read(dioProvider);
  return ProfileService(dio);
});

enum ProfileActionStatus { idle, loading, success, error }

class ProfileState {
  final ProfileActionStatus status;
  final String? message;

  const ProfileState({required this.status, this.message});

  const ProfileState.initial()
    : status = ProfileActionStatus.idle,
      message = null;

  ProfileState copyWith({
    ProfileActionStatus? status,
    Object? message = _noChange,
  }) {
    return ProfileState(
      status: status ?? this.status,
      message: message == _noChange ? this.message : message as String?,
    );
  }
}

const _noChange = Object();

class ProfileNotifier extends StateNotifier<ProfileState> {
  final Ref ref;
  final ProfileService profileService;

  ProfileNotifier({required this.ref, required this.profileService})
    : super(const ProfileState.initial());

  Future<bool> updateProfile({
    String? email,
    String? password,
    String? avatarName,
  }) async {
    state = state.copyWith(status: ProfileActionStatus.loading, message: null);

    try {
      final hasProfilePayload =
          (email != null && email.trim().isNotEmpty) ||
          (password != null && password.trim().isNotEmpty);
      final hasAvatarPayload =
          avatarName != null && avatarName.trim().isNotEmpty;

      if (!hasProfilePayload && !hasAvatarPayload) {
        throw Exception('No hay datos para actualizar');
      }

      if (hasProfilePayload) {
        await profileService.updateProfile(email: email, password: password);
      }

      if (hasAvatarPayload) {
        await profileService.updateAvatar(avatarName: avatarName!.trim());
      }

      await ref.read(authProvider.notifier).checkSession();

      state = state.copyWith(
        status: ProfileActionStatus.success,
        message: 'Perfil actualizado correctamente',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        status: ProfileActionStatus.error,
        message: profileService.extractErrorMessage(e),
      );
      return false;
    }
  }

  void clearFeedback() {
    state = state.copyWith(status: ProfileActionStatus.idle, message: null);
  }
}

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((
  ref,
) {
  final profileService = ref.read(profileServiceProvider);
  return ProfileNotifier(ref: ref, profileService: profileService);
});
