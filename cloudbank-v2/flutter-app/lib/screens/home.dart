import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loginapp/components/appbar.dart';
import 'package:loginapp/components/myaccounts.dart';
import 'package:loginapp/components/mycreditcards.dart';
import 'package:loginapp/components/bottombuttonbar.dart';

import '../components/credentials.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    final creds = ModalRoute.of(context)!.settings.arguments as Credentials;
    print(creds.username);
    print(creds.email);
    return Scaffold(
        appBar: CloudBankAppBar(),
        body: Center(
          child: ListView(
            padding: const EdgeInsets.all(10),
            children: [
              const SizedBox(height: 8),
              MyAccounts(
                creds: creds,
              ),
              const SizedBox(height: 8),
              const MyCreditCards(),
              const SizedBox(height: 20),
              // --------------------
              const Text(
                'What else can I do?',
                textScaleFactor: 2,
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              const SizedBox(height: 16),
              Card(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    ListTile(
                      leading: const Icon(Icons.wallet),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          Text('Apply for a Credit Card'),
                        ],
                      ),
                      subtitle: const Text(
                          'We have several cards to suit your needs'),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: <Widget>[
                        TextButton(
                          child: const Text('APPLY NOW'),
                          onPressed: () => GoRouter.of(context).go('/applycc'),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(
                height: 10,
              ),
              // ADD CLOUD CASH CARD HERE
              const SizedBox(
                height: 20,
              ),
              // --------------------
              const BottomButtonBar(),
            ],
          ),
        ));
  }
}
