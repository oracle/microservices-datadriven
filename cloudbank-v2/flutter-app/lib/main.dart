import 'dart:io';

import 'package:flutter/material.dart';
import 'package:loginapp/screens/accountdetail.dart';
import 'package:loginapp/screens/applycc.dart';
import 'package:loginapp/screens/deposit.dart';
import 'package:loginapp/screens/home.dart';
import 'package:loginapp/screens/login.dart';
import 'package:loginapp/screens/signup.dart';
import 'package:loginapp/screens/transfer.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:go_router/go_router.dart';

const String backendUrl = 'http://129.158.244.40';

// GoRouter configuration
final _router = GoRouter(
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const Login(
        backendUrl: backendUrl,
      ),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignUp(
        backendUrl: backendUrl,
      ),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const Home(),
    ),
    GoRoute(
      path: '/deposit',
      builder: (context, state) => const Deposit(),
    ),
    GoRoute(
      path: '/transfer',
      builder: (context, state) => const Transfer(),
    ),
    GoRoute(
      path: '/accountdetail',
      builder: (context, state) => const AccountDetail(),
    ),
    GoRoute(
      path: '/applycc',
      builder: (context, state) => const ApplyForCreditCard(),
    ),
  ],
);

void main() async {
//  Parse code
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'APPLICATION_ID';
  // WebLogicOnDocker Old Install
  const keyParseServerUrl = 'http://129.80.94.27/parse';
  // MaaCloud New Install  Not Working Yet, Parse Server Keep crashing
  // const keyParseServerUrl = 'http://129.159.115.55/parse';

  var response = await Parse().initialize(keyApplicationId, keyParseServerUrl);
  if (!response.hasParseBeenInitialized()) {
    // https://stackoverflow.com/questions/45109557/flutter-how-to-programmatically-exit-the-app
    exit(0);
  }
  var firstObject = ParseObject('FirstClass')
    ..set('message', 'LoginApp is Connected 2');
  await firstObject.save();

  print('done');
// Parse code done

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      routerConfig: _router,
    );
  }
}
