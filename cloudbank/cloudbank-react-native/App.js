// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React, {useState} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import LoginForm from './components/Login/LoginForm';
import Home from './components/Home';
import AccountDetail from './components/Accounts/AccountDetail';
import {NavigationContainer} from '@react-navigation/native';
import {createNativeStackNavigator} from '@react-navigation/native-stack';
import CloudBankMasthead from './components/UI/CloudBankMasthead';
import Transfer from './components/Transfer/Transfer';
import Deposit from './components/Deposit/Deposit';
import Payment from './components/Payment/Payment';
import {Alert} from 'react-native';

const Stack = createNativeStackNavigator();

const App = () => {
  // isLoggedIn is used to control whether to show the login screen or the main app ui
  const [isLoggedIn, setIsLoggedIn] = useState(false);
  // user stores the username of the logged in user
  const [user, setUser] = useState('');

  // called when the user logs out
  const logoutHandler = () => {
    AsyncStorage.removeItem('isLoggedIn');
    setIsLoggedIn(false);
  };

  // called when the user logs in
  const loginHandler = (username, password, serverAddress) => {
    // do some very basic form validation
    if (username.length < 1) {
      Alert.alert('You must enter your username');
      return;
    }
    if (password.length < 1) {
      Alert.alert('You must enter your password');
      return;
    }
    // TODO call API to validate user exists, etc.

    // store the logged in state and the server address that the user entered
    AsyncStorage.setItem('isLoggedIn', '1');
    AsyncStorage.setItem('serverAddress', serverAddress);
    setUser(username);
    setIsLoggedIn(true);
  };

  return (
    <NavigationContainer>
      <Stack.Navigator
        screenOptions={{
          headerTitle: props => <CloudBankMasthead />,
        }}>
        {isLoggedIn ? (
          <>
            <Stack.Screen name="Home">
              {props => (
                <Home {...props} onLogout={logoutHandler} user={user} />
              )}
            </Stack.Screen>
            <Stack.Screen name="AccountDetail">
              {props => <AccountDetail {...props} />}
            </Stack.Screen>
            <Stack.Screen name="Transfer">
              {props => <Transfer {...props} user={user} />}
            </Stack.Screen>
            <Stack.Screen name="Payment">
              {props => <Payment {...props} user={user} />}
            </Stack.Screen>
            <Stack.Screen name="Deposit">
              {props => <Deposit {...props} user={user} />}
            </Stack.Screen>
          </>
        ) : (
          <>
            <Stack.Screen name="Login">
              {props => <LoginForm {...props} onLogin={loginHandler} />}
            </Stack.Screen>
          </>
        )}
      </Stack.Navigator>
    </NavigationContainer>
  );
};

export default App;
