#!/usr/bin/env python
# coding: utf-8

# In[1]:


import os
import pandas as pd
import numpy as np
import string
# from operator import itemgetter
from collections import Counter, OrderedDict

from nltk.tokenize import word_tokenize, sent_tokenize
from nltk.stem import SnowballStemmer
from nltk.corpus import stopwords
import nltk
#nltk.download('punkt')
#nltk.download('stopwords')

from gensim.models.phrases import Phrases, Phraser
from gensim.models import Word2Vec

from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.decomposition import PCA
from matplotlib import pyplot as plt

pd.set_option('display.max_rows', 500)
pd.set_option('display.max_columns', 500)


# First, import the wine dataset.

# In[2]:


base_location = r"wine_data"

i = 0
for file in os.listdir(base_location):
    file_location = base_location + '/' + str(file)
    if i==0:
        wine_dataframe = pd.read_csv(file_location, encoding='latin-1')
        i+=1
    else:
        df_to_append = pd.read_csv(file_location, encoding='latin-1', low_memory=False)
        wine_dataframe = pd.concat([wine_dataframe, df_to_append], axis=0)


# In[3]:


#wine_dataframe.drop_duplicates(subset=['Name'], inplace=True)

geographies = ['Subregion', 'Region', 'Province', 'Country']
for geo in geographies:
    wine_dataframe[geo] = wine_dataframe[geo].apply(lambda x : str(x).strip())

print(wine_dataframe)


# Then, the food dataset.

# In[4]:


food_review_dataset = pd.read_csv('food_data/Reviews.csv')
print(food_review_dataset.shape)


# ### 1. Training our Word Embeddings
# 
# First, we need to train a Word2Vec model on all the words in our corpus. We will process our wine and food terms separately - some of the wine terms will be standardized to account for commonalities in the colorful language of the world of wine.

# In[5]:


wine_reviews_list = list(wine_dataframe['Description'])
food_reviews_list = list(food_review_dataset['Text'])


# To begin, we need to tokenize the terms in our corpus (wine and food).

# In[6]:


full_wine_reviews_list = [str(r) for r in wine_reviews_list]
full_wine_corpus = ' '.join(full_wine_reviews_list)
wine_sentences_tokenized = sent_tokenize(full_wine_corpus)

full_food_reviews_list = [str(r) for r in food_reviews_list]
full_food_corpus = ' '.join(full_food_reviews_list)
food_sentences_tokenized = sent_tokenize(full_food_corpus)

print(wine_sentences_tokenized[:2])
print(food_sentences_tokenized[:2])


# Next, the text in each sentence is normalized (tokenize, remove punctuation and remove stopwords).

# In[7]:


stop_words = set(stopwords.words('english')) 

punctuation_table = str.maketrans({key: None for key in string.punctuation})
sno = SnowballStemmer('english')

def normalize_text(raw_text):
    try:
        word_list = word_tokenize(raw_text)
        normalized_sentence = []
        for w in word_list:
            try:
                w = str(w)
                lower_case_word = str.lower(w)
                stemmed_word = sno.stem(lower_case_word)
                no_punctuation = stemmed_word.translate(punctuation_table)
                if len(no_punctuation) > 1 and no_punctuation not in stop_words:
                    normalized_sentence.append(no_punctuation)
            except:
                continue
        return normalized_sentence
    except:
        return ''

normalized_wine_sentences = []
for s in wine_sentences_tokenized:
    normalized_text = normalize_text(s)
    normalized_wine_sentences.append(normalized_text)

normalized_food_sentences = []
for s in food_sentences_tokenized:
    normalized_text = normalize_text(s)
    normalized_food_sentences.append(normalized_text)
    
print(normalized_wine_sentences[:2])
print(normalized_food_sentences[:2])


# Not all of the terms we are interested in are single words. Some of the terms are phrases, consisting of two (or more!) words. An example of this might be 'high tannin'. We can use gensim's Phrases feature to extract all the most relevant bi- and tri-grams from our corpus.
# 
# We will train a separate trigram model for wine and for food. 

