class User {
  String id;
  String userName;
  String num;

  User({
    required this.id,
    required this.userName,
    required this.num,
  });
  
  factory User.fromJson(Map<String, dynamic> json){
    return User(
      id: json['id'],
      userName: json['userName'],
      num: json['num'],
    );
  }

}
