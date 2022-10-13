// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import AsyncStorage from '@react-native-async-storage/async-storage';

//
// these are common functions that are used by a number of components
// they generally retrieve various data from the backend
//

// get the account history, i.e. transaction list for the given account
export const getHistory = async (parseAddress, accountNum) => {
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';

  const params = {accountNum: accountNum};
  const history = await Parse.Cloud.run('history', params);
  return history;
};

// get the account type for the given account, e.g. Checking, Savings, etc.
export const getAccountType = async (parseAddress, accountNum) => {
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';
  const params = {accountNum: accountNum};
  const accountType = await Parse.Cloud.run(
    'getaccounttypeforaccountnum',
    params,
  );
  return accountType;
};

// get a list of accounts for the given user
export const getAccounts = async (parseAddress, user) => {
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';

  const params = {userId: user};
  const accounts = await Parse.Cloud.run('getaccountsforuser', params);
  return accounts;
};

// get the balance of the given account
export const getAccountBalance = async (parseAddress, accountNum) => {
  if (parseAddress.length < 1) {
    return;
  }
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';
  const params = {accountNum: accountNum};
  const balance = await Parse.Cloud.run('balance', params);
  return balance;
};
