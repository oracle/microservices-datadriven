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

// this function performs the actual deposit on the backend
const performDeposit = async (
  parseAddress,
  accountNum,
  amount,
  accountType,
) => {
  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize('APPLICATION_ID');
  Parse.serverURL = 'http://' + parseAddress + ':1337/parse';

  const Deposit = Parse.Object.extend('BankAccount');
  const deposit = new Deposit();
  deposit.set('accountNum', +accountNum);
  deposit.set('action', 'Deposit');
  deposit.set('amount', +amount);
  deposit.set('userId', 'mark');
  deposit.set('accountType', accountType);
  deposit.save().then(
    id => console.log('saved with id ' + JSON.stringify(id)),
    error => console.log('failed to save, error = ' + error),
  );
};

const Deposit = props => {
  const [toAccount, setToAccount] = useState('45000');
  const [amount, setAmount] = useState('0.00');
  const [parseAddress, setParseAddress] = useState('');
  const [accounts, setAccounts] = useState([]);

  // hook to get and save the parse server address in local state
  useEffect(() => {
    AsyncStorage.getItem('serverAddress').then(storedAddress => {
      storedAddress && setParseAddress(storedAddress);
    });
  }, [parseAddress, setParseAddress]);

  // hook to get the list of account numbers for the user, and then
  // for each account, get the type, and save this data in local state
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
              setToAccount(item);
            })
            .catch(error => console.log(error));
        });
      });
    });
  }, [props.user]);

  // sort the accounts and render a picker
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

    // this function handles the press on the deposit button
  const depositHandler = async () => {
    // lookup the account type
    const accountType = await getAccountType(parseAddress, toAccount);
    
    // perform the actual deposit transaction
    performDeposit(parseAddress, toAccount, amount, accountType);

    // report success to the user
    Alert.alert(
      'Deposit',
      'Successfully deposited $' + amount + ' in to account ' + toAccount,
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
          <Text>To account:</Text>
          <View style={styles.input}>
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
          <View style={styles.input}>
            <TextInput
              placeholder="0.00"
              keyboardType="number-pad"
              value={amount}
              onChangeText={currentAmount => setAmount(currentAmount)}
            />
          </View>
          <Text> </Text>
        </View>
        <Button title="Deposit" onPress={depositHandler} />
      </Card>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  main: {
    flex: 10,
  },
  input: {
    borderWidth: 1,
    borderColor: 'gray',
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
});

export default Deposit;
