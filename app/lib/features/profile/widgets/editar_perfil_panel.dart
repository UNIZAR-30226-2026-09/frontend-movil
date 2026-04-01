import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_provider.dart';
import '../providers/profile_provider.dart';

class EditarPerfilPanel extends ConsumerStatefulWidget {
  const EditarPerfilPanel({
    super.key,
    required this.onClose,
  });

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

  bool _obscureNewPassword = true;
  bool _obscureRepeatPassword = true;

  @override
  void initState() {
    super.initState();
    final emailInicial = ref.read(authProvider).user?.email ?? '';
    _emailController = TextEditingController(text: emailInicial);
  }

  @override
  void dispose() {
    _emailController.dispose();
    _newPasswordController.dispose();
    _repeatPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final newPassword = _newPasswordController.text.trim();

    final emailActual = ref.read(authProvider).user?.email?.trim() ?? '';
    final emailCambiado = email.isNotEmpty && email != emailActual;
    final passwordInformada = newPassword.isNotEmpty;

    if (!emailCambiado && !passwordInformada) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No has cambiado ningún dato'),
        ),
      );
      return;
    }

    final ok = await ref.read(profileProvider.notifier).updateProfile(
          email: emailCambiado ? email : null,
          password: passwordInformada ? newPassword : null,
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
      padding: EdgeInsets.fromLTRB(
        16,
        24,
        16,
        keyboardInset + 24,
      ),
      child: Align(
        alignment: Alignment.center,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 700,
            maxHeight: maxPanelHeight,
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF252530).withOpacity(0.96),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: const Color(0xFFC5A059),
                  width: 1.2,
                ),
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
                              const Text(
                                'Correo electrónico',
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
                                    return 'Introduce un correo válido';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Nueva contraseña',
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
                                  hintText: 'Déjalo vacío si no quieres cambiarla',
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
                                'Repetir nueva contraseña',
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
                                  hintText: 'Repite la nueva contraseña',
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
                                  final newPassword =
                                      _newPasswordController.text.trim();
  
                                  if (newPassword.isEmpty &&
                                      repeated.isEmpty) {
                                    return null;
                                  }
  
                                  if (newPassword.isNotEmpty &&
                                      repeated.isEmpty) {
                                    return 'Repite la nueva contraseña';
                                  }
  
                                  if (repeated != newPassword) {
                                    return 'Las contraseñas no coinciden';
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
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 12,
        vertical: 12,
      ),
      filled: true,
      fillColor: const Color(0xFF252530),
      hintStyle: const TextStyle(color: Color(0xFFA0A0B0)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF8C6D3F),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFFC5A059),
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1,
        ),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }
}