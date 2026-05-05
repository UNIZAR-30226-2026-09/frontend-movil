import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_theme.dart';
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
        _avatarOptions = const <AvatarOptionModel>[];
        _loadingAvatarOptions = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se pudo cargar el catalogo de avatares desde backend.',
          ),
        ),
      );
    }
  }

  List<AvatarOptionModel> _buildPickerOptions(
    List<AvatarOptionModel> backendOptions,
  ) {
    return backendOptions
        .map((option) {
          final previewCandidate = (option.previewUrl ?? '').trim();
          final hasPreview =
              previewCandidate.isNotEmpty &&
              (previewCandidate.startsWith('http://') ||
                  previewCandidate.startsWith('https://') ||
                  previewCandidate.startsWith('/'));
          if (hasPreview) {
            return option;
          }
          return option;
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

    return fileName;
  }

  String _avatarDisplayName(String avatarName) {
    final cleanName = avatarName
        .replaceAll('.png', '')
        .replaceAll('.jpg', '')
        .replaceAll('.jpeg', '')
        .replaceAll('.webp', '')
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim();

    switch (cleanName.toLowerCase()) {
      case '1':
        return 'José Antonio Labordeta';
      case '2':
        return 'Alberto Zapater';
      case '3':
        return 'Amaral';
      case '4':
        return 'Kase.O';
      case '5':
        return 'Francisco de Goya';
      case '6':
        return 'Jesús Vallejo';
      default:
        return cleanName.isEmpty ? 'Avatar' : cleanName;
    }
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
        final crossAxisCount = 3;
        String localSelectedAvatarName = _selectedAvatarName ?? '';
        String? pressedAvatarName;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.panelOverlay.withValues(alpha: 0.96),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppTheme.borderGold,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.54),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
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
                                'ELIGE TU AVATAR',
                                style: TextStyle(
                                  color: AppTheme.borderGold,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                            _PanelCloseButton(
                              onPressed: () => Navigator.of(dialogContext).pop(),
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
                              childAspectRatio: 1.25,
                            ),
                            itemCount: options.length,
                            itemBuilder: (context, index) {
                              final option = options[index];
                              final isSelected =
                                  option.avatarName.toLowerCase() ==
                                  localSelectedAvatarName.toLowerCase();
                              final isPressed =
                                option.avatarName.toLowerCase() ==
                                (pressedAvatarName ?? '').toLowerCase();

                              return GestureDetector(
                                onTapDown: (_) {
                                  setDialogState(() {
                                    pressedAvatarName = option.avatarName;
                                  });
                                },
                                onTapCancel: () {
                                  setDialogState(() {
                                    pressedAvatarName = null;
                                  });
                                },
                                onTapUp: (_) {
                                  setDialogState(() {
                                    pressedAvatarName = null;
                                    localSelectedAvatarName = option.avatarName;
                                  });


                                  Future.delayed(const Duration(milliseconds: 90), () {
                                    if (dialogContext.mounted) {
                                      Navigator.of(dialogContext).pop(option);
                                    }
                                  });
                                },
                                child: AnimatedScale(
                                  scale: isPressed ? 0.96 : 1,
                                  duration: const Duration(milliseconds: 90),
                                  curve: Curves.easeOut,
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 90),
                                    curve: Curves.easeOut,
                                    decoration: BoxDecoration(
                                      color: AppTheme.surface.withValues(alpha: 0.78),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isPressed || isSelected
                                            ? AppTheme.borderGoldVivo
                                            : AppTheme.borderBronze,
                                        width: isPressed || isSelected ? 2 : 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          _AvatarPreview(
                                            radius: 30,
                                            source: option.previewUrl,
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            _avatarDisplayName(option.avatarName),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: isPressed || isSelected
                                                  ? AppTheme.borderGoldVivo
                                                  : AppTheme.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              height: 1.05,
                                            ),
                                          ),
                                        ],
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
              ),
            );
          },
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
                color: AppTheme.panelOverlay.withValues(alpha: 0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppTheme.borderGold, width: 1.2),
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
                            color: AppTheme.borderGold,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      _PanelCloseButton(
                        enabled: !isLoading,
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppTheme.borderGold,
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
                                                color: AppTheme.borderGold,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: AppTheme.surface,
                                                  width: 1.5,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.edit,
                                                size: 14,
                                                color: AppTheme.surface,
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
                                        color: AppTheme.textSecondary,
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
                                style: const TextStyle(color: AppTheme.textSecondary),
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
                                style: const TextStyle(color: AppTheme.text),
                                decoration: _inputDecoration(
                                  hintText:
                                      'Dejalo vacio si no quieres cambiarla',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureNewPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppTheme.textSecondary,
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
                                style: const TextStyle(color: AppTheme.text),
                                decoration: _inputDecoration(
                                  hintText: 'Repite la nueva contrasena',
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscureRepeatPassword
                                          ? Icons.visibility
                                          : Icons.visibility_off,
                                      color: AppTheme.textSecondary,
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
                              _SaveProfileButton(
                                isLoading: isLoading,
                                onPressed: _handleSubmit,
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
      fillColor: AppTheme.surface,
      hintStyle: const TextStyle(color: AppTheme.textSecondary),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderBronze, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.borderGold, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppTheme.error, width: 1.5),
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

class _PanelCloseButton extends StatefulWidget {
  const _PanelCloseButton({
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  State<_PanelCloseButton> createState() => _PanelCloseButtonState();
}

class _PanelCloseButtonState extends State<_PanelCloseButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (!widget.enabled) return;
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.borderGold.withValues(alpha: widget.enabled ? 1 : 0.45);

    final iconColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.primary.withValues(alpha: widget.enabled ? 1 : 0.45);

    return AnimatedScale(
      scale: _pressed ? 0.94 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.enabled ? widget.onPressed : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: borderColor,
              width: _pressed ? 1.5 : 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.38),
                blurRadius: _pressed ? 8 : 10,
                offset: Offset(0, _pressed ? 3 : 4),
              ),
            ],
          ),
          child: Icon(
            Icons.close_rounded,
            color: iconColor,
            size: 22,
          ),
        ),
      ),
    );
  }
}


class _SaveProfileButton extends StatefulWidget {
  const _SaveProfileButton({
    required this.isLoading,
    required this.onPressed,
  });

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_SaveProfileButton> createState() => _SaveProfileButtonState();
}

class _SaveProfileButtonState extends State<_SaveProfileButton> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (widget.isLoading) return;
    if (_pressed == value) return;

    setState(() {
      _pressed = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    final backgroundColor = _pressed
        ? AppTheme.borderGoldVivo
        : AppTheme.primary;

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      child: GestureDetector(
        onTapDown: (_) => _setPressed(true),
        onTapUp: (_) => _setPressed(false),
        onTapCancel: () => _setPressed(false),
        onTap: widget.isLoading ? null : widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.isLoading
                ? AppTheme.disabled
                : backgroundColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: _pressed ? 0.22 : 0.32),
                blurRadius: _pressed ? 8 : 10,
                offset: Offset(0, _pressed ? 3 : 5),
              ),
            ],
          ),
          child: widget.isLoading
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppTheme.bg,
                  ),
                )
              : const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(
                    color: AppTheme.bg,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
        ),
      ),
    );
  }
}