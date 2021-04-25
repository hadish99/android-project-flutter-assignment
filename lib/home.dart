import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:english_words/english_words.dart';
import 'package:hello_me/authRepository.dart';
import 'package:hello_me/userFavorites.dart';
import 'package:hello_me/userFavorites_notifier.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snapping_sheet/snapping_sheet.dart';
import 'package:hello_me/profilePage.dart';

class RandomWords extends StatefulWidget {
  @override
  _RandomWordsState createState() => _RandomWordsState();
}

class _RandomWordsState extends State<RandomWords> {
  final _suggestions = <WordPair>[];
  final _saved = <WordPair>{};
  final _biggerFont = const TextStyle(fontSize: 18.0);
  final firestoreInstance = FirebaseFirestore.instance;


  @override
  void initState(){
    UserFavoritesNotifier userFavoritesNotifier = Provider.of<UserFavoritesNotifier>(context, listen: false);
    getUserFavorites(userFavoritesNotifier);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    AuthRepository _currentUser = Provider.of<AuthRepository>(context);
    UserFavoritesNotifier userFavoritesNotifier = Provider.of<UserFavoritesNotifier>(context);

    void _logoutUser() async {
      AuthRepository _currentUser = Provider.of<AuthRepository>(context,listen: false);
      try{
        await _currentUser.signOut();
      } catch(e) {
        print(e);
      }
    }
    return Scaffold(
      appBar: AppBar(
        title: Text('Startup Name Generator'),
        actions: [
          IconButton(icon: Icon(Icons.favorite), onPressed: _pushSaved),
          _currentUser.status != Status.Authenticated
            ? IconButton(icon: Icon(Icons.login), onPressed: _loginScreen)
            : IconButton(icon: Icon(Icons.exit_to_app), onPressed: _logoutUser),
        ],
      ),
      body: _buildSuggestions(context, _currentUser, userFavoritesNotifier),
    );
  }