# In[8]:


# first, take care of the wine trigrams
wine_bigram_model = Phrases(normalized_wine_sentences, min_count=100)
wine_bigrams = [wine_bigram_model[line] for line in normalized_wine_sentences]
wine_trigram_model = Phrases(wine_bigrams, min_count=50)
phrased_wine_sentences = [wine_trigram_model[line] for line in wine_bigrams]
#wine_trigram_model.save('wine_trigrams.pkl')

### now, do the same for food
food_bigram_model = Phrases(normalized_food_sentences, min_count=100)
food_bigrams = [food_bigram_model[sent] for sent in normalized_food_sentences]
food_trigram_model = Phrases(food_bigrams, min_count=50)
phrased_food_sentences = [food_trigram_model[sent] for sent in food_bigrams]
#food_trigram_model.save('food_trigrams.pkl')

wine_trigram_model = Phraser.load('wine_trigrams.pkl')
food_trigram_model = Phraser.load('food_trigrams.pkl')



descriptor_mapping = pd.read_csv('descriptor_mapping.csv', encoding='latin1').set_index('raw descriptor')

def return_mapped_descriptor(word, mapping):
    if word in list(mapping.index):
        normalized_word = mapping.at[word, 'level_3']
        return normalized_word
    else:
        return word

normalized_wine_sentences = []
for sent in phrased_wine_sentences:
    normalized_wine_sentence = []
    for word in sent:
        normalized_word = return_mapped_descriptor(word, descriptor_mapping)
        normalized_wine_sentence.append(str(normalized_word))
    normalized_wine_sentences.append(normalized_wine_sentence)


# If the trigram model has already been trained, simply retrieve it.

# In[9]:


#wine_trigram_model = Phraser.load('wine_trigrams.pkl')
#food_trigram_model = Phraser.load('food_trigrams.pkl')


# Now for the most important part: leveraging existing wine theory, the work of others like Bernard Chen, wine descriptor mappings and the UC Davis wine wheel, the top 5000 most frequent wine terms were reviewed to (i) determine whether they are a descriptor that can be derived by blind tasting, and (ii) whether they are informative (judgments like 'tasty' and 'great' are not considered to be informative). The roughly 1000 descriptors that remain were then mapped onto a normalized descriptor, a category and a class:

# In[10]:


#descriptor_mapping = pd.read_csv('descriptor_mapping.csv', encoding='latin1').set_index('raw descriptor')

#def return_mapped_descriptor(word, mapping):
#    if word in list(mapping.index):
#        normalized_word = mapping.at[word, 'level_3']
#        return normalized_word
#    else:
#        return word

#normalized_wine_sentences = []
#for sent in phrased_wine_sentences:
#    normalized_wine_sentence = []
#    for word in sent:
#        normalized_word = return_mapped_descriptor(word, descriptor_mapping)
#        normalized_wine_sentence.append(str(normalized_word))
#    normalized_wine_sentences.append(normalized_wine_sentence)


# We will go through the same process for food, but without normalizing the nonaroma descriptors.

# In[11]:


aroma_descriptor_mapping = descriptor_mapping.loc[descriptor_mapping['type'] == 'aroma']
print(aroma_descriptor_mapping)
normalized_food_sentences = []
for sent in phrased_food_sentences:
    normalized_food_sentence = []
    for word in sent:
        normalized_word = return_mapped_descriptor(word, aroma_descriptor_mapping)
        normalized_food_sentence.append(str(normalized_word))
    normalized_food_sentences.append(normalized_food_sentence)


# Now, let's combine the wine dataset with our food dataset so we can train our embeddings. We want to make sure that the food and wine embeddings are calculated in the same feature space so that we can compute similarity vectors later on.

# In[12]:


normalized_sentences = normalized_wine_sentences + normalized_food_sentences


# We are ready to train our Word2Vec model!

# In[13]:


