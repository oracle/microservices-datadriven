// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import {Image, StyleSheet} from 'react-native';
import Card from './Card';

const CloudBankMasthead = () => {
  return (
    <Card style={styles.card}>
      <Image source={require('./cloudbank.png')} style={styles.image} />
    </Card>
  );
};

const styles = StyleSheet.create({
  card: {
    justifyContent: 'center',
    alignItems: 'center',
  },
  image: {
    height: 84,
  },
});

export default CloudBankMasthead;
