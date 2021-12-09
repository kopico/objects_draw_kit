import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' show User;

class AccountPage extends StatefulWidget {
  final User user;
  const AccountPage(this.user, {Key? key}) : super(key: key);

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double appBarHeight = 40;
    return Container(
      width: screenWidth,
      height: screenHeight,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: screenWidth,
            height: appBarHeight,
            child: AppBar(
              title: const Text("Objects Draw Kit - My Account"),
              leading: MaterialButton(
                  onPressed: (){
                    Navigator.pop(context);
                  },
                  child: const SizedBox(
                    width: 40,
                    height: 40,
                    child: Icon(Icons.arrow_back, size: 24, color: Colors.white),
                  )
              ),
              actions: [],
            ),
          ),
          const SizedBox(
            height: 20,
          ),
          Material(
            elevation: 10.0,
            child: Container(
                width: screenWidth / 2,
                height: screenHeight - appBarHeight - 50,
                padding: const EdgeInsets.symmetric(vertical: 20),
                alignment: Alignment.center,
                decoration: ShapeDecoration(
                  shape:  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6.0),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SizedBox(
                      height: 50,
                    ),
                  ],
                )
            ),
          )
        ],
      ),
    );
  }
}
