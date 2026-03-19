class Session {
  static String? currentLogin;

  static void setLogin(String login) {
    currentLogin = login;
  }

  static void clear() {
    currentLogin = null;
  }
}
