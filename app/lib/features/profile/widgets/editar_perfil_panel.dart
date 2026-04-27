import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/avatar_url_resolver.dart';
import '../../../shared/widgets/app_avatar.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/avatar_option_model.dart';
import '../providers/profile_provider.dart';

class EditarPerfilPanel extends ConsumerStatefulWidget {
  const EditarPerfilPanel({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<EditarPerfilPanel> createState() => _EditarPerfilPanelState();
}

class _EditarPerfilPanelState extends ConsumerState<EditarPerfilPanel> {
  static const List<AvatarOptionModel> _fallbackAvatarOptions =
      <AvatarOptionModel>[
        AvatarOptionModel(
          avatarName: '1.png',
          previewUrl: 'assets/images/fotoPerfil1svg.png',
        ),
        AvatarOptionModel(
          avatarName: '2.png',
          previewUrl: 'assets/images/fotoPerfil2svg.png',
        ),
        AvatarOptionModel(
          avatarName: '3.png',
          previewUrl: 'assets/images/fotoPerfil3svg.png',
        ),
        AvatarOptionModel(
          avatarName: '4.png',
          previewUrl: 'assets/images/fotoPerfil4svg.png',
        ),
        AvatarOptionModel(
          avatarName: '5.png',
          previewUrl: 'assets/images/fotoPerfil5svg.png',
        ),
        AvatarOptionModel(
          avatarName: '6.png',
          previewUrl: 'assets/images/fotoPerfil6svg.png',
        ),
      ];

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _emailController;
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _repeatPasswordController =
      TextEditingController();

  String? _selectedAvatarName;
  String? _selectedAvatarPreview;
  List<AvatarOptionModel> _avatarOptions = const <AvatarOptionModel>[];
  bool _loadingAvatarOptions = true;

  bool _obscureNewPassword = true;
  bool _obscureRepeatPassword = true;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _emailController = TextEditingController(text: user?.email ?? '');
    _selectedAvatarName = _extractAvatarName(user?.avatar);
    _loadAvatarOptions();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatarOptions() async {
    setState(() {
      _loadingAvatarOptions = true;
    });

    try {
      final backendOptions = await ref
          .read(profileServiceProvider)
          .fetchAvatarOptions();
      final enriched = _buildPickerOptions(backendOptions);

      if (!mounted) return;
      setState(() {
        _avatarOptions = enriched;
        _loadingAvatarOptions = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _avatarOptions = _fallbackAvatarOptions;
        _loadingAvatarOptions = false;
      });
    }
  }

  List<AvatarOptionModel> _buildPickerOptions(
    List<AvatarOptionModel> backendOptions,
  ) {
    if (backendOptions.isEmpty) {
      return _fallbackAvatarOptions;
    }

    final fallbackByName = <String, AvatarOptionModel>{
      for (final option in _fallbackAvatarOptions)
        option.avatarName.toLowerCase(): option,
    };

    return backendOptions
        .map((option) {
          if ((option.previewUrl ?? '').trim().isNotEmpty) {
            return option;
          }
          final fallback = fallbackByName[option.avatarName.toLowerCase()];
          if (fallback == null) return option;
          return AvatarOptionModel(
            avatarName: option.avatarName,
            previewUrl: fallback.previewUrl,
          );
        })
        .toList(growable: false);
  }

  String _extractAvatarName(String? avatarRaw) {
    final raw = avatarRaw?.trim() ?? '';
    if (raw.isEmpty) return '';

    final withoutQuery = raw.split('?').first;
    final segments = withoutQuery
        .split('/')
        .where((s) => s.isNotEmpty)
        .toList(growable: false);
    final fileName = segments.isEmpty ? withoutQuery : segments.last;

    final dotIndex = fileName.lastIndexOf('.');
    if (dotIndex <= 0) return fileName;
    return fileName.substring(0, dotIndex);
  }

  Future<void> _openAvatarPicker() async {
    if (_loadingAvatarOptions) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Cargando avatares...')));
      return;
    }

    final options = _avatarOptions;
    if (options.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No hay avatares disponibles ahora mismo'),
        ),
      );
      return;
    }

