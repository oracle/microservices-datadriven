// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:loginapp/components/accountdetailarguments.dart';

import '../components/credentials.dart';
import 'home.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

final formatCurrency = new NumberFormat.simpleCurrency();

class AccountDetail extends StatefulWidget {
  final AccountDetailArguments args;

  const AccountDetail({Key? key, required this.args}) : super(key: key);

  @override
  State<AccountDetail> createState() => _AccountDetailState();
}

class Account {
  // {"accountId":2,"accountName":"Mark's CCard","accountType":"CC","accountCustomerId":"bkzLp8cozi",
  //"accountOpenedDate":"2023-03-12T16:06:03.000+00:00","accountOtherDetails":"Mastercard account",
  //"accountBalance":800}
  final int accountId;
  final String accountName;
  final String accountType;
  final String accountCustomerId;
  final String accountOpenedDate;
  final String accountOtherDetails;
  final double accountBalance;

  const Account({
    required this.accountId,
    required this.accountName,
    required this.accountType,
    required this.accountCustomerId,
    required this.accountOpenedDate,
    required this.accountOtherDetails,
    required this.accountBalance,
  });

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      accountId: json['accountId'],
      accountName: json['accountName'],
      accountType: json['accountType'],
      accountCustomerId: json['accountCustomerId'],
      accountOpenedDate: json['accountOpenedDate'],
      accountOtherDetails: json['accountOtherDetails'],
      accountBalance: double.parse(json['accountBalance'].toString()),
    );
  }
}

class Transactions {
  final List<dynamic> transactions;

  const Transactions({
    required this.transactions,
  });

  List getTransactions() {
    return transactions;
  }

  factory Transactions.fromJson({required transactions}) {
    return Transactions(
      transactions: transactions,
    );
  }
}

class _AccountDetailState extends State<AccountDetail> {
  late Future<Account> futureAccountData;
  late Future<Transactions> futureTransactionData;

  @override
  void initState() {
    super.initState();
    futureAccountData = fetchAccountData();
    futureTransactionData = fetchTransactionData();
  }

  Future<Account> fetchAccountData() async {
    String accountsUrl =
        '${widget.args.creds.backendUrl}/api/v1/account/${widget.args.accountId}';
    final response = await http.get(Uri.parse(accountsUrl));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Account.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to retrieve score');
    }
  }

  Future<Transactions> fetchTransactionData() async {
    String transcationsUrl =
        '${widget.args.creds.backendUrl}/api/v1/account/${widget.args.accountId}/transactions';
    final response = await http.get(Uri.parse(transcationsUrl));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return Transactions.fromJson(transactions: jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to retrieve score');
    }
  }

  @override
  Widget build(BuildContext context) {
    // final args =
    //     ModalRoute.of(context)!.settings.arguments as AccountDetailArguments;
    print(widget.args.creds.username);
    print(widget.args.creds.email);
    print(widget.args.accountId);
    return Scaffold(
      appBar: AppBar(title: const Text("Your Transactions")),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: ListView(
            children: [
              const Text("Account Details", textScaleFactor: 1.5),
              FutureBuilder<Account>(
                future: futureAccountData,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    print(snapshot.data);
                    return Card(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          ListTile(
                            title: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(snapshot.data!.accountName),
                                Text(
                                  formatCurrency
                                      .format(snapshot.data!.accountBalance),
                                  textScaleFactor: 1.5,
                                ),
                              ],
                            ),
                            subtitle:
                                Text("CB ACCT-${snapshot.data!.accountId}"),
                          ),
                        ],
                      ),
                    );
                  } else if (snapshot.hasError) {
                    return Text('${snapshot.error}');
                  }
                  // By default, show a loading spinner.
                  return const Text("Loading...");
                },
              ),
              const SizedBox(height: 20),
              const Text("Recent Transactions", textScaleFactor: 1.5),
              const SizedBox(height: 20),
              FutureBuilder<Transactions>(
                future: futureTransactionData,
                builder: (context, snapshot) {
                  // {"journalId":3,
                  // "journalType":"WITHDRAW",
                  // "accountId":2,
                  // "lraId":"http://otmm-tcs.otmm.svc.cluster.local:9000/api/v1/lra-coordinator/144d7ad8-653e-4540-987c-cc2fcf0643e0",
                  // "lraState":"Closed",
                  // "journalAmount":100}
                  if (snapshot.hasData) {
                    print(snapshot.data!.transactions.length);
                    List<dynamic> data = snapshot.data!.transactions;
                    print(data);
                    return ListView.builder(
                      scrollDirection: Axis.vertical,
                      shrinkWrap: true,
                      physics: const ClampingScrollPhysics(),
                      itemCount: snapshot.data!.transactions.length,
                      itemBuilder: (context, index) {
                        return Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              ListTile(
                                leading: const Icon(Icons.attach_money),
                                title: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(data[index]['journalType'].toString()),
                                    Text(
                                      formatCurrency
                                          .format(data[index]['journalAmount']),
                                      textScaleFactor: 1.5,
                                    ),
                                  ],
                                ),
                                subtitle: Text(data[index]['lraState']),
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
                        arguments: widget.args.creds,
                      ),
                    ),
                  );
                },
                //=> GoRouter.of(context).go('/home'),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Account List'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
