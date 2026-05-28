class HelperClass {
  String? name;
  String? email;
  String? username;
  String? password;

  HelperClass({
    this.name,
    this.email,
    this.username,
    this.password,
  });

  HelperClass.fromMap(Map<String, dynamic> map) {
    name = map["name"];
    email = map["email"];
    username = map["username"];
    password = map["password"];
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "email": email,
      "username": username,
      "password": password,
    };
  }
}
