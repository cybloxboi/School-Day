bool isValidEmail(String email) {
  final emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  return emailRegex.hasMatch(email);
}

bool hasUpperCase(String password) => password.contains(RegExp(r'[A-Z]'));

bool hasLowerCase(String password) => password.contains(RegExp(r'[a-z]'));

bool hasNumber(String password) => password.contains(RegExp(r'[0-9]'));

bool hasMinLength(String password) => password.length >= 6;

bool isPasswordValid(String password) {
  return hasUpperCase(password) &&
      hasLowerCase(password) &&
      hasNumber(password) &&
      hasMinLength(password);
}
