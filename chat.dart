import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Chat extends StatelessWidget {
  final String peerId;
  final String peerToken;
  final String peerAvatar;
  Chat({this.peerAvatar, this.peerToken, this.peerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('CHAT'),
        centerTitle: true,
      ),
      body: ChatScreen(
          peerId: peerId, peerAvatar: peerAvatar, peerToken: peerToken),
    );
  }
}

class ChatScreen extends StatefulWidget {
  final String peerId;
  final String peerAvatar;
  final String peerToken;
  ChatScreen({this.peerAvatar, this.peerToken, this.peerId});

  @override
  _ChatScreenState createState() => _ChatScreenState(
      peerId: peerId, peerAvatar: peerAvatar, peerToken: peerToken);
}

Future<dynamic> myBackgroundMessageHandler(Map<String, dynamic> message) async {
  if (message.containsKey('data')) {
    // Handle data message
    final dynamic data = message['data'];
  }

  if (message.containsKey('notification')) {
    // Handle notification message
    final dynamic notification = message['notification'];
  }

  // Or do other work.
}

class _ChatScreenState extends State<ChatScreen> {
  _ChatScreenState({this.peerAvatar, this.peerId, this.peerToken});

  String peerId;
  String peerAvatar;
  String id;
  String peerToken;

  List<DocumentSnapshot> listMessage = List.from([]);
  int _limit = 20;
  final int _limitIncrement = 20;

  String groupChatId;
  SharedPreferences prefs;

  bool isLoading;
  String imageUrl;
  TextEditingController textEditingController = TextEditingController();
  final ScrollController listScrollcontroller = ScrollController();
  final FocusNode focusNode = FocusNode();
  // final FirebaseMessaging _firebaseMessaging = FirebaseMessaging();
  final FirebaseMessaging firebaseMessaging = FirebaseMessaging();

  

   final String serverToken = 'my server token';

  _scrollListener() {
    if (listScrollcontroller.offset >=
            listScrollcontroller.position.maxScrollExtent &&
        !listScrollcontroller.position.outOfRange) {
      print('reached the bottom');
      setState(() {
        print('reached the bottom2');
        _limit += _limitIncrement;
      });
    }
    if (listScrollcontroller.offset <=
            listScrollcontroller.position.minScrollExtent &&
        !listScrollcontroller.position.outOfRange) {
      print('reached the top');
      setState(() {
        print('reached the top2');
      });
    }
  }

