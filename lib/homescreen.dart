import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demok/chat.dart';
import 'package:demok/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class HomeScreen extends StatefulWidget {
  final String currentUserId;
  HomeScreen({this.currentUserId});
  @override
  _HomeScreenState createState() =>
      _HomeScreenState(currentUserId: currentUserId);
}

class _HomeScreenState extends State<HomeScreen> {
  final String currentUserId;
  _HomeScreenState({this.currentUserId});

  final GoogleSignIn googleSignIn = GoogleSignIn();

  bool isLoading = false;

  Future<Null> handleSignOut() async {
    this.setState(() {
      isLoading = true;
    });

    await FirebaseAuth.instance.signOut();
    await googleSignIn.disconnect();
    await googleSignIn.signOut();

    this.setState(() {
      isLoading = false;
    });

    Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MyApp()),
        (Route<dynamic> route) => false);
  }

  Widget buildItem(BuildContext context, DocumentSnapshot document) {
    if (document.data()['id'] == currentUserId) {
      return Container();
    } else {
      return Container(
        child: FlatButton(
          child: Row(
            children: <Widget>[
              Material(
                child: document.data()['photourl'] != null
                    ? CachedNetworkImage(
                        imageUrl: document.data()['photourl'],
                        placeholder: (context, url) => Container(
                          child: CircularProgressIndicator(),
                          width: 50,
                          height: 50,
                          padding: EdgeInsets.all(15),
                        ),
                        fit: BoxFit.cover,
                      )
                    : Icon(
                        Icons.account_circle,
                        size: 50,
                        color: Colors.grey,
                      ),
                borderRadius: BorderRadius.circular(25),
                clipBehavior: Clip.hardEdge,
              ),
              Flexible(
                child: Container(
                  child: Column(
                    children: <Widget>[
                      Container(
                        child: Text(
                          'Nickname : ${document.data()['nickname']}',
                        ),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10, 0, 0, 5),
                      ),
                      Container(
                        child: Text(
                            'About me: ${document.data()['aboutme'] ?? 'Not Available'}'),
                        alignment: Alignment.centerLeft,
                        margin: EdgeInsets.fromLTRB(10, 0, 0, 0),
                      ),
                    ],
                  ),
                  margin: EdgeInsets.only(left: 20),
                ),
              ),
            ],
          ),
          onPressed: () {
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => Chat(
                        peerId: document.data()['id'],
                        peerToken: document.data()['devtoken'],
                        peerAvatar: document.data()['photourl'])));
          },
          color: Colors.grey,
          padding: EdgeInsets.fromLTRB(25, 10, 25, 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        margin: EdgeInsets.only(bottom: 10, left: 5, right: 5),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Main'),
        centerTitle: true,
        actions: <Widget>[
          IconButton(icon: Icon(Icons.exit_to_app), onPressed: handleSignOut),
        ],
      ),
      body: Stack(
        children: <Widget>[
          //list
          Container(
            child: StreamBuilder(
              stream:
                  FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                } else {
                  return ListView.builder(
                    itemBuilder: (context, index) =>
                        buildItem(context, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                  );
                }
              },
            ),
          ),
          //loading
          Positioned(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Container())
        ],
      ),
    );
  }
}
