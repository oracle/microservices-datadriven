// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MyCreditCards extends StatelessWidget {
  const MyCreditCards({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Wrap(
      children: <Widget>[
        const Text(
          'My Credit Cards',
          textScaleFactor: 2,
        ),
        const SizedBox(height: 20),
        Card(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.credit_card),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('Cloud Credit Gold'),
                    Text(
                      '\$6,123',
                      textScaleFactor: 1.5,
                    ),
                  ],
                ),
                subtitle: const Text(
                    '4545-0101-0202-0345\nNext payment due: March 15'),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    child: const Text('TRANSACTIONS'),
                    onPressed: () => GoRouter.of(context).go('/accountdetail'),
                  ),
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
        ),
      ],
    );
  }
}
