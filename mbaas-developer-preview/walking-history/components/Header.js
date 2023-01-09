// Copyright (c) 2022, Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.

 //import type {Node} from 'react';
 import {ImageBackground, StyleSheet, Text, useColorScheme} from 'react-native';
 import React from 'react';
 import Colors from 'react-native';
 
 const Header = (): Node => {
   const isDarkMode = useColorScheme() === 'dark';
   return (
     <ImageBackground
       accessibilityRole="image"
       testID="new-app-screen-header"
       source={require('./logo.png')}
       style={[
         styles.background,
         {
           backgroundColor: isDarkMode ? Colors.darker : Colors.lighter,
         },
       ]}
       imageStyle={styles.logo}>
       <Text
         style={[
           styles.text,
           {
             color: isDarkMode ? Colors.white : Colors.black,
           },
         ]}>
         Walking
         {'\n'}
         History
       </Text>
     </ImageBackground>
   );
 };
 
 const styles = StyleSheet.create({
   background: {
     paddingBottom: 30,
     paddingTop: 56,
     paddingHorizontal: 32,
   },
   logo: {
     opacity: 0.2,
     overflow: 'visible',
     resizeMode: 'cover',
     /*
      * These negative margins allow the image to be offset similarly across screen sizes and component sizes.
      *
      * The source logo.png image is 512x512px, so as such, these margins attempt to be relative to the
      * source image's size.
      */
     marginLeft: -128,
     marginBottom: -192,
   },
   text: {
     fontSize: 40,
     fontWeight: '700',
     textAlign: 'center',
   },
 });
 
 export default Header;
 