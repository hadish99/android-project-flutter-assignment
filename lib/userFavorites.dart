

class UserFavorites {
  late String id;
  late String email;
  late List savedNames;

  UserFavorites();

  UserFavorites.fromMap(Map<String, dynamic> data){
    id = data['id'];
    email = data['email'];
    savedNames = data['savedNames'];
  }

  Map<String, dynamic> toMap(){
    return{
      'id': id,
      'email': email,
      'savedNames': savedNames
    };
  }
}