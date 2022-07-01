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
  destinationBank,
  user,
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
  transfer.set('userId', user);
  // TODO this assumes the bank is always CloudBank, need to fix this
  // if we are transfering to another user's account at the same bank,
  // we provide toAccountNum, otherwise, we provide externalAccountNum
  destinationBank === 'CloudBank'
    ? transfer.set('toAccountNum', +toAccountNum)
    : transfer.set('externalAccountNum', +toAccountNum);
  transfer.set('accountType', accountType);
  transfer.save().then(
    id => console.log('saved with id ' + JSON.stringify(id)),
    error => console.log('failed to save, error = ' + error),
  );
};

const Payment = props => {
  const [fromAccount, setFromAccount] = useState('');
  const [toAccount, setToAccount] = useState('102');
  const [amount, setAmount] = useState('0.00');
  const [destinationBank, setDestinationBank] = useState('CloudBank');
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
              key={account.accountNumber}
              value={account.accountNumber}
              label={account.accountNumber + ' - ' + account.accountType}
            />
          );
        })
    ) : (
      <></>
    );

  const paymentHandler = () => {
    // get the account type
    const accountType = accounts.find(
      item => item.accountNumber === fromAccount,
    ).accountType;

    // perform the actual transfer
    performTransfer(
      parseAddress,
      fromAccount,
      toAccount,
      amount,
      accountType,
      destinationBank,
      props.user,
    );

    // report success to the user
    Alert.alert(
      'Payment',
      'Successfully paid $' +
        amount +
        ' from account ' +
        fromAccount +
        ' to external account ' +
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
      <Card title="Send payment to external account">
        <View>
          <Text> </Text>
          <Text>From your account:</Text>
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
          <Text>Destination Bank:</Text>
          <View style={styles.picker}>
            <Picker
              selectedValue={destinationBank}
              onValueChange={destination => setDestinationBank(destination)}>
              <Picker.Item
                key="CloudBank"
                value="CloudBank"
                label="CloudBank"
              />
              <Picker.Item
                key="ReggieBank"
                value="ReggieBank"
                label="ReggieBank"
              />
            </Picker>
          </View>
        </View>
        <View>
          <Text> </Text>
          <Text>To external account:</Text>
          <View style={styles.picker}>
            <TextInput
              placeholder="123"
              keyboardType="number-pad"
              value={toAccount}
              onChangeText={currentToAccount => setToAccount(currentToAccount)}
            />
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
        <Button title="Pay" onPress={paymentHandler} />
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

export default Payment;
