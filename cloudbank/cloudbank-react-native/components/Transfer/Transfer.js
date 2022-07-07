// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import {Picker} from '@react-native-picker/picker';
import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  ScrollView,
  TextInput,
  Button,
  Alert,
} from 'react-native';
import Card from '../UI/Card';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {getAccountType, getAccounts} from '../common/common';

// this function performs the actual transfer on the backend
const performTransfer = async (
  parseAddress,
  fromAccountNum,
  toAccountNum,
  amount,
  accountType,
) => {
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';

  const Transfer = Parse.Object.extend('BankAccount');
  const transfer = new Transfer();
  transfer.set('accountNum', +fromAccountNum);
  transfer.set('action', 'Transfer');
  transfer.set('amount', +amount);
  transfer.set('userId', 'mark');
  transfer.set('toAccountNum', +toAccountNum);
  transfer.set('accountType', accountType);
  transfer.save().then(
    id => console.log('saved with id ' + JSON.stringify(id)),
    error => console.log('failed to save, error = ' + error),
  );
};

const Transfer = props => {
  const [fromAccount, setFromAccount] = useState('');
  const [toAccount, setToAccount] = useState('');
  const [amount, setAmount] = useState('0.00');
  const [parseAddress, setParseAddress] = useState('');
  const [accounts, setAccounts] = useState([]);

  // hook to retreive the parse server address and store in local state
  useEffect(() => {
    AsyncStorage.getItem('serverAddress').then(storedAddress => {
      storedAddress && setParseAddress(storedAddress);
    });
  }, [parseAddress, setParseAddress]);

  // hook to get the user's account numbers and lookup the type for each
  // one and store this in local state - we use this in the picker
  useEffect(() => {
    AsyncStorage.getItem('serverAddress').then(address => {
      getAccounts(address, props.user).then(accountNumbers => {
        accountNumbers.forEach(item => {
          getAccountType(address, item)
            .then(type => {
              setAccounts(prev => [
                ...prev,
                {
                  accountNumber: item,
                  accountType: type,
                },
              ]);
              // make sure that the controlled state is initialized
              setFromAccount(item);
              setToAccount(item);
            })
            .catch(error => console.log(error));
        });
      });
    });
  }, [props.user]);

  const accountList =
    accounts.length !== 0 ? (
      accounts
        .sort((a, b) => +b.accountNumber - +a.accountNumber)
        .map(account => {
          return (
            <Picker.Item
              value={account.accountNumber}
              label={account.accountNumber + ' - ' + account.accountType}
            />
          );
        })
    ) : (
      <></>
    );

  const transferHandler = () => {
    // get the account type
    const accountType = accounts.find(
      item => item.accountNumber === fromAccount,
    ).accountType;

    // perform the actual transfer
    performTransfer(parseAddress, fromAccount, toAccount, amount, accountType);

    // report success to the user
    Alert.alert(
      'Transfer',
      'Successfully transfered $' +
        amount +
        ' from account ' +
        fromAccount +
        ' to account ' +
        toAccount,
      [
        {
          text: 'OK',
          style: 'cancel',
          onPress: () => {
            props.navigation.navigate('Home');
          },
        },
      ],
      {
        cancelable: true,
        onDismiss: () => {
          props.navigation.navigate('Home');
        },
      },
    );
  };

  return (
    <ScrollView style={styles.main}>
      <Card title="Transfer between accounts">
        <View>
          <Text> </Text>
          <Text>From account:</Text>
          <View style={styles.picker}>
            <Picker
              selectedValue={fromAccount}
              onValueChange={currentFromAccount =>
                setFromAccount(currentFromAccount)
              }>
              {accountList}
            </Picker>
          </View>
        </View>
        <View>
          <Text> </Text>
          <Text>To account:</Text>
          <View style={styles.picker}>
            <Picker
              selectedValue={toAccount}
              onValueChange={currentToAccount =>
                setToAccount(currentToAccount)
              }>
              {accountList}
            </Picker>
          </View>
        </View>
        <View>
          <Text> </Text>
          <Text>Amount:</Text>
          <View style={styles.picker}>
            <TextInput
              placeholder="0.00"
              keyboardType="number-pad"
              value={amount}
              onChangeText={currentAmount => setAmount(currentAmount)}
            />
          </View>
          <Text> </Text>
        </View>
        <Button title="Transfer" onPress={transferHandler} />
      </Card>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  main: {
    flex: 10,
  },
  row: {
    flex: 1,
    alignSelf: 'stretch',
    flexDirection: 'row',
  },
  cell: {
    flex: 1,
    alignSelf: 'stretch',
  },
  widecell: {
    flex: 3,
    alignSelf: 'stretch',
  },
  numbers: {
    textAlign: 'right',
  },
  picker: {
    borderWidth: 1,
    borderColor: 'gray',
  },
});

export default Transfer;
