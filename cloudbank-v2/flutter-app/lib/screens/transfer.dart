// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class Transfer extends StatefulWidget {
  const Transfer({Key? key}) : super(key: key);

  @override
  State<Transfer> createState() => _TransferState();
}

class _TransferState extends State<Transfer> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Transfer")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'To and from account chooser, amount, etc., goes here',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Roboto',
                  letterSpacing: 0.5,
                  fontSize: 20,
                ),
              ),
              const SizedBox(
                height: 20,
              ),
              ElevatedButton(
                onPressed: () => GoRouter.of(context).go('/home'),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Go back to Home'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
