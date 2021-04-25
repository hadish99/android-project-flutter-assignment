import 'dart:collection';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:hello_me/userFavorites.dart';

class UserFavoritesNotifier with ChangeNotifier{
  List<UserFavorites> _userFavoritesList = [];
  UserFavorites? _currentUserFavorites;

  UnmodifiableListView<UserFavorites> get userFavoritesList => UnmodifiableListView(_userFavoritesList);

  UserFavorites? get currentUserFavorites => _currentUserFavorites;

  set userFavoritesList(List<UserFavorites> userFavoritesList){
    _userFavoritesList = userFavoritesList;
    notifyListeners();
  }

  set currentUserFavorites(UserFavorites? userFavorites){
    _currentUserFavorites = userFavorites;
    notifyListeners();
  }
}

getUserFavorites(UserFavoritesNotifier userFavoritesNotifier) async {
  QuerySnapshot snapshot = await FirebaseFirestore.instance.collection('favorites').get();

  List<UserFavorites> _userFavoritesList = [];

  snapshot.docs.forEach((doc) {
    UserFavorites userFavorites = UserFavorites.fromMap(doc.data());
    _userFavoritesList.add(userFavorites);
  });

  userFavoritesNotifier.userFavoritesList = _userFavoritesList;
}

uploadUserFavorites(UserFavorites userFavorites, bool isUpdating) async {
  CollectionReference userFavoritesRef = FirebaseFirestore.instance.collection('favorites');

  if(isUpdating){
    await userFavoritesRef.doc(userFavorites.id).update(userFavorites.toMap());
  } else {
    DocumentReference documentReference = await userFavoritesRef.add(userFavorites.toMap());
    userFavorites.id = documentReference.id;
    await documentReference.set(userFavorites.toMap(), SetOptions(merge: true));
  }
}