wine_word2vec_model = Word2Vec(normalized_sentences, vector_size=300, min_count=8, epochs=15)
print(wine_word2vec_model)

wine_word2vec_model.save('food_word2vec_model.bin')


# In[14]:


# if the word2vec model has already been trained, simply load it
wine_word2vec_model = Word2Vec.load("food_word2vec_model.bin")


# ### 2. Preprocessing our Wine Dataset
# 
# We can now turn our attention to our wine dataset. Descriptions for a single wine are unlikely to contain sufficient information about all the nonaromas and aromas to yield consistent and reliable pairing recommendations. As such, we will produce recommendations at the grape variety & subregion level. 
# 
# First, let's normalize the names of the grape varieties in our dataset.

# In[15]:


variety_mapping = {'Shiraz': 'Syrah', 'Pinot Gris': 'Pinot Grigio', 'Pinot Grigio/Gris': 'Pinot Grigio', 
                   'Garnacha, Grenache': 'Grenache', 'Garnacha': 'Grenache', 'CarmenÃ¨re': 'Carmenere',
                    'GrÃ¼ner Veltliner': 'Gruner Veltliner', 'TorrontÃ©s': 'Torrontes', 
                   'RhÃ´ne-style Red Blend': 'Rhone-style Red Blend', 'AlbariÃ±o': 'Albarino',
                  'GewÃ¼rztraminer': 'Gewurztraminer', 'RhÃ´ne-style White Blend': 'Rhone-style White Blend',
                  'SpÃƒÂ¤tburgunder, Pinot Noir': 'Pinot Noir', 'Sauvignon, Sauvignon Blanc': 'Sauvignon Blanc',
                  'Pinot Nero, Pinot Noir': 'Pinot Noir', 'Malbec-Merlot, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                  'Meritage, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Garnacha, Grenache': 'Grenache',
                   'FumÃ© Blanc': 'Sauvignon Blanc', 'Cabernet Sauvignon-Cabernet Franc, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                   'Cabernet Merlot, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Cabernet Sauvignon-Merlot, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                   'Cabernet Blend, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Malbec-Cabernet Sauvignon, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                   'Merlot-Cabernet Franc, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Merlot-Cabernet Sauvignon, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                   'Cabernet Franc-Merlot, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Merlot-Malbec, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend',
                   'Cabernet, Bordeaux-style Red Blend': 'Bordeaux-style Red Blend', 'Primitivo, Zinfandel': 'Zinfandel',
                   'AragonÃªs, Tempranillo': 'Aragonez, Tempranillo'
                  }

def consolidate_varieties(variety_name):
    if variety_name in variety_mapping:
        return variety_mapping[variety_name]
    else:
        return variety_name

wine_df_clean = wine_dataframe.copy()
wine_df_clean['Variety'] = wine_df_clean['Variety'].apply(consolidate_varieties)


# Next, we need to define the set of geography subregions we will use to define our wines. Not too general, not too specific... just right. 

# In[16]:


order_of_geographies = ['Subregion', 'Region', 'Province', 'Country']


# replace any nan values in the geography columns with the word none
def replace_nan_for_zero(value):
    if str(value) == '0' or str(value) == 'nan':
        return 'none'
    else:
        return value

for o in order_of_geographies:
    wine_df_clean[o] = wine_df_clean[o].apply(replace_nan_for_zero)

wine_df_clean.loc[:, order_of_geographies].fillna('none', inplace=True)


# In[17]:


variety_geo = wine_df_clean.groupby(['Variety', 'Country', 'Province', 'Region', 'Subregion']).size().reset_index().rename(columns={0:'count'})
variety_geo_sliced = variety_geo.loc[variety_geo['count'] > 1]

vgeos_df = pd.DataFrame(variety_geo_sliced, columns=['Variety', 'Country', 'Province', 'Region', 'Subregion', 'count']) 
vgeos_df.to_csv('varieties_all_geos.csv')


# In[18]:


