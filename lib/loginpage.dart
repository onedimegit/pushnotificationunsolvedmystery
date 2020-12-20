import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'homescreen.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}



class _LoginPageState extends State<LoginPage> {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  final GoogleSignIn googleSignIn = GoogleSignIn();
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  SharedPreferences preferences;
  bool isLoading = false;
  bool isLoggedIn = false;
  User currentUser;
  String onedevice = 'token of one device';
  String enddevice = 'token of end device';

  @override
  void initState() {
    super.initState();
   
    // initfcm();
    isSignedIn();
  }

  // void initfcm() async {
  //   _firebaseMessaging.configure(
  //     onMessage: (Map<String, dynamic> message) async {
  //       print("onMessage: $message");
  //     },
  //   );
  // }

  void isSignedIn() async {
    this.setState(() {
      isLoading = false;
    });
    preferences = await SharedPreferences.getInstance();

    isLoggedIn = await googleSignIn.isSignedIn();
    if (isLoggedIn) {
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    currentUserId: preferences.getString('id'),
                  )));
    }
    this.setState(() {
      isLoading = false;
    });
  }

  //sign in function
  Future<Null> signin() async {
    preferences = await SharedPreferences.getInstance();
    this.setState(() {
      isLoading = true;
    });
    GoogleSignInAccount googleUser = await googleSignIn.signIn();
    GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken, accessToken: googleAuth.accessToken);
    User firebaseUser =
        (await firebaseAuth.signInWithCredential(credential)).user;

    if (firebaseUser != null) {
      //check if already signed up
      final QuerySnapshot result = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: firebaseUser.uid)
          .get();
      final List<DocumentSnapshot> documents = result.docs;
      if (documents.length == 0) {
        //update data to server if new user
        FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .set({
          'nickname': firebaseUser.displayName,
          'photourl': firebaseUser.photoURL,
          'id': firebaseUser.uid,
          'createdat': DateTime.now().millisecondsSinceEpoch.toString(),
          'chattingwith': null,
          'devtoken': null,
        });
        _firebaseMessaging.getToken().then((val) {
          FirebaseFirestore.instance
              .collection('users')
              .doc(firebaseUser.uid)
              .update({
            'devtoken': val,
          });
          print('Token for this user: ' + val);
        });
        //write data to local
        currentUser = firebaseUser;
        await preferences.setString('id', currentUser.uid);

        await preferences.setString('nickname', currentUser.displayName);

        await preferences.setString('photourl', currentUser.photoURL);
      } else {
        //write data to local
        await preferences.setString('id', documents[0].data()['id']);

        await preferences.setString(
            'nickname', documents[0].data()['nickname']);

        await preferences.setString(
            'photourl', documents[0].data()['photourl']);

        await preferences.setString('aboutme', documents[0].data()['aboutme']);
      }
      Fluttertoast.showToast(msg: 'Sign in success');
      this.setState(() {
        isLoading = false;
      });
      Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => HomeScreen(
                    currentUserId: preferences.getString('id'),
                  )));
    } else {
      Fluttertoast.showToast(msg: 'Signin failed');
      this.setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var width = MediaQuery.of(context).size.width / 100;
    var height = MediaQuery.of(context).size.height / 100;
    return Scaffold(
      appBar: AppBar(
        title: Text('CHAT DEMO'),
      ),
      body: Stack(
        children: <Widget>[
          Center(
            child: RaisedButton(
              splashColor: Colors.transparent,
              onPressed: signin,
              child: Text(
                'Sign In with google',
                style: TextStyle(fontSize: width * 5),
              ),
              color: Colors.orangeAccent,
            ),
          ),
          //loading
          Positioned(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(),
                  )
                : Container(),
          ),
        ],
      ),
    );
  }
}