  @override
  void initState() {
    super.initState();
    if (Platform.isIOS) {
      firebaseMessaging
          .requestNotificationPermissions(IosNotificationSettings());
    }
    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        print("onMessage: $message");
      },
      onBackgroundMessage: myBackgroundMessageHandler,
    );
    focusNode.addListener(onFocusChange);
    listScrollcontroller.addListener(_scrollListener);

    groupChatId = '';
    isLoading = false;
    imageUrl = '';
    readLocal();
  }

  Future<Map<String, dynamic>> sendAndRetrieveMessage(String peertoken) async {
    // await firebaseMessaging.requestNotificationPermissions(
    //   const IosNotificationSettings(
    //       sound: true, badge: true, alert: true, provisional: false),
    // );

    await http.post(
      'https://fcm.googleapis.com/fcm/send',
      headers: <String, String>{
        'Content-Type': 'application/json',
        'Authorization': 'key=$serverToken',
      },
      body: jsonEncode(
        <String, dynamic>{
          'notification': <String, dynamic>{
            'body': 'hey',
            'title': 'Demoktestingpush'
          },
          'priority': 'high',
          'data': <String, dynamic>{
            'body': 'hey',
            'title': 'Demoktestingpush',
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'id': '1',
            'status': 'done'
          },
          'to': peertoken,
        },
      ),
    );
    textEditingController.text = '';
    final Completer<Map<String, dynamic>> completer =
        Completer<Map<String, dynamic>>();

    firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        completer.complete(message);
      },
    );

    return completer.future;
  }

  void onFocusChange() {
    if (focusNode.hasFocus) {
      //hide sticker when keyboard appears
      setState(() {});
    }
  }

  readLocal() async {
    prefs = await SharedPreferences.getInstance();
    id = prefs.getString('id') ?? '';
    if (id.hashCode <= peerId.hashCode) {
      groupChatId = '$id-$peerId';
    } else {
      groupChatId = '$peerId-$id';
    }
    FirebaseFirestore.instance.collection('users').doc(id).update({
      'chattingwith': peerId,
    });
    setState(() {});
  }

  void onSendMessage(String msg) {
    if (msg.trim() != '') {
      textEditingController.clear();
      var docref = FirebaseFirestore.instance
          .collection('messages')
          .doc(groupChatId)
          .collection(groupChatId)
          .doc(
            DateTime.now().millisecondsSinceEpoch.toString(),
          );

      FirebaseFirestore.instance.runTransaction((transaction) async {
        transaction.set(docref, {
          'idFrom': id,
          'idTo': peerId,
          'timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
          'msg': msg,
          'isseen': false,
          'toToken': peerToken,
        });
      });

      listScrollcontroller.animateTo(0,
          duration: Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      Fluttertoast.showToast(
        msg: 'Nothing to send',
      );
    }
  }

  // Future<bool> delete() async {
  //   var docs = await Firestore.instance
  //       .collection('messages')
  //       .document(groupChatId)
  //       .collection(groupChatId)
  //       .getDocuments();
  //   docs.documents.removeLast();
  //   Navigator.pop(context);
  // }

//build message item/container...
  Widget buildItem(
    int index,
    DocumentSnapshot document,
  ) {
    if (document.data()['idFrom'] == id) {
      //Right (my message)
      return Row(
        children: <Widget>[
          Container(
            child: Text(
              document.data()['msg'],
            ),
            padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
            width: 200,
            decoration: BoxDecoration(
                color: Colors.grey, borderRadius: BorderRadius.circular(8)),
            margin: EdgeInsets.only(
              bottom: isLastMessageRight(index) ? 20 : 10,
              right: 10,
            ),
          ),
          Container(child: Text(document.data()['isseen'] ? '' : 'Unseen'))
        ],
        mainAxisAlignment: MainAxisAlignment.end,
      );
    } else {
      //left peer message
      return Container(
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                isLastMessageLeft(index)
                    ? Material(
                        child: CachedNetworkImage(
                          imageUrl: peerAvatar,
                          placeholder: (context, url) => Container(
                            child: CircularProgressIndicator(),
                            width: 35,
                            height: 35,
                            padding: EdgeInsets.all(10),
                          ),
                          width: 35,
                          height: 35,
                          fit: BoxFit.cover,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        clipBehavior: Clip.hardEdge,
                      )
                    : Container(
                        width: 35,
                      ),
                Container(
                  child: Text(document.data()['msg']),
                  padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                  width: 200,
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(8)),
                  margin: EdgeInsets.only(left: 10),
                )
              ],
            ),
            //time
            isLastMessageLeft(index)
                ? Container(
                    child: Text(
                      DateFormat('dd MMMM kk:mm').format(
                        DateTime.fromMillisecondsSinceEpoch(
                          int.parse(
                            document.data()['timestamp'],
                          ),
                        ),
                      ),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                          fontStyle: FontStyle.italic),
                    ),
                  )
                : Container()
          ],
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
        margin: EdgeInsets.only(bottom: 10),
      );
    }
  }

  bool isLastMessageLeft(int index) {
    if (index > 0 &&
            listMessage != null &&
            listMessage[index - 1].data()['idFrom'] == id ||
        index == 0) {
      return true;
    } else {
      return false;
    }
  }

  bool isLastMessageRight(int index) {
    if ((index > 0 &&
            listMessage != null &&
            listMessage[index - 1].data()['idFrom'] != id ||
        index == 0)) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> onBackPress() {
    FirebaseFirestore.instance
        .collection('users')
        .doc(id)
        .update({'chattingwith': null});
    Navigator.pop(context);
  }

  Widget buildInput() {
    return Container(
      child: Row(
        children: <Widget>[
          // Button send image
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(icon: Icon(Icons.image), onPressed: () {}),
            ),
            color: Colors.white,
          ),
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 1.0),
              child: IconButton(icon: Icon(Icons.face), onPressed: () {}),
            ),
            color: Colors.white,
          ),

          // Edit text
          Flexible(
            child: Container(
              child: TextField(
                onSubmitted: (value) {
                  sendAndRetrieveMessage(peerToken);
                  // onSendMessage(
                  //   textEditingController.text,
                  // );
                },
                style: TextStyle(fontSize: 15.0),
                controller: textEditingController,
                decoration: InputDecoration.collapsed(
                  hintText: 'Type your message...',
                ),
                focusNode: focusNode,
              ),
            ),
          ),

          // Button send message
          Material(
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.0),
              child: IconButton(
                  icon: Icon(Icons.send),
                  onPressed: () => sendAndRetrieveMessage(peerToken)),
            ),
            color: Colors.white,
          ),
        ],
      ),
      width: double.infinity,
      height: 50.0,
      decoration: BoxDecoration(
          border: Border(top: BorderSide(width: 0.5)), color: Colors.white),
    );
  }

  // void deletemessage(DocumentSnapshot snapshot, DocumentReference dr) async {
  //   if(snapshot.data['idFrom']==id && snapshot.data['isseen']==false) {
  //     Firestore.instance.runTransaction((Transaction transaction) async {
  //         await transaction.update(dr, {'msg' : 'This message has been deleted'});
  //     });

  //   }
  // }

  Widget buildListMessage() {
    return Flexible(
      child: groupChatId == ''
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder(
              stream: FirebaseFirestore.instance
                  .collection('messages')
                  .doc(groupChatId)
                  .collection(groupChatId)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                } else {
                  for (var data in snapshot.data.documents) {
                    if (data['idTo'] == id && data['isseen'] == false) {
                      if (data.reference != null) {
                        FirebaseFirestore.instance
                            .runTransaction((Transaction myTransaction) async {
                          await myTransaction
                              .update(data.reference, {'isseen': true});
                        });
                      }
                    }
                  }
                  Timer(Duration(hours: 12), () {
                    for (var data in snapshot.data.documents) {
                      if (data['idFrom'] == id && data['isseen'] == true) {
                        if (data.reference != null) {
                          FirebaseFirestore.instance.runTransaction(
                              (Transaction myTransaction) async {
                            await myTransaction.delete(data.reference);
                          });
                        }
                      }
                    }
                  });

                  listMessage.addAll(snapshot.data.documents);
                  return ListView.builder(
                    padding: EdgeInsets.all(10.0),
                    itemBuilder: (context, index) =>
                        buildItem(index, snapshot.data.documents[index]),
                    itemCount: snapshot.data.documents.length,
                    reverse: true,
                    controller: listScrollcontroller,
                  );
                }
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: onBackPress,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Container(
                margin: EdgeInsets.only(top: 10),
                width: 180,
                alignment: Alignment.center,
                padding: EdgeInsets.all(5),
                decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('seen messages will disappear after 12 hours',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
              //list of messages
              buildListMessage(),
              buildInput(),
              // Center(child: CircularProgressIndicator()),
            ],
          )
        ],
      ),
    );
  }
}
