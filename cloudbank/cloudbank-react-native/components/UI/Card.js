// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import {View, Text, StyleSheet, TouchableWithoutFeedback} from 'react-native';

const Card = props => {
  return (
    <TouchableWithoutFeedback onPress={props.onPress}>
      <View onClick={props.onClick} title={props.title} style={styles.card}>
        {props.title && <Text style={styles.heading}>{props.title}</Text>}
        {props.children}
      </View>
    </TouchableWithoutFeedback>
  );
};

const styles = StyleSheet.create({
  card: {
    backgroundColor: 'white',
    borderRadius: 5,
    padding: 5,
    margin: 5,
  },
  heading: {
    fontSize: 18,
    fontWeight: '600',
    padding: 5,
  },
});

export default Card;
