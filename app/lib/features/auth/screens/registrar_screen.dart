import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';

/// Pantalla de registro.
/// Permite al usuario crear una nueva cuenta usando la lógica
/// definida en auth_provider.dart.
class RegistrarScreen extends ConsumerStatefulWidget {
  const RegistrarScreen({super.key});

  @override
  ConsumerState<RegistrarScreen> createState() => _RegistrarScreenState();
}

class _RegistrarScreenState extends ConsumerState<RegistrarScreen> {
  // Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  // Controladores para acceder al texto introducido en los campos.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  @override
  void dispose(){
    // Libera los controladores cuando la pantalla se destruye
    // para evitar fugas de memoria.
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// Valida el formulario y, si es correcto, ejecuta el registro
  /// a través del provider de autenticación.
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).register(
      username: _usernameController.text.trim(),
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context){
    final authState = ref.watch(authProvider);

    /// Escucha cambios en el estado de autenticación para volver
    /// a la pantalla de login cuando el registro termine correctamente.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final bool wasLoading = previous?.status == AuthStatus.loading;
      final bool isNowUnauthenticated =
          next.status == AuthStatus.unauthenticated;

      // Si venimos de loading y terminamos en unauthenticated sin error,
      // asumimos que el registro ha ido bien.
      if (wasLoading && isNowUnauthenticated && next.errorMessage == null){
        context.go(AppRoutes.login);
      }
    });

    /// Indica si el registro está en curso para desactivar botones
    /// y mostrar feedback visual al usuario.
    final bool isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registrarse'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            // Formulario que agrupa y valida los campos del registro.
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Crea tu cuenta',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Campo de nombre de usuario.
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre de usuario',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce un nombre de usuario';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de correo electrónico.
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo electrónico',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduce tu correo electrónico';
                      }
                      if (!value.contains('@')) {
                        return 'Introduce un correo válido';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campo de contraseña.
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off
                        ),
                        onPressed: (){
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    // Validación simple para asegurar que el campo no esté vacío.
                    validator:(value) {
                      if(value == null || value.trim().isEmpty){
                        return 'Introduce tu contraseña';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Si existe un mensaje de error en el estado de auth,
                  // se muestra en pantalla.
                  if (authState.errorMessage != null) ...[
                    Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Botón de registro, desactivado si isLoading es true.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleRegister,
                      child: isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Registrarse'),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Enlace para volver a la pantalla de login,
                  // desactivado si isLoading es true.
                  TextButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            context.go(AppRoutes.login);
                          },
                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}