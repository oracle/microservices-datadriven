// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import {View, Text, Pressable, StyleSheet} from 'react-native';

const FooterActionButton = props => {
  return (
    <View style={styles.actionButton}>
      <Pressable onPress={props.onPress}>
        <Text style={styles.label}>{props.name}</Text>
      </Pressable>
    </View>
  );
};

const styles = StyleSheet.create({
  actionButton: {
    padding: 5,
    margin: 5,
    width: 68,
    height: 68,
    backgroundColor: 'white',
    alignItems: 'center',
    justifyContent: 'center',
    borderRadius: 5,
    borderColor: '#91b1e3',
    borderWidth: 2,
  },
  label: {
    fontSize: 12,
  },
});

export default FooterActionButton;
