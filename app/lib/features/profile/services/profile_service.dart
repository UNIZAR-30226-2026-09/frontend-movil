import 'package:dio/dio.dart';

import '../models/avatar_option_model.dart';

class ProfileService {
  final Dio dio;

  ProfileService(this.dio);

  static const String _updateProfilePath = '/usuarios/me';
  static const String _updateAvatarPath = '/usuarios/me/avatar';
  static const String _avatarOptionsPath = '/usuarios/opciones';

  Future<void> updateProfile({String? email, String? password}) async {
    final data = <String, dynamic>{};

    if (email != null && email.trim().isNotEmpty) {
      data['email'] = email.trim();
    }

    if (password != null && password.trim().isNotEmpty) {
      data['password'] = password.trim();
    }

    if (data.isEmpty) {
      throw Exception('No hay datos para actualizar');
    }

    await dio.put(_updateProfilePath, data: data);
  }

  Future<void> updateAvatar({required String avatarName}) async {
    final normalized = avatarName.trim();
    if (normalized.isEmpty) {
      throw Exception('No hay avatar para actualizar');
    }

    await dio.put(_updateAvatarPath, data: {'avatar_name': normalized});
  }

  Future<List<AvatarOptionModel>> fetchAvatarOptions() async {
    final response = await dio.get(_avatarOptionsPath);
    return _parseAvatarOptions(response.data);
  }

  List<AvatarOptionModel> _parseAvatarOptions(dynamic raw) {
    final parsed = <AvatarOptionModel>[];

    void addParsed(dynamic value) {
      final option = _parseAvatarOption(value);
      if (option == null) return;
      final exists = parsed.any(
        (item) =>
            item.avatarName.toLowerCase() == option.avatarName.toLowerCase(),
      );
      if (!exists) {
        parsed.add(option);
      }
    }

    if (raw is List) {
      for (final item in raw) {
        addParsed(item);
      }
      return parsed;
    }

    if (raw is! Map) return parsed;

    final root = Map<String, dynamic>.from(raw);
    final nestedList = _extractAvatarListFromMap(root);
    if (nestedList != null) {
      for (final item in nestedList) {
        addParsed(item);
      }
      return parsed;
    }

    final looksLikeNamePathMap = root.entries.every(
      (entry) => entry.value is String || entry.value == null,
    );
    if (looksLikeNamePathMap) {
      for (final entry in root.entries) {
        final avatarName = entry.key.trim();
        if (avatarName.isEmpty) continue;
        final previewUrl = entry.value?.toString();
        parsed.add(
          AvatarOptionModel(avatarName: avatarName, previewUrl: previewUrl),
        );
      }
      return parsed;
    }

    addParsed(root);
    return parsed;
  }

  List<dynamic>? _extractAvatarListFromMap(Map<String, dynamic> map) {
    const keys = <String>[
      'avatars',
      'opciones',
      'avatar_options',
      'available_avatars',
      'items',
      'data',
      'results',
    ];

    for (final key in keys) {
      final value = map[key];
      if (value is List) {
        return value;
      }
      if (value is Map) {
        final nested = _extractAvatarListFromMap(
          Map<String, dynamic>.from(value),
        );
        if (nested != null) return nested;
      }
    }

    return null;
  }

  AvatarOptionModel? _parseAvatarOption(dynamic raw) {
    if (raw is String) {
      final normalized = raw.trim();
      if (normalized.isEmpty) return null;

      final looksLikePath =
          normalized.startsWith('http://') ||
          normalized.startsWith('https://') ||
          normalized.contains('/') ||
          normalized.contains('.');
      final avatarName = looksLikePath
          ? _extractAvatarNameFromRaw(normalized)
          : normalized;
      if (avatarName.isEmpty) return null;

      return AvatarOptionModel(
        avatarName: avatarName,
        previewUrl: looksLikePath ? normalized : null,
      );
    }

    if (raw is! Map) return null;

    final map = Map<String, dynamic>.from(raw);
    final avatarName =
        map['avatar_name']?.toString().trim() ??
        map['name']?.toString().trim() ??
        map['id']?.toString().trim() ??
        map['slug']?.toString().trim() ??
        map['code']?.toString().trim() ??
        '';
    final previewUrl =
        map['preview_url']?.toString().trim() ??
        map['image_url']?.toString().trim() ??
        map['avatar_url']?.toString().trim() ??
        map['url']?.toString().trim() ??
        map['path']?.toString().trim() ??
        map['image']?.toString().trim() ??
        map['avatar']?.toString().trim() ??
        '';

    final normalizedName = avatarName.isNotEmpty
        ? avatarName
        : _extractAvatarNameFromRaw(previewUrl);
    if (normalizedName.isEmpty) return null;

    return AvatarOptionModel(
      avatarName: normalizedName,
      previewUrl: previewUrl.isNotEmpty ? previewUrl : null,
    );
  }

  String _extractAvatarNameFromRaw(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty) return '';

    final withoutQuery = normalized.split('?').first;
    final segments = withoutQuery
        .split('/')
        .where((segment) => segment.isNotEmpty)
        .toList(growable: false);
    final fileName = segments.isEmpty ? withoutQuery : segments.last;

    return fileName;
  }

  String extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        final message = data['message'];

        if (detail is String) return detail;
        if (message is String) return message;

        if (detail is List && detail.isNotEmpty) {
          final first = detail.first;
          if (first is Map<String, dynamic> && first['msg'] != null) {
            return first['msg'].toString();
          }
          return detail.toString();
        }
      }

      if (data != null) return data.toString();
      if (error.message != null && error.message!.trim().isNotEmpty) {
        return error.message!;
      }
    }

    return 'Ha ocurrido un error inesperado';
  }
}