    final selected = await showDialog<AvatarOptionModel>(
      context: context,
      builder: (dialogContext) {
        final media = MediaQuery.of(dialogContext).size;
        final crossAxisCount = media.width > 620 ? 4 : 3;

        return Dialog(
          backgroundColor: const Color(0xFF1A1A24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Elige tu avatar',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(dialogContext).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: crossAxisCount,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: options.length,
                      itemBuilder: (context, index) {
                        final option = options[index];
                        final isSelected =
                            option.avatarName.toLowerCase() ==
                            (_selectedAvatarName ?? '').toLowerCase();

                        return InkWell(
                          onTap: () => Navigator.of(dialogContext).pop(option),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF252530),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFC5A059)
                                    : const Color(0xFF8C6D3F),
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Center(
                                child: _AvatarPreview(
                                  radius: 32,
                                  source: option.previewUrl,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;

    setState(() {
      _selectedAvatarName = selected.avatarName;
      _selectedAvatarPreview = selected.previewUrl;
    });
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    final email = _emailController.text.trim();
    final avatarName = (_selectedAvatarName ?? '').trim();
    final newPassword = _newPasswordController.text.trim();

    final emailActual = user?.email.trim() ?? '';
    final avatarActual = _extractAvatarName(user?.avatar);
    final emailCambiado = email.isNotEmpty && email != emailActual;
    final avatarCambiado = avatarName.isNotEmpty && avatarName != avatarActual;
    final passwordInformada = newPassword.isNotEmpty;

    if (!emailCambiado && !passwordInformada && !avatarCambiado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No has cambiado ningun dato')),
      );
      return;
    }

    final ok = await ref
        .read(profileProvider.notifier)
        .updateProfile(
          email: emailCambiado ? email : null,
          password: passwordInformada ? newPassword : null,
          avatarName: avatarCambiado ? avatarName : null,
        );

    if (!mounted) return;

    final profileState = ref.read(profileProvider);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          profileState.message ??
              (ok
                  ? 'Perfil actualizado correctamente'
                  : 'No se pudo actualizar el perfil'),
        ),
      ),
    );

    if (ok) {
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileState = ref.watch(profileProvider);
    final isLoading = profileState.status == ProfileActionStatus.loading;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final maxPanelHeight = keyboardInset > 0
        ? screenHeight * 0.72
        : screenHeight * 0.78;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.fromLTRB(16, 24, 16, keyboardInset + 24),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 700, maxHeight: maxPanelHeight),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF252530).withOpacity(0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFC5A059), width: 1.2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black54,
                    blurRadius: 20,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'EDITAR PERFIL',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A1A24),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFC5A059),
                            width: 1.1,
                          ),
                        ),
                        child: IconButton(
                          onPressed: isLoading ? null : widget.onClose,
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A24).withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFF8C6D3F),
                          width: 1,
                        ),
                      ),
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Center(
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: isLoading
                                          ? null
                                          : _openAvatarPicker,
                                      customBorder: const CircleBorder(),
                                      child: Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          _AvatarPreview(
                                            source: _selectedAvatarPreview,
                                            fallback: ref
                                                .watch(authProvider)
                                                .user
                                                ?.avatar,
                                            radius: 38,
                                          ),
                                          Positioned(
                                            right: -2,
                                            bottom: -2,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFFC5A059),
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF1A1A24,
                                                  ),
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: Color(0xFF1A1A24),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      _loadingAvatarOptions
                                          ? 'Cargando avatares...'
                                          : 'Pulsa la foto para cambiar avatar',
                                      style: const TextStyle(
                                        color: Color(0xFFA0A0B0),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Correo electronico',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  hintText: 'tu@correo.com',
                                ),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return null;
                                  if (!email.contains('@')) {
                                    return 'Introduce un correo valido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Nueva contrasena',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _newPasswordController,
                                obscureText: _obscureNewPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  hintText:
                                      'Dejalo vacio si no quieres cambiarla',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFFA0A0B0),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureNewPassword =
                                            !_obscureNewPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  final password = value?.trim() ?? '';
                                  if (password.isEmpty) return null;
                                  if (password.length < 8) {
                                    return 'Debe tener al menos 8 caracteres';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Repetir nueva contrasena',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              TextFormField(
                                controller: _repeatPasswordController,
                                obscureText: _obscureRepeatPassword,
                                style: const TextStyle(color: Colors.white),
                                decoration: _inputDecoration(
                                  hintText: 'Repite la nueva contrasena',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRepeatPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: const Color(0xFFA0A0B0),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _obscureRepeatPassword =
                                            !_obscureRepeatPassword;
                                      });
                                    },
                                  ),
                                ),
                                validator: (value) {
                                  final repeated = value?.trim() ?? '';
                                  final newPassword = _newPasswordController
                                      .text
                                      .trim();

                                  if (newPassword.isEmpty && repeated.isEmpty) {
                                    return null;
                                  }

                                  if (newPassword.isNotEmpty &&
                                      repeated.isEmpty) {
                                    return 'Repite la nueva contrasena';
                                  }

                                  if (repeated != newPassword) {
                                    return 'Las contrasenas no coinciden';
                                  }

                                  return null;
                                },
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: isLoading ? null : _handleSubmit,
                                  child: isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('GUARDAR CAMBIOS'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      filled: true,
      fillColor: const Color(0xFF252530),
      hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF8C6D3F), width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFD32F2F), width: 1.5),
      ),
    );
  }
}

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({required this.radius, this.source, this.fallback});

  final double radius;
  final String? source;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final value = (source ?? '').trim();
    if (value.isEmpty) {
      return AppAvatar(avatar: fallback, radius: radius);
    }

    if (value.startsWith('assets/')) {
      return Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(shape: BoxShape.circle),
        clipBehavior: Clip.antiAlias,
        child: Image.asset(
          value,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return AppAvatar(avatar: fallback, radius: radius);
          },
        ),
      );
    }

    final resolved = resolveAvatarUrl(value) ?? value;
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(shape: BoxShape.circle),
      clipBehavior: Clip.antiAlias,
      child: Image.network(
        resolved,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return AppAvatar(avatar: fallback, radius: radius);
        },
      ),
    );
  }
}
