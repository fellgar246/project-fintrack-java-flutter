/// Centralized user-facing copy so screens never hardcode text — prepared
/// for future i18n. Only auth strings live here for now; grows per feature.
class AppStrings {
  AppStrings._();

  static const loginTitle = 'Iniciar sesión';
  static const registerTitle = 'Crear cuenta';
  static const emailLabel = 'Correo electrónico';
  static const passwordLabel = 'Contraseña';
  static const confirmPasswordLabel = 'Confirmar contraseña';
  static const nameLabel = 'Nombre';
  static const loginButton = 'Entrar';
  static const registerButton = 'Crear cuenta';
  static const logoutButton = 'Cerrar sesión';
  static const noAccountPrompt = '¿No tienes cuenta? Regístrate';
  static const hasAccountPrompt = '¿Ya tienes cuenta? Inicia sesión';

  static const invalidCredentials = 'Credenciales inválidas';
  static const emailAlreadyRegistered = 'Ese correo ya está registrado';

  static const emailRequired = 'Ingresa un correo';
  static const emailInvalid = 'Correo inválido';
  static const passwordRequired = 'Ingresa una contraseña';
  static const passwordTooShort = 'Mínimo 8 caracteres';
  static const passwordsDontMatch = 'Las contraseñas no coinciden';
  static const nameRequired = 'Ingresa tu nombre';
}