variety_geo_df = pd.read_csv('varieties_all_geos_normalized.csv', index_col=0)

wine_df_merged = pd.merge(left=wine_df_clean, right=variety_geo_df, left_on=['Variety', 'Country', 'Province', 'Region', 'Subregion'],
                         right_on=['Variety', 'Country', 'Province', 'Region', 'Subregion'])
#wine_df_merged.drop(['Unnamed: 0', 'Appellation', 'Bottle Size', 'Category', 'Country', 
#                     'Date Published', 'Designation', 'Importer', 'Province', 'Rating', 
#                     'Region', 'Reviewer', 'Reviewer Twitter Handle', 'Subregion', 'User Avg Rating', 'Winery', 'count'], 
#                    axis=1, inplace=True)
wine_df_merged.shape


# We only want to keep wine types (location + variety) that appear frequently enough in our dataset. 

# In[19]:


variety_geos = wine_df_merged.groupby(['Variety', 'geo_normalized']).size()
at_least_n_types = variety_geos[variety_geos > 30].reset_index()
wine_df_merged_filtered = pd.merge(wine_df_merged, at_least_n_types, left_on=['Variety', 'geo_normalized'], right_on=['Variety', 'geo_normalized'])
#wine_df_merged_filtered = wine_df_merged_filtered[['Name', 'Variety', 'geo_normalized', 'Description']]
wine_df_merged_filtered = wine_df_merged_filtered[['Variety', 'geo_normalized', 'Description']]
print(wine_df_merged_filtered.shape)


# Now, we will extract 7 vectors for every wine:
# 
# - aroma vector (the aggregate of all the aroma descriptors in a wine)
# - nonaroma vectors (an aggregate vector for only aroma & non-aroma descriptors matching the core tastes below):
#     - sweetness
#     - acid
#     - salt
#     - piquant
#     - fat
#     - bitter
#     
#  In our descriptor file, we have defined which normalized descriptors pertain to each nonaroma. 

# In[20]:


wine_reviews = list(wine_df_merged_filtered['Description'])

descriptor_mapping = pd.read_csv('descriptor_mapping_tastes.csv', encoding='latin1').set_index('raw descriptor')

core_tastes = ['aroma', 'weight', 'sweet', 'acid', 'salt', 'piquant', 'fat', 'bitter']
descriptor_mappings = dict()
for c in core_tastes:
    if c=='aroma':
        descriptor_mapping_filtered=descriptor_mapping.loc[descriptor_mapping['type']=='aroma']
    else:
        descriptor_mapping_filtered=descriptor_mapping.loc[descriptor_mapping['primary taste']==c]
    descriptor_mappings[c] = descriptor_mapping_filtered                                                   
    

def return_descriptor_from_mapping(descriptor_mapping, word, core_taste):
    if word in list(descriptor_mapping.index):
        descriptor_to_return = descriptor_mapping['combined'][word]
        return descriptor_to_return
    else:
        return None

review_descriptors = []
for review in wine_reviews:
    taste_descriptors = []
    normalized_review = normalize_text(review)
    phrased_review = wine_trigram_model[normalized_review]
#     print(phrased_review)
    
    for c in core_tastes:                                                      
        descriptors_only = [return_descriptor_from_mapping(descriptor_mappings[c], word, c) for word in phrased_review]
        no_nones = [str(d).strip() for d in descriptors_only if d is not None]
        descriptorized_review = ' '.join(no_nones)
        taste_descriptors.append(descriptorized_review)
    review_descriptors.append(taste_descriptors)


# Now we will take the list of descriptors for each wine and its aroma/nonaroma vectors and compute a TF-IDF weighted embedding for each. We will store the results in a dataframe.

# In[21]:


taste_descriptors = []
taste_vectors = []

