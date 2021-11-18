#!/usr/bin/env python
# coding: utf-8

# In[20]:


#import os
import sys
import subprocess
import WineFoodPairings

if __name__ == "__main__":
    argList = sys.argv
    test_food = argList[1]
    print('Input in main11111 : ',test_food)
    #wine_names = subprocess.call([sys.executable, 'Wine Food Pairings.py', test_food])
    wine_names = WineFoodPairings.getRecommendedWines(test_food)
    print('wine_names : ',wine_names)