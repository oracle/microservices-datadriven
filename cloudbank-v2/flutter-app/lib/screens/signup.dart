import 'package:flutter/material.dart';
import 'package:loginapp/screens/home.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';

import '../components/credentials.dart';

class SignUp extends StatefulWidget {
  final String backendUrl;
  const SignUp({Key? key, required this.backendUrl}) : super(key: key);

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  @override
  void initState() {
    super.initState();
  }

  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController emailController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Account SignUp")),
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: usernameController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Name',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: passwordController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Password',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    controller: emailController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'User Email',
                    ),
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(
                      child: const Text('Create Account'),
                      onPressed: () {
                        print(
                            "Controller user name = ${usernameController.text}");
                        print(
                            "Controller password = ${passwordController.text}");
                        print("Controller password = ${emailController.text}");
                        processSignUp(context, usernameController.text,
                            passwordController.text, emailController.text);
                      },
                    )),
              ],
            )),
      ),
    );
  }

  processSignUp(context, username, password, email) async {
    print("processSignUp name = $username");
    print("processSignUp password = $password");
    print("processSignUp email = $email");
    var user = ParseUser(username, password, "");
    var response = await ParseUser(username, password, email).create();
    if (response.success) {
      user = response.result;
      print("user = $user");
      Credentials creds = Credentials(
          user.username.toString(),
          user.emailAddress.toString(),
          user.objectId.toString(),
          widget.backendUrl);
      print(creds);
      // set up the button
      Widget okButton = TextButton(
          child: const Text("OK"),
          onPressed: () {
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
          });
      // set up the AlertDialog
      AlertDialog alert = AlertDialog(
        title: const Text("Success"),
        content: const Text("Account successfully created"),
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
