import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';
import '../../../app/router/app_routes.dart';

/* Pantalla de inicio de sesión.
   Permite al usuario introducir sus credenciales y autenticarse
   usando la lógica definida en auth_provider.dart.
*/
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  // Clave para validar el formulario.
  final _formKey = GlobalKey<FormState>();

  // Controladores para acceder al texto introducido en los campos.
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _obscurePassword = true;

  /* Libera los controladores cuando la pantalla se destruye
     para evitar fugas de memoria.
  */
  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /* Valida el formulario y, si es correcto, ejecuta el login
     a través del provider de autenticación.
  */
  Future<void> _handleLogin() async {
    if(!_formKey.currentState!.validate()) return;

    await ref.read(authProvider.notifier).login(
      username: _usernameController.text.trim(),
      password: _passwordController.text.trim(),
    );
  }


  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    /* Escucha cambios en el estado de autenticación para navegar
       cuando el login se complete correctamente.
    */
    ref.listen<AuthState>(authProvider, (previous, next) {
      if(next.status == AuthStatus.authenticated){
        context.go(AppRoutes.inicio);
      }
    });

    /* Indica si el login está en curso para desactivar botones
       y mostrar feedback visual al usuario.
    */
    final bool isLoading = authState.status == AuthStatus.loading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Iniciar sesión'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            // Formulario que agrupa y valida los campos del login.
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Accede a tu cuenta',
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
                    // Validación simple para asegurar que el campo no esté vacío.
                    validator: (value){
                      if(value == null || value.trim().isEmpty){
                        return 'Introduce tu nombre de usuario';
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
                  const SizedBox(height:20),
                  // Si existe un mensaje de error en el estado de auth, se muestra en pantalla.
                  if(authState.errorMessage != null) ...[
                    Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Botón de inicio de sesión, desactivado si isLoading es true.
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _handleLogin,
                      child: isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Iniciar sesión'),
                    ),
                  ),
                  // Enlace para ir a la pantalla de registro, desactivado si isLoading es true.
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: isLoading 
                    ? null 
                    : () {
                        context.go(AppRoutes.registro);
                      },
                    child: const Text('¿No tienes cuenta? Regístrate'),
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