for n, taste in enumerate(core_tastes):
    print(taste)
    taste_words = [r[n] for r in review_descriptors]
    
    vectorizer = TfidfVectorizer()
    X = vectorizer.fit(taste_words)
    dict_of_tfidf_weightings = dict(zip(X.get_feature_names(), X.idf_))
        
    wine_review_descriptors = []
    wine_review_vectors = []
    
    for d in taste_words:
        descriptor_count = 0
        weighted_review_terms = []
        terms = d.split(' ')
        for term in terms:
            if term in dict_of_tfidf_weightings.keys():
                tfidf_weighting = dict_of_tfidf_weightings[term]
                try:
                    word_vector = wine_word2vec_model.wv.get_vector(term).reshape(1, 300)
                    weighted_word_vector = tfidf_weighting * word_vector
                    weighted_review_terms.append(weighted_word_vector)
                    descriptor_count += 1
                except:
                    continue
            else:
                continue
        try:
            review_vector = sum(weighted_review_terms)/len(weighted_review_terms)
            review_vector = review_vector[0]
        except:
            review_vector = np.nan
#         terms_and_vec = [terms, review_vector]
        wine_review_vectors.append(review_vector)
        wine_review_descriptors.append(terms)
    
    taste_vectors.append(wine_review_vectors)
    taste_descriptors.append(wine_review_descriptors)
    

taste_vectors_t = list(map(list, zip(*taste_vectors)))
taste_descriptors_t = list(map(list, zip(*taste_descriptors)))

review_vecs_df = pd.DataFrame(taste_vectors_t, columns=core_tastes)

columns_taste_descriptors = [a + '_descriptors' for a in core_tastes]
review_descriptors_df = pd.DataFrame(taste_descriptors_t, columns=columns_taste_descriptors)

wine_df_vecs = pd.concat([wine_df_merged_filtered, review_descriptors_df, review_vecs_df], axis=1)
wine_df_vecs.head(5)


# If we don't have a nonaroma embedding for one of the wines, we will simply take the average nonaroma embedding for all the wines in the dataset.

# In[22]:


# pull the average embedding for the wine attribute across all wines. 
avg_taste_vecs = dict()
for t in core_tastes:
    # look at the average embedding for a taste, across all wines that have descriptors for that taste 
    review_arrays = wine_df_vecs[t].dropna()
    average_taste_vec = np.average(review_arrays)
    avg_taste_vecs[t] = average_taste_vec


# Now, let's find the average embedding for each type of wine (aromas and all nonaromas). We have defined the different types of wines by grape variety and geography, keeping only those with a sufficiently large sample size.
# 
# For each variety, we will pull (i) a 300-dimensional aroma vector, and (ii) 7 non-aroma scalars.

# In[23]:


normalized_geos = list(set(zip(wine_df_vecs['Variety'], wine_df_vecs['geo_normalized'])))

def subset_wine_vectors(list_of_varieties, wine_attribute):
    wine_variety_vectors = []
    for v in list_of_varieties:

        one_var_only = wine_df_vecs.loc[(wine_df_vecs['Variety'] == v[0]) & 
                                                (wine_df_vecs['geo_normalized'] == v[1])]
        if len(list(one_var_only.index)) < 1 or str(v[1][-1]) == '0':
            continue
        else:
            taste_vecs = list(one_var_only[wine_attribute])
            taste_vecs = [avg_taste_vecs[wine_attribute] if 'numpy' not in str(type(x)) else x for x in taste_vecs]
            average_variety_vec = np.average(taste_vecs, axis=0)
            
            descriptor_colname = wine_attribute + '_descriptors'
            all_descriptors = [i[0] for i in list(one_var_only[descriptor_colname])]
            word_freqs = Counter(all_descriptors)
            most_common_words = word_freqs.most_common(50)
            top_n_words = [(i[0], "{:.2f}".format(i[1]/len(taste_vecs))) for i in most_common_words]
            top_n_words = [i for i in top_n_words if len(i[0])>2]
            wine_variety_vector = [v, average_variety_vec, top_n_words]
                
            wine_variety_vectors.append(wine_variety_vector)
            
    return wine_variety_vectors


