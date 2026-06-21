class LoginService {
  // Validamos que el correo sea básico (contenga @)
  bool validateEmail(String email) {
    return email.contains('@');
  }

  // Validamos que la contraseña no sea vacía o muy corta
  bool validatePassword(String password) {
    return password.length >= 6;
  }
}