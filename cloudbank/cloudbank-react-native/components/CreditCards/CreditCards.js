// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import {View, Text, StyleSheet} from 'react-native';
import Card from '../UI/Card';

// this is really a placeholder for future use
const CreditCards = () => {
  return (
    <Card title="My Credit Cards">
      <View key="1" style={styles.row}>
        <View style={styles.cell}>
          <Text>AAdvantage</Text>
        </View>
        <View style={styles.cell}>
          <Text style={styles.numbers}>$1,098.56</Text>
        </View>
      </View>
      <View key="2" style={styles.row}>
        <View style={styles.cell}>
          <Text>CitiCard</Text>
        </View>
        <View style={styles.cell}>
          <Text style={styles.numbers}>$1,500.00</Text>
        </View>
      </View>
    </Card>
  );
};

const styles = StyleSheet.create({
  row: {
    flex: 1,
    alignSelf: 'stretch',
    flexDirection: 'row',
  },
  cell: {
    flex: 1,
    alignSelf: 'stretch',
  },
  numbers: {
    textAlign: 'right',
  },
});

export default CreditCards;