def pca_wine_variety(list_of_varieties, wine_attribute, pca=True):
    wine_var_vectors = subset_wine_vectors(normalized_geos, wine_attribute)
    
    wine_varieties = [str(w[0]).replace('(', '').replace(')', '').replace("'", '').replace('"', '') for w in wine_var_vectors]
    wine_var_vec = [w[1] for w in wine_var_vectors]
    if pca:
        pca = PCA(1)
        #below one line newly added by praveen
        #wine_var_vec = np.array(wine_var_vec).reshape(-1, 1)
        
        wine_var_vec = pca.fit_transform(wine_var_vec)
        wine_var_vec = pd.DataFrame(wine_var_vec, index=wine_varieties)
    else:
        wine_var_vec = pd.Series(wine_var_vec, index=wine_varieties)
    wine_var_vec.sort_index(inplace=True)
    
    wine_descriptors = pd.DataFrame([w[2] for w in wine_var_vectors], index=wine_varieties)
    wine_descriptors = pd.melt(wine_descriptors.reset_index(), id_vars='index')
    wine_descriptors.sort_index(inplace=True)
    
    return wine_var_vec, wine_descriptors

taste_dataframes = []
# generate the dataframe of aromas vectors as output, 
aroma_vec, aroma_descriptors = pca_wine_variety(normalized_geos, 'aroma', pca=False)
taste_dataframes.append(aroma_vec)
#print(taste_dataframes)
print(core_tastes)
# generate the dataframes of nonaroma scalars
for tw in core_tastes[1:]:
    pca_w_dataframe, nonaroma_descriptors = pca_wine_variety(normalized_geos, tw, pca=False)
    taste_dataframes.append(pca_w_dataframe)
    
# combine all the dataframes created above into one 
all_nonaromas = pd.concat(taste_dataframes, axis=1)
all_nonaromas.columns = core_tastes


# In[24]:


# save the 50 top descriptors for each wine variety as a CSV file. We will us this later to dig deeper into our proposed wine recommendations.

aroma_descriptors_copy = aroma_descriptors.copy()
aroma_descriptors_copy.set_index('index', inplace=True)
aroma_descriptors_copy.dropna(inplace=True)

aroma_descriptors_copy = pd.DataFrame(aroma_descriptors_copy['value'].tolist(), index=aroma_descriptors_copy.index)
aroma_descriptors_copy.columns = ['descriptors', 'relative_frequency']
aroma_descriptors_copy.to_csv('wine_variety_descriptors.csv')


# At the moment, it's hard to interpret the nonaroma scalars. To allow for greater interpretability, we will normalize the nonaroma scalars between 0 and 1.

# In[25]:


def normalize(df, cols_to_normalize):
    for feature_name in cols_to_normalize:
        print(feature_name)
        
        # TODO : Praveen (solve min and max function values)
        max_value = 1 #np.max(df[feature_name])
        min_value = 0 # np.min(df[feature_name])
        #max_value = df[feature_name].max()
        #min_value = df[feature_name].min()
        df[feature_name] = df[feature_name].apply(lambda x: (x- min_value)/(max_value-min_value))
#         (df[feature_name] - min_value) / (max_value - min_value)
    return df

all_nonaromas_normalized = normalize(all_nonaromas, cols_to_normalize=core_tastes[1:])
all_nonaromas_normalized.to_csv('wine_aromas_nonaromas.csv')


# ### 3. Preparing our Food Dataset
# 
# Now that we have our wine aroma vectors and the nonaroma scalars, we can turn our attention to food. 
# 
# We will want to generate nonaroma vectors for any type of food that we want a wine pairing with. For food, we don't have the luxury of being able to define nonaroma vs. aroma descriptors, so the approach we take will be slightly different:
# 
# The aroma vector will be the full food embedding.
# 
# We will define an embedding for each of our core nonaromas (sweet, acid, salt, piquant, fat and bitter), and the weight/body of the food. We will define the maximum distance between each of the nonaroma embeddings and a range of commonly appearing foods. The foods that least and most resemble each nonaroma will eventually allow us to create a normalized scale between 0 (very dissimilar) and 1 (very similar) to say how much a food reflects each nonaroma. 
# 
# First, let's load this list of common foods.

