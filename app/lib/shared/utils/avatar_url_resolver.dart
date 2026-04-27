import 'package:flutter_dotenv/flutter_dotenv.dart';

String? resolveAvatarUrl(String? rawAvatar) {
  final avatar = rawAvatar?.trim() ?? '';
  if (avatar.isEmpty) return null;

  if (avatar.startsWith('http://') || avatar.startsWith('https://')) {
    return avatar;
  }

  final apiBaseUrl = dotenv.env['API_BASE_URL']?.trim() ?? '';
  if (apiBaseUrl.isEmpty) return avatar;

  final apiUri = Uri.tryParse(apiBaseUrl);
  if (apiUri == null || apiUri.authority.isEmpty) return avatar;

  final origin = '${apiUri.scheme}://${apiUri.authority}';
  if (avatar.startsWith('/')) {
    return '$origin$avatar';
  }

  return '$origin/$avatar';
}
