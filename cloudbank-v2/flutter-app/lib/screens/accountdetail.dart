import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../components/credentials.dart';
import 'home.dart';

class AccountDetail extends StatefulWidget {
  const AccountDetail({Key? key}) : super(key: key);

  @override
  State<AccountDetail> createState() => _AccountDetailState();
}

class _AccountDetailState extends State<AccountDetail> {
  @override
  Widget build(BuildContext context) {
    final creds = ModalRoute.of(context)!.settings.arguments as Credentials;
    print(creds.username);
    print(creds.email);
    return Scaffold(
      appBar: AppBar(title: const Text("Account Detail")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text(
                'Account detail and transaction list goes here',
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Home(),
                      // Pass the arguments as part of the RouteSettings. The
                      // DetailScreen reads the arguments from these settings.
                      settings: RouteSettings(
                        arguments: creds,
                      ),
                    ),
                  );
                },
                //=> GoRouter.of(context).go('/home'),
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
