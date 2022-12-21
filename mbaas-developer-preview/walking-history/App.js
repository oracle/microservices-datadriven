// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

import React from 'react';
import Location from './components/Location';
import Header from './components/Header';
import type {Node} from 'react';
import {
  SafeAreaView,
  ScrollView,
  StatusBar,
  StyleSheet,
  Text,
  useColorScheme,
  View,
  AsyncStorage,
  Button, 
  ActivityIndicator,
  FlatList
} from 'react-native';

import {
  Colors,
} from 'react-native/Libraries/NewAppScreen';
import { useState, useEffect } from 'react';

const Section = ({children, title}): Node => {
  const isDarkMode = useColorScheme() === 'dark';
  return (
    <View style={styles.sectionContainer}>
      <Text
        style={[
          styles.sectionTitle,
          {
            color: isDarkMode ? Colors.white : Colors.black,
          },
        ]}>
        {title}
      </Text>
      <Text
        style={[
          styles.sectionDescription,
          {
            color: isDarkMode ? Colors.light : Colors.dark,
          },
        ]}>
        {children}
      </Text>
    </View>
  );
};

const App: () => Node = () => {
  const isDarkMode = useColorScheme() === 'dark';

  const Parse = require('parse/react-native.js');
  Parse.setAsyncStorage(AsyncStorage);
  Parse.initialize("APPLICATION_ID");
  Parse.serverURL = 'http://1.2.3.4/parse';

  const [isLoading, setLoading] = useState(true);
  const [topicList, setTopicList] = useState([]);

  const getTopicList = async () => {
    try {
    const response = await fetch(
      "https://bsenjiat5lmurtq-prod.adb.us-ashburn-1.oraclecloudapps.com/ords/mark/api/topics"
    );
    const json = await response.json();
    console.log(json);
    setTopicList(json.items);
    } catch (error) {
      console.log(error);
    } finally {
      setLoading(false);
    }
  }

  useEffect(() => {
    getTopicList();
  }, []);

  const backgroundStyle = {
    backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
  };

  return (
    <SafeAreaView style={backgroundStyle}>
      <StatusBar barStyle={isDarkMode ? 'light-content' : 'dark-content'} />
      <ScrollView
        contentInsetAdjustmentBehavior="automatic"
        style={backgroundStyle}>
        <Header />
        <View
          style={{
            backgroundColor: isDarkMode ? Colors.black : Colors.white,
          }}>
          {/* <Section title="Topics">
            {isLoading ? <ActivityIndicator /> : 
              topicList.map((item) => {
                console.log("hi", item.name);
                return  (
                  <View style={{ flexDirection:'column', flex: 1, padding: 24 }}>
                    <Text style={{flex: 1, flexWrap: 'wrap', flexShrink: 1}}>{item.name}</Text>
                  </View>
                )
              })
            }
          </Section> */}
          <Section title="Walk around, discover history!">
            <Location />
          </Section>
        </View>
      </ScrollView>
    </SafeAreaView>
  );
};

const styles = StyleSheet.create({
  sectionContainer: {
    marginTop: 32,
    paddingHorizontal: 24,
  },
  sectionTitle: {
    fontSize: 24,
    fontWeight: '600',
  },
  sectionDescription: {
    marginTop: 8,
    fontSize: 18,
    fontWeight: '400',
  },
  highlight: {
    fontWeight: '700',
  },
});

export default App;
