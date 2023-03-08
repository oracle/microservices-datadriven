import 'package:flutter/material.dart';
import 'package:loginapp/components/credentials.dart';
import 'package:loginapp/screens/accountdetail.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class Accounts {
  final List<dynamic> accounts;

  const Accounts({
    required this.accounts,
  });

  List getAccounts() {
    return accounts;
  }

  factory Accounts.fromJson({required accounts}) {
    return Accounts(
      accounts: accounts,
    );
  }
}

class MyAccounts extends StatefulWidget {
  final Credentials creds;

  const MyAccounts({Key? key, required this.creds}) : super(key: key);

  @override
  State<MyAccounts> createState() => _MyAccountsState();
}

class _MyAccountsState extends State<MyAccounts> {
  late Future<Accounts> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<Accounts> fetchData() async {
    String accountsUrl =
        '${widget.creds.backendUrl}/api/v1/account/getAccounts/${widget.creds.objectID}';
    final response = await http.get(Uri.parse(accountsUrl));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      var accounts = jsonDecode(response.body);
      print(accounts);
      return Accounts.fromJson(accounts: accounts);
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to retrieve Account List');
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget accountsSection = Container(
      child: Column(
        children: [
          FutureBuilder<Accounts>(
            future: futureData,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                print(snapshot.data!.accounts.length);
                List<dynamic> data = snapshot.data!.accounts;
                print(data);
                return ListView.builder(
                  scrollDirection: Axis.vertical,
                  shrinkWrap: true,
                  physics: const ClampingScrollPhysics(),
                  itemCount: snapshot.data!.accounts.length,
                  itemBuilder: (context, index) {
                    return Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            leading: const Icon(Icons.attach_money),
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(data[index]['accountName'].toString()),
                                Text(
                                  data[index]['accountBalance'].toString(),
                                  textScaleFactor: 1.5,
                                ),
                              ],
                            ),
                            subtitle: Text(data[index]['accountId'].toString()),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: <Widget>[
                              TextButton(
                                  child: const Text('TRANSACTIONS'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AccountDetail(),
                                        // Pass the arguments as part of the RouteSettings. The
                                        // DetailScreen reads the arguments from these settings.
                                        settings: RouteSettings(
                                          arguments: widget.creds,
                                        ),
                                      ),
                                    );
                                  }),
                              const SizedBox(width: 8),
                              TextButton(
                                child: const Text('PAY'),
                                onPressed: () {/* ... */},
                              ),
                              const SizedBox(width: 8),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              } else if (snapshot.hasError) {
                return Text('${snapshot.error}');
              }
              // By default, show a loading spinner.
              return const CircularProgressIndicator();
            },
          )
        ],
      ),
    );

    print(widget.creds);
    return Wrap(
      children: <Widget>[
        const Text(
          'My Accounts',
          textScaleFactor: 2,
        ),
        const SizedBox(height: 20),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            accountsSection,
          ],
        ),
      ],
    );
  }
}
