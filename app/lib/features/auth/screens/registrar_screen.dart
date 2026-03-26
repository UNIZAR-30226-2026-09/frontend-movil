import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';
import '../../../shared/widgets/auth_inicio_background.dart';

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
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose(){
    // Libera los controladores cuando la pantalla se destruye
    // para evitar fugas de memoria.
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
      body: AuthInicioBackground(
        child: Stack(
          children: [
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF252530).withOpacity(0.92),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFFC5A059),
                        width: 1.2,
                      ),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black54,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: () => context.pop(), 
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: const Alignment(-0.05, 0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF252530).withOpacity(0.92),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Nuevo Recluta',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _usernameController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              labelText: 'Usuario',
                              hintText: 'Nombre de guerra...',
                              filled: true,
                              fillColor: const Color(0xFF1A1A24).withOpacity(0.85),
                              labelStyle: const TextStyle(color: Color(0xFFA0A0B0)),
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
                            ),
                            validator:(value) {
                              if(value == null || value.trim().isEmpty){
                                return 'Introduce un nombre de usuario';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              labelText: 'Correo electrónico',
                              hintText: 'tu@correo.com',
                              filled: true,
                              fillColor: const Color(0xFF1A1A24).withOpacity(0.85),
                              labelStyle:
                                  const TextStyle(color: Color(0xFFA0A0B0)),
                              hintStyle:
                                  const TextStyle(color: Color(0xFFA0A0B0)),
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
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              labelText: 'Contraseña',
                              hintText: 'Mínimo 8 caracteres',
                              filled: true,
                              fillColor: const Color(0xFF1A1A24).withOpacity(0.85),
                              labelStyle:
                                  const TextStyle(color: Color(0xFFA0A0B0)),
                              hintStyle:
                                  const TextStyle(color: Color(0xFFA0A0B0)),
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFA0A0B0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscurePassword = !_obscurePassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Introduce tu contraseña';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 8),

                          TextFormField(
                            controller: _confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              labelText: 'Confirmar contraseña',
                              hintText: 'Repite tu contraseña',
                              filled: true,
                              fillColor: const Color(0xFF1A1A24).withOpacity(0.85),
                              labelStyle: const TextStyle(color: Color(0xFFA0A0B0)),
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
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility
                                      : Icons.visibility_off,
                                  color: const Color(0xFFA0A0B0),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirmPassword = !_obscureConfirmPassword;
                                  });
                                },
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Confirma tu contraseña';
                              }
                              if (value.trim() != _passwordController.text.trim()) {
                                return 'Las contraseñas no coinciden';
                              }
                              return null;
                            },
                          ),


                          const SizedBox(height: 12),

                          if (authState.errorMessage != null) ...[
                            Text(
                              authState.errorMessage!,
                              style: const TextStyle(color: Colors.redAccent),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                          ],

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isLoading ? null : _handleRegister, 
                              child: isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Registrarse'),
                            ),
                          ),
                          const SizedBox(height: 1),

                          TextButton(
                            onPressed: isLoading
                              ? null
                              : () {
                                context.go(AppRoutes.login);
                                },
                            child: const Text('¿Ya eres veterano? Entra aquí'),
                          ),
                        ],
                      ),
                    ),
                  ), 
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
} 
        
//        SingleChildScrollView(
//          padding: const EdgeInsets.all(24),
//          child: ConstrainedBox(
//            constraints: const BoxConstraints(maxWidth: 400),
//            // Formulario que agrupa y valida los campos del registro.
//            child: Form(
//              key: _formKey,
//              child: Column(
//                mainAxisSize: MainAxisSize.min,
//                children: [
//                  const Text(
//                    'Crea tu cuenta',
//                    style: TextStyle(
//                      fontSize: 28,
//                      fontWeight: FontWeight.bold,
//                    ),
//                  ),
//                  const SizedBox(height: 24),
//
//                  // Campo de nombre de usuario.
//                  TextFormField(
//                    controller: _usernameController,
//                    decoration: const InputDecoration(
//                      labelText: 'Nombre de usuario',
//                      border: OutlineInputBorder(),
//                    ),
//                    validator: (value) {
//                      if (value == null || value.trim().isEmpty) {
//                        return 'Introduce un nombre de usuario';
//                      }
//                      return null;
//                    },
//                  ),
//                  const SizedBox(height: 16),
//
//                  // Campo de correo electrónico.
//                  TextFormField(
//                    controller: _emailController,
//                    keyboardType: TextInputType.emailAddress,
//                    decoration: const InputDecoration(
//                      labelText: 'Correo electrónico',
//                      border: OutlineInputBorder(),
//                    ),
//                    validator: (value) {
//                      if (value == null || value.trim().isEmpty) {
//                        return 'Introduce tu correo electrónico';
//                      }
//                      if (!value.contains('@')) {
//                        return 'Introduce un correo válido';
//                      }
//                      return null;
//                    },
//                  ),
//                  const SizedBox(height: 16),
//
//                  // Campo de contraseña.
//                  TextFormField(
//                    controller: _passwordController,
//                    obscureText: _obscurePassword,
//                    decoration: InputDecoration(
//                      labelText: 'Contraseña',
//                      border: OutlineInputBorder(),
//                      suffixIcon: IconButton(
//                        icon: Icon(
//                          _obscurePassword ? Icons.visibility : Icons.visibility_off
//                        ),
//                        onPressed: (){
//                          setState(() {
//                            _obscurePassword = !_obscurePassword;
//                          });
//                        },
//                      ),
//                    ),
//                    // Validación simple para asegurar que el campo no esté vacío.
//                    validator:(value) {
//                      if(value == null || value.trim().isEmpty){
//                        return 'Introduce tu contraseña';
//                      }
//                      return null;
//                    },
//                  ),
//                  const SizedBox(height: 20),
//
//                  // Si existe un mensaje de error en el estado de auth,
//                  // se muestra en pantalla.
//                  if (authState.errorMessage != null) ...[
//                    Text(
//                      authState.errorMessage!,
//                      style: const TextStyle(color: Colors.red),
//                      textAlign: TextAlign.center,
//                    ),
//                    const SizedBox(height: 16),
//                  ],
//
//                  // Botón de registro, desactivado si isLoading es true.
//                  SizedBox(
//                    width: double.infinity,
//                    child: ElevatedButton(
//                      onPressed: isLoading ? null : _handleRegister,
//                      child: isLoading
//                          ? const SizedBox(
//                              height: 20,
//                              width: 20,
//                              child: CircularProgressIndicator(strokeWidth: 2),
//                            )
//                          : const Text('Registrarse'),
//                    ),
//                  ),
//                  const SizedBox(height: 12),
//
//                  // Enlace para volver a la pantalla de login,
//                  // desactivado si isLoading es true.
//                  TextButton(
//                    onPressed: isLoading
//                        ? null
//                        : () {
//                            context.go(AppRoutes.login);
//                          },
//                    child: const Text('¿Ya tienes cuenta? Inicia sesión'),
//                  ),
//                ],
//              ),
//            ),
//          ),
//        ),
//      ),
//    );
//  }
//}