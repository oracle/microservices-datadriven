// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import {StyleSheet, View} from 'react-native';
import FooterActionButton from './FooterActionButton';

const Footer = props => {
  const onPressBillPayHandler = () => {
    console.log('pressed bill pay');
  };

  return (
    <View style={styles.footer}>
      <FooterActionButton
        name="Deposit"
        onPress={() => props.navigation.navigate('Deposit')}
      />
      <FooterActionButton
        name="Transfer"
        onPress={() => props.navigation.navigate('Transfer')}
      />
      <FooterActionButton
        name="Payment"
        onPress={() => props.navigation.navigate('Payment')}
      />
      <FooterActionButton name="Bill Pay" onPress={onPressBillPayHandler} />
      <FooterActionButton name="Logout" onPress={props.onLogout} />
    </View>
  );
};

const styles = StyleSheet.create({
  footer: {
    flexDirection: 'row',
    position: 'absolute',
    bottom: 0,
    height: 78,
    backgroundColor: '#8194b3',
    left: 0,
    right: 0,
    borderColor: '#91b1e3',
    borderTopWidth: 2,
  },
});

export default Footer;
