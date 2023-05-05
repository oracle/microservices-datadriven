// Copyright (c) 2023, Oracle and/or its affiliates. 
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/ 

import 'credentials.dart';

class AccountDetailArguments {
  final Credentials creds;
  final int accountId;

  AccountDetailArguments(this.creds, this.accountId);
}
