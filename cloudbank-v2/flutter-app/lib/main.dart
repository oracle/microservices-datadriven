// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

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

const String backendUrl = 'http://1.2.3.4';

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
      path: '/applycc',
      builder: (context, state) => const ApplyForCreditCard(),
    ),
  ],
);

void main() async {
  // Initialize Parse
  WidgetsFlutterBinding.ensureInitialized();
  const keyApplicationId = 'M023';
  const keyParseServerUrl = '$backendUrl/parse';

  var response = await Parse().initialize(keyApplicationId, keyParseServerUrl);
  if (!response.hasParseBeenInitialized()) {
    exit(0);
  }
  var firstObject = ParseObject('FirstClass')
    ..set('message', 'LoginApp is Connected 3');
  await firstObject.save();
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
