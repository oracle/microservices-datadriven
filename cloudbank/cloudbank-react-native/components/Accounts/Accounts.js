// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React, {useState, useEffect} from 'react';
import {View, Text, StyleSheet, TouchableWithoutFeedback} from 'react-native';
import Card from '../UI/Card';
import AsyncStorage from '@react-native-async-storage/async-storage';
import {formatCurrency} from 'react-native-format-currency';
import {getAccountType, getAccounts, getAccountBalance} from '../common/common';

const Accounts = props => {
  const [accounts, setAccounts] = useState([]);
  const [refresh, setRefresh] = useState(0);

  // hook to retrieve the user's account list
  // the for each account number, find the type and balance
  // and save this information in local state
  useEffect(() => {
    AsyncStorage.getItem('serverAddress')
      .then(address => {
        getAccounts(address, props.user)
          .then(accountNumbers => {
            accountNumbers.forEach(item => {
              getAccountType(address, item)
                .then(type => {
                  getAccountBalance(address, item)
                    .then(balance => {
                      setAccounts(prev => {
                        // first check if the account is already there, if so, update it
                        const updatedState = prev.map(entry => {
                          if (entry.accountNumber === item) {
                            // replace existing entry
                            return {
                              accountNumber: item,
                              accountType: type,
                              balance: formatCurrency({
                                amount: (+balance).toFixed(2),
                                code: 'USD',
                              })[0],
                            };
                          } else {
                            // keep existing entry
                            return entry;
                          }
                        });
                        // if the account was not there, we need to add it
                        if (!prev.some(entry => entry.accountNumber === item)) {
                          updatedState.push({
                            accountNumber: item,
                            accountType: type,
                            balance: formatCurrency({
                              amount: (+balance).toFixed(2),
                              code: 'USD',
                            })[0],
                          });
                        }
                        return updatedState;
                      });
                    })
                    .catch(error => console.log(error));
                })
                .catch(error => console.log(error));
            });
          })
          .catch(error => console.log(error));
      })
      .catch(error => console.log(error));

    // force refresh after BACK so balances will be updated if 
    // a transaction just occurred
    /* eslint-disable no-unused-vars */
    const willFocusSubscription = props.navigation.addListener('focus', () =>
      setRefresh(refresh + 1),
    );
    /* eslint-enable no-unused-vars */
  }, [refresh, props.navigation, props.user]);

  // sort the accounts by account number
  const accountList =
    accounts.length !== 0 ? (
      accounts
        .sort((a, b) => +a.accountNumber - +b.accountNumber)
        .map(account => {
          return (
            <TouchableWithoutFeedback
              onPress={() =>
                props.navigation.navigate('AccountDetail', {
                  accountNumber: account.accountNumber,
                })
              }>
              <View style={styles.row} key={account.accountNumber}>
                <View style={styles.cell}>
                  <Text>{account.accountNumber}</Text>
                </View>
                <View style={styles.widecell}>
                  <Text>{account.accountType}</Text>
                </View>
                <View style={styles.cell}>
                  <Text style={styles.numbers}>{account.balance}</Text>
                </View>
              </View>
            </TouchableWithoutFeedback>
          );
        })
    ) : (
      <View style={styles.row}>
        <View style={styles.cell}>
          <Text> </Text>
          <Text>No accounts to display</Text>
        </View>
      </View>
    );

  return <Card title="My Accounts">{accountList}</Card>;
};

const styles = StyleSheet.create({
  row: {
    flex: 1,
    alignSelf: 'stretch',
    flexDirection: 'row',
  },
  widecell: {
    flex: 3,
    alignSelf: 'stretch',
  },
  cell: {
    flex: 1,
    alignSelf: 'stretch',
  },
  numbers: {
    textAlign: 'right',
  },
});

export default Accounts;
