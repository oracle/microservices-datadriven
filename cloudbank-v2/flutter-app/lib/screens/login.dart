// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'package:flutter/material.dart';
import 'package:loginapp/components/appbar.dart';
import 'package:loginapp/screens/home.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:go_router/go_router.dart';

import '../components/credentials.dart';

class Login extends StatefulWidget {
  final String backendUrl;

  const Login({Key? key, required this.backendUrl}) : super(key: key);

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  TextEditingController nameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: CloudBankAppBar(),
        body: Padding(
            padding: const EdgeInsets.all(10),
            child: ListView(
              children: <Widget>[
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      'CloudBank',
                      style: TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                          fontSize: 30),
                    )),
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      'Sign in',
                      style: TextStyle(fontSize: 20),
                    )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    obscureText: true,
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Password',
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    //forgot password screen
                  },
                  child: const Text(
                    'Forgot Password',
                  ),
                ),
                Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(
                      child: const Text('Login'),
                      onPressed: () {
                        print("Controller name = ${nameController.text}");
                        print(
                            "Controller password = ${passwordController.text}");
                        processLogin(context, nameController.text,
                            passwordController.text);
                      },
                    )),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Text('Need an account?'),
                    TextButton(
                      child: const Text(
                        'Join us now',
                        //style: TextStyle(fontSize: 20),
                      ),
                      onPressed: () {
                        //signup screen
                        GoRouter.of(context).go('/signup');
                      },
                    )
                  ],
                ),
              ],
            )));
  }

  processLogin(context, username, password) async {
    print("processLogin name = $username");
    print("processLogin password = $password");
    var user = ParseUser(username, password, "");
    var response = await user.login();
    if (response.success) {
      user = response.result;
      print("user = $user");
      Credentials creds = Credentials(
          user.username.toString(),
          user.emailAddress.toString(),
          user.objectId.toString(),
          widget.backendUrl);
      print(creds);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const Home(),
          // Pass the arguments as part of the RouteSettings.
          settings: RouteSettings(
            arguments: creds,
          ),
        ),
      );
    } else {
      // set up the button
      Widget okButton = TextButton(
        child: const Text("OK"),
        onPressed: () => Navigator.pop(context),
      );
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: const Text("Error Dialog"),
        content: Text('${response.error?.message}'),
        actions: [
          okButton,
        ],
      );

      // show the dialog
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return alert;
        },
      );
    }
  }
}