# In[26]:


foods = pd.read_csv('list_of_foods.csv')
foods_list = list(foods['Food'])
foods_list_normalized = [normalize_text(f) for f in foods_list]
foods_list_preprocessed = [food_trigram_model[f][0] for f in foods_list_normalized]
foods_list_preprocessed = list(set(foods_list_preprocessed))


# Load the word embedding for each food in the list of sample foods, and save to a dictionary. 

# In[27]:


foods_vecs = dict()

word_vectors = wine_word2vec_model.wv
for f in foods_list_preprocessed:
    try:
        food_vec = word_vectors[f]
        foods_vecs[f] = food_vec
    except:
        continue


# Now, we can define the nonaroma embeddings + the weight embedding as the average of foods that represent each nonaroma characteristic.

# In[28]:


from scipy import spatial

core_tastes_revised = {'weight': ['heavy', 'cassoulet', 'cassoulet', 'full_bodied', 'thick', 'milk', 'fat', 'mincemeat', 'steak', 'bold', 'pizza', 'pasta', 'creamy', 'bread'],
                       'sweet': ['sweet', 'sugar', 'cake', 'mango', 'stevia'], 
                       'acid': ['acid', 'sour', 'vinegar', 'yoghurt', 'cevich', 'cevich'],
                       'salt': ['salty', 'salty', 'parmesan', 'oyster', 'pizza', 'bacon', 'cured_meat', 'sausage', 'potato_chip'], 
                       'piquant': ['spicy'], 
                       'fat': ['fat', 'fried', 'creamy', 'cassoulet', 'foie_gras', 'buttery', 'cake', 'foie_gras', 'sausage', 'brie', 'carbonara'], 
                       'bitter': ['bitter', 'kale']
                      }

average_taste_vecs = dict()
core_tastes_distances = dict()
for taste, keywords in core_tastes_revised.items():
    
    all_keyword_vecs = []
    for keyword in keywords:
        c_vec = word_vectors[keyword]
        all_keyword_vecs.append(c_vec)
    
    avg_taste_vec = np.average(all_keyword_vecs, axis=0)
    average_taste_vecs[taste] = avg_taste_vec
        
    taste_distances = dict()
    for k, v in foods_vecs.items():
        similarity = 1- spatial.distance.cosine(avg_taste_vec, v)
        taste_distances[k] = similarity
        
    core_tastes_distances[taste] = taste_distances        


# We can now find out which foods most and least resemble each nonaroma.

# In[29]:


food_nonaroma_infos = dict()
# for each core taste, identify the food item that is farthest and closest. We will need this to create a normalized scale between 0 and 1
for key, value in core_tastes_revised.items():
    dict_taste = dict()
    farthest = min(core_tastes_distances[key], key=core_tastes_distances[key].get)
    farthest_distance = core_tastes_distances[key][farthest]
    closest = max(core_tastes_distances[key], key=core_tastes_distances[key].get)
    closest_distance = core_tastes_distances[key][closest]
    print(key, farthest, closest)
    dict_taste['farthest'] = farthest_distance
    dict_taste['closest'] = closest_distance
    dict_taste['average_vec'] = average_taste_vecs[key]
    food_nonaroma_infos[key] = dict_taste


# Now, let's save the average embedding for each nonaroma, as well as the minimum and maximum distance to each nonaroma embedding - we will use these to scale the nonaroma scalars that we obtain for any foods we try to pair wine with.

# In[30]:


food_nonaroma_infos_df = pd.DataFrame(food_nonaroma_infos).T
food_nonaroma_infos_df.to_csv('average_nonaroma_vectors.csv')


# We have all the pieces we need to build our wine recommendations. We will continue with this in a separate notebook.
