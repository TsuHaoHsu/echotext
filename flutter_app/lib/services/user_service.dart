class UserService{
  static String? _userId;

  static String? get userId=> _userId;

  static set setUserId(String id) {
    _userId = id;
  }

  static void clearUserID(){
    _userId = null;
  }
}