// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'package:flutter/material.dart';

class CloudBankAppBar extends StatefulWidget implements PreferredSizeWidget {
  CloudBankAppBar({Key? key})
      : preferredSize = const Size.fromHeight(kToolbarHeight),
        super(key: key);

  @override
  final Size preferredSize; // default is 56.0

  @override
  _CloudBankAppBarState createState() => _CloudBankAppBarState();
}

class _CloudBankAppBarState extends State<CloudBankAppBar> {
  static const String _title = 'Cloud Bank';

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text(_title),
    );
  }
}