  void _pushSaved() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        // NEW lines from here...
        builder: (BuildContext context) {
          AuthRepository _currentUser = Provider.of<AuthRepository>(context);
          UserFavoritesNotifier userFavoritesNotifier = Provider.of<UserFavoritesNotifier>(context);
          final tiles;
          if(_currentUser.status != Status.Authenticated) {
            tiles = _saved.map(
                  (WordPair pair) {
                return ListTile(
                  title: Text(
                    pair.asPascalCase,
                    style: _biggerFont,
                  ),
                  trailing: Icon(
                    Icons.delete_outlined,
                    color: Colors.redAccent,
                  ),
                  onTap: () {
                    setState(() {
                      _saved.remove(pair);
                      Navigator.of(context).pop();
                      _pushSaved();
                    });
                  },
                );
              },
            );
          } else {
            tiles = userFavoritesNotifier.currentUserFavorites!.savedNames.map(
                  (e) {
                return ListTile(
                  title: Text(
                    e,
                    style: _biggerFont,
                  ),
                  trailing: Icon(
                    Icons.delete_outlined,
                    color: Colors.redAccent,
                  ),
                  onTap: () {
                    setState(() {
                      UserFavorites userFavorites =  UserFavorites();
                      userFavorites.id = userFavoritesNotifier.currentUserFavorites!.id;
                      userFavorites.email = userFavoritesNotifier.currentUserFavorites!.email;
                      userFavorites.savedNames = userFavoritesNotifier.currentUserFavorites!.savedNames;
                      userFavorites.savedNames.removeWhere((element) => element == e);
                      uploadUserFavorites(userFavorites, true);
                      _saved.removeWhere((element) =>  element.asPascalCase.toString() == e);
                      Navigator.of(context).pop();
                      _pushSaved();
                    });
                  },
                );
              },
            );
          }
          final divided = ListTile.divideTiles(
            context: context,
            tiles: tiles,
          ).toList();

          return Scaffold(
            appBar: AppBar(
              title: Text('Saved Suggestions'),
            ),
            body: ListView(children: divided),
          );
        }, // ...to here.
      ),
    );
  }

  void _loginScreen(){
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          TextEditingController _email = TextEditingController(text: "");
          TextEditingController _password = TextEditingController(text: "");
          TextEditingController _conformationPassword = TextEditingController(text: "");
          AuthRepository _user = Provider.of<AuthRepository>(context);
          void _loginUser(String email, String password, BuildContext context) async {
            AuthRepository _currentUser = Provider.of<AuthRepository>(context,listen: false);
            UserFavoritesNotifier userFavoritesNotifier = Provider.of<UserFavoritesNotifier>(context,listen: false);
            try{
              if(await _currentUser.signIn(email, password)){
                final index = userFavoritesNotifier.userFavoritesList.indexWhere((element) => element.email == email);
                if(index != -1) {
                  userFavoritesNotifier.currentUserFavorites = userFavoritesNotifier.userFavoritesList[index];
                  UserFavorites userFavorites = UserFavorites();
                  userFavorites.id = userFavoritesNotifier.currentUserFavorites!.id;
                  userFavorites.email = userFavoritesNotifier.currentUserFavorites!.email;
                  List list = userFavoritesNotifier.currentUserFavorites!.savedNames;
                  _saved.forEach((element) async {
                    list.add(element.asPascalCase.toString());
                    userFavorites.savedNames = list;
                    await uploadUserFavorites(userFavorites, true);
                  });
                  _saved.clear();
                } else {
                  UserFavorites userFavorites = UserFavorites();
                  userFavorites.email = email;
                  List list = [];
                  userFavorites.savedNames = list;
                  userFavorites.id = "";
                  await uploadUserFavorites(userFavorites, false);
                  FirebaseFirestore.instance.waitForPendingWrites();
                  await getUserFavorites(userFavoritesNotifier);
                  final idx = userFavoritesNotifier.userFavoritesList.indexWhere((element) => element.email == email);
                  userFavoritesNotifier.currentUserFavorites = userFavoritesNotifier.userFavoritesList[idx];
                  UserFavorites userFavorites2 = UserFavorites();
                  userFavorites2.email = _user.user!.email!;
                  List list2 = [];
                  userFavorites2.savedNames = list2;
                  userFavorites2.id = userFavoritesNotifier.currentUserFavorites!.id;
                  _saved.forEach((element) async {
                    list2.add(element.asPascalCase.toString());
                    userFavorites2.savedNames = list2;
                    await uploadUserFavorites(userFavorites2, true);
                    FirebaseFirestore.instance.waitForPendingWrites();
                  });
                  _saved.clear();
                  FirebaseFirestore.instance.waitForPendingWrites();
                  await getUserFavorites(userFavoritesNotifier);
                  final idx2 = userFavoritesNotifier.userFavoritesList.indexWhere((element)
                  => element.email == email);
                  userFavoritesNotifier.currentUserFavorites = userFavoritesNotifier.userFavoritesList[idx2];
                }
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("There was an error logging into the app"))
                );
              }
            } catch(e) {
              print(e);
            }
          }
          void _signUpUser(String email, String password, BuildContext context) async{
            AuthRepository _currentUser = Provider.of<AuthRepository>(context,listen: false);
            UserFavoritesNotifier userFavoritesNotifier = Provider.of<UserFavoritesNotifier>(context,listen: false);
            try{
              if(await _currentUser.signUp(email, password) != null) {
                UserFavorites userFavorites = UserFavorites();
                userFavorites.email = email;
                List list = [];
                userFavorites.savedNames = list;
                userFavorites.id = "";
                await uploadUserFavorites(userFavorites, false);
                FirebaseFirestore.instance.waitForPendingWrites();
                await getUserFavorites(userFavoritesNotifier);
                final idx = userFavoritesNotifier.userFavoritesList.indexWhere((
                    element) => element.email == email);
                userFavoritesNotifier.currentUserFavorites =
                userFavoritesNotifier.userFavoritesList[idx];
                UserFavorites userFavorites2 = UserFavorites();
                userFavorites2.email = _user.user!.email!;
                List list2 = [];
                userFavorites2.savedNames = list2;
                userFavorites2.id =
                    userFavoritesNotifier.currentUserFavorites!.id;
                _saved.forEach((element) async {
                  list2.add(element.asPascalCase.toString());
                  userFavorites2.savedNames = list2;
                  await uploadUserFavorites(userFavorites2, true);
                  FirebaseFirestore.instance.waitForPendingWrites();
                });
                _saved.clear();
                FirebaseFirestore.instance.waitForPendingWrites();
                await getUserFavorites(userFavoritesNotifier);
                final idx2 = userFavoritesNotifier.userFavoritesList
                    .indexWhere((element) => element.email == email);
                userFavoritesNotifier.currentUserFavorites =
                userFavoritesNotifier.userFavoritesList[idx2];
                Navigator.pop(context);
                Navigator.pop(context);
                setState(() {});
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("There was an error logging into the app"))
                );
              }
            } catch(e) {
              print(e);
            }
          }
          return Scaffold(
              appBar: AppBar(
                centerTitle: true,
                title: Text('Login'),
              ),
              body:
              ListView(
                  children: <Widget>[
                    Container(
                        alignment: Alignment.centerLeft,
                        padding: EdgeInsets.all(10),
                        child: Text(
                          'Welcome to Startup Names Generator, please log in below',
                          style: TextStyle(fontSize: 18),
                        )),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        controller: _email,
                        decoration: InputDecoration(
                          labelText: 'Email',
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.all(16),
                      child: TextField(
                        obscureText: true,
                        controller: _password,
                        decoration: InputDecoration(
                          labelText: 'Password',
                        ),
                      ),
                    ),
                    _user.status == Status.Authenticating
                      ? Center(child: CircularProgressIndicator())
                      : Container(
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            primary: Colors.red, // background
                            onPrimary: Colors.white, // foreground
                            shape: new RoundedRectangleBorder(
                              borderRadius: new BorderRadius.circular(30.0),
                            ),
                          ),
                          child: Text('Log in'),
                          onPressed: () {
                            _loginUser(_email.text, _password.text, context);
                          },
                        )
                    ),
                    Container(
                        padding: EdgeInsets.all(10),
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              primary: Colors.teal, // background
                              onPrimary: Colors.white, // foreground
                              shape: new RoundedRectangleBorder(
                                borderRadius: new BorderRadius.circular(30.0),
                              ),
                            ),
                            child: Text('New user? Click to sign up'),
                            onPressed: () {
                              showModalBottomSheet<dynamic>(context: context,
                                builder: (BuildContext context) {
                                  return SingleChildScrollView(
                                      child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'Please confirm your password below:',
                                              style: TextStyle(height: 2, fontSize: 18),
                                              textAlign: TextAlign.center,
                                            ),
                                            Divider(
                                              height: 20,
                                              indent: 20,
                                              endIndent: 20,
                                            ),
                                            Container(
                                              padding: EdgeInsets.all(16),
                                              child: TextField(
                                                obscureText: true,
                                                controller: _conformationPassword,
                                                decoration: InputDecoration(
                                                  errorText: _conformationPassword.text == _password.text
                                                      || _conformationPassword.text == "" ? null : 'Passwords must match' ,
                                                  labelText: 'Password',
                                                ),
                                              ),
                                            ),
                                            Row(
                                                mainAxisSize: MainAxisSize.min,
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  ElevatedButton(
                                                    style: ElevatedButton.styleFrom(
                                                      primary: Colors.teal, // background
                                                      onPrimary: Colors.white, // foreground
                                                      alignment: Alignment.center,
                                                      shape: const ContinuousRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                                                    ),
                                                    child: Text('Confirm'),
                                                    onPressed: () {
                                                      if(_conformationPassword.text == _password.text) {
                                                        _signUpUser(_email.text, _password.text, context);
                                                      } else{
                                                        setState(() {
                                                        });
                                                      }
                                                    },
                                                  ),
                                                ]
                                            )
                                          ]
                                      )
                                  );
                                },
                              );
                            }
                        )
                    ),
                  ]
              )
          );
        },
      ),
    );
  }

  Widget _buildRow(WordPair pair, BuildContext context, AuthRepository currentUser, UserFavoritesNotifier userFavoritesNotifier) {
    final alreadySaved = _saved.contains(pair);
    return ListTile(
      title: Text(
        pair.asPascalCase,
        style: _biggerFont,
      ),
      trailing: Icon(
        alreadySaved || (currentUser.status == Status.Authenticated &&
              userFavoritesNotifier.currentUserFavorites!.savedNames.contains(pair.asPascalCase.toString()))
            ? Icons.favorite : Icons.favorite_border,
        color: alreadySaved || (currentUser.status == Status.Authenticated &&
            userFavoritesNotifier.currentUserFavorites!.savedNames.contains(pair.asPascalCase.toString()))
            ? Colors.red : null,
      ),
      onTap: () {
        setState(() {
          if (alreadySaved || (currentUser.status == Status.Authenticated &&
              userFavoritesNotifier.currentUserFavorites!.savedNames.contains(pair.asPascalCase.toString()))) {
            if(currentUser.status == Status.Authenticated){
              UserFavorites userFavorites =  UserFavorites();
              userFavorites.id = userFavoritesNotifier.currentUserFavorites!.id;
              userFavorites.email = userFavoritesNotifier.currentUserFavorites!.email;
              userFavorites.savedNames = userFavoritesNotifier.currentUserFavorites!.savedNames;
              userFavorites.savedNames.removeWhere((element) => element == pair.asPascalCase.toString());
              uploadUserFavorites(userFavorites, true);
            } else {
              _saved.remove(pair);
            }
          } else {
            if(currentUser.status == Status.Authenticated){
              UserFavorites userFavorites =  UserFavorites();
              userFavorites.id = userFavoritesNotifier.currentUserFavorites!.id;
              userFavorites.email = userFavoritesNotifier.currentUserFavorites!.email;
              userFavorites.savedNames = userFavoritesNotifier.currentUserFavorites!.savedNames;
              userFavorites.savedNames.add(pair.asPascalCase.toString());
              uploadUserFavorites(userFavorites, true);
            } else {
              _saved.add(pair);
            }
          }
        });
      },
    );
  }
  Widget _buildSuggestions(BuildContext context, AuthRepository currentUser, UserFavoritesNotifier userFavoritesNotifier) {
    return ListView.builder(
        padding: const EdgeInsets.all(16),
        itemBuilder: (BuildContext _context, int i) {
          if (i.isOdd) {
            return Divider();
          }
          final int index = i ~/ 2;
          if (index >= _suggestions.length) {
            _suggestions.addAll(generateWordPairs().take(10));
          }
          return _buildRow(_suggestions[index], context, currentUser, userFavoritesNotifier);
        }
    );
  }
}
