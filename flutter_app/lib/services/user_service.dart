import 'dart:developer' as devtools show log;
import 'package:echotext/requests/get_friend_list.dart';

class UserService{
  static String? _userId;
  static List<Map<String,dynamic>>? _friendList;

  // Getter
  static String? get userId=> _userId;
  static List<Map<String,dynamic>>? get friendList => _friendList;

  // Setter
  static set setUserId(String id) {
    _userId = id;
  }

  static void clearUserID(){
    _userId = null;
  }

  static set setFriendList(List<Map<String,dynamic>>? friends) {
    _friendList = friends;
  }
  static Future<void> fetchFriendList() async {
    if (_userId != null){
      
      try{
        List<Map<String, dynamic>> friendResponse = await getFriendList(_userId!);
        _friendList = friendResponse;

      } catch (e) {
        devtools.log("Error fetching friend list: $e");
        _friendList = [];
      }
    }
  }

  static void clearFriendList(){
    _friendList = null;
  }
}