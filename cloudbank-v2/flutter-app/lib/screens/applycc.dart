import 'package:flutter/material.dart';
import 'package:parse_server_sdk_flutter/parse_server_sdk.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreditScore {
  final String date;
  final String score;

  const CreditScore({
    required this.date,
    required this.score,
  });

  factory CreditScore.fromJson(Map<String, dynamic> json) {
    return CreditScore(
      date: json['Date'],
      score: json['Credit Score'],
    );
  }
}

class ApplyForCreditCard extends StatefulWidget {
  const ApplyForCreditCard({Key? key}) : super(key: key);

  @override
  State<ApplyForCreditCard> createState() => _ApplyForCreditCardState();
}

const List<String> cardTypeList = <String>[
  'Cloud Credit',
  'Cloud Credit Gold',
  'Cloud Credit Diamond'
];

class _ApplyForCreditCardState extends State<ApplyForCreditCard> {
  late Future<CreditScore> futureCreditScore;

  @override
  void initState() {
    super.initState();
    futureCreditScore = fetchCreditScore();
  }

  Future<CreditScore> fetchCreditScore() async {
    final response =
        await http.get(Uri.parse('http://129.158.244.40/api/v1/creditscore'));

    if (response.statusCode == 200) {
      // If the server did return a 200 OK response,
      // then parse the JSON.
      return CreditScore.fromJson(jsonDecode(response.body));
    } else {
      // If the server did not return a 200 OK response,
      // then throw an exception.
      throw Exception('Failed to retrieve score');
    }
  }

  TextEditingController incomeController = TextEditingController();
  TextEditingController expensesController = TextEditingController();
  TextEditingController limitController = TextEditingController();
  String cardTypeDropdownValue = cardTypeList.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Apply for Credit Card")),
      body: Center(
        child: Container(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: <Widget>[
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      'Which card would you like?',
                      style: TextStyle(fontSize: 20),
                    )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: DropdownButton<String>(
                    value: cardTypeDropdownValue,
                    icon: const Icon(Icons.arrow_drop_down),
                    isExpanded: true,
                    elevation: 16,
                    style: const TextStyle(color: Colors.deepPurple),
                    underline: Container(
                      height: 2,
                      color: Colors.deepPurpleAccent,
                    ),
                    onChanged: (String? value) {
                      setState(() {
                        cardTypeDropdownValue = value!;
                      });
                    },
                    items: cardTypeList
                        .map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: limitController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Requested credit limit',
                    ),
                  ),
                ),
                Container(
                    alignment: Alignment.center,
                    padding: const EdgeInsets.all(10),
                    child: const Text(
                      'About you',
                      style: TextStyle(fontSize: 20),
                    )),
                Container(
                  padding: const EdgeInsets.all(10),
                  child: TextField(
                    controller: incomeController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Monthly income before tax',
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: TextField(
                    controller: expensesController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Monthly expenses',
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: FutureBuilder<CreditScore>(
                    future: futureCreditScore,
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Text(
                            "Your credit score: ${snapshot.data!.score}");
                      } else if (snapshot.hasError) {
                        return Text('${snapshot.error}');
                      }
                      // By default, show a loading spinner.
                      return const CircularProgressIndicator();
                    },
                  ),
                ),
                const SizedBox(
                  height: 20,
                ),
                Container(
                    height: 50,
                    padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                    child: ElevatedButton(
                      child: const Text('Submit Application'),
                      onPressed: () {
                        print("Controller name = ${incomeController.text}");
                        print(
                            "Controller password = ${expensesController.text}");
                        processCCApplication(
                            context,
                            incomeController.text,
                            expensesController.text,
                            cardTypeDropdownValue,
                            limitController.text);
                      },
                    )),
              ],
            )),
      ),
    );
  }

  processCCApplication(context, income, expenses, cardType, limit) async {
    print("processCCApplication income = $income");
    print("processCCApplication expenses = $expenses");
    print("processCCApplication cardType = $cardType");
    print("processCCApplication limit = $limit");
    var application = ParseObject("CCApplication");
    application.set("income", income);
    application.set("expenses", expenses);
    application.set("cardType", cardType);
    application.set("limit", limit);
    var response = await application.save();

    print("saved = $response");
    // set up the button
    Widget okButton = TextButton(
      child: const Text("OK"),
      onPressed: () => GoRouter.of(context).go('/home'),
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Application submitted"),
      icon: Icon(Icons.account_balance_rounded),
      content: const Text(
          "Thanks for your application!  We'll get back to you as soon as we can."),
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
