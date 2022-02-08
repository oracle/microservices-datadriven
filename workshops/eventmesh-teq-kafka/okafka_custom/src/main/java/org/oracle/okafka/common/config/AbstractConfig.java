/*
** OKafka Java Client version 0.8.
**
** Copyright (c) 2019, 2020 Oracle and/or its affiliates.
** Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl.
*/

/*
 * Licensed to the Apache Software Foundation (ASF) under one or more
 * contributor license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright ownership.
 * The ASF licenses this file to You under the Apache License, Version 2.0
 * (the "License"); you may not use this file except in compliance with
 * the License. You may obtain a copy of the License at
 *
 *    http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

/*
 * 04/20/2020: This file is modified to support Kafka Java Client compatability to Oracle Transactional Event Queues.
 *
 */

package org.oracle.okafka.common.config;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.HashMap;
import java.util.Set;
import java.util.TreeMap;

import org.oracle.okafka.common.Configurable;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.utils.Utils;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/** 
 * A convenient base class for configurations to extend.
 * This class holds both the original configuration that was provided as well as the parsed
 *
 */
public class AbstractConfig {

	   private final Logger log = LoggerFactory.getLogger(getClass());

	    /* configs for which values have been requested, used to detect unused configs */
	    private final Set<String> used;

	    /* the original values passed in by the user */
	    private final Map<String, ?> originals;

	    /* the parsed values */
	    private final Map<String, Object> values;

	    private final ConfigDef definition;

	    @SuppressWarnings("unchecked")
	    public AbstractConfig(ConfigDef definition, Map<?, ?> originals, boolean doLog) {
	        /* check that all the keys are really strings */
	        for (Map.Entry<?, ?> entry : originals.entrySet())
	            if (!(entry.getKey() instanceof String))
	                throw new ConfigException(entry.getKey().toString(), entry.getValue(), "Key must be a string.");
	        this.originals = (Map<String, ?>) originals;
	        this.values = definition.parse(this.originals);
	        Map<String, Object> configUpdates = postProcessParsedConfig(Collections.unmodifiableMap(this.values));
	        for (Map.Entry<String, Object> update : configUpdates.entrySet()) {
	            this.values.put(update.getKey(), update.getValue());
	        }
	        definition.parse(this.values);
	        this.used = Collections.synchronizedSet(new HashSet<String>());
	        this.definition = definition;
	        if (doLog)
	            logAll();
	    }

	    public AbstractConfig(ConfigDef definition, Map<?, ?> originals) {
	        this(definition, originals, true);
	    }

	    public Object get(String key)
	    {
	    	if(!values.containsKey(key))
	    		throw new ConfigException(String.format("Unknown configuration %s", key));
	    	used.add(key);
	    	return values.get(key);
	    }
	    
	    public Integer getInt(String key)
	    {
	    	return (Integer)get(key);
	    }
	    
	    public Long getLong(String key)
	    {
	    	return (Long)get(key);
	    }
	    
	    public Short getShort(String key)
	    {
	    	return (Short)get(key);
	    }
	    public String getString(String key)
	    {
	    	return (String)get(key);
        }
	    
	    public Class<?> getClass(String key)
	    {
	    	return (Class<?>)get(key);
	    }
	    
	    @SuppressWarnings("unchecked")
	    public List<String> getList(String key) {
	        return (List<String>) get(key);
	    }
	    
	    public Boolean getBoolean(String key) {
	        return (Boolean) get(key);
	    }

	    public void ignore(String key) {
	        used.add(key);
	    }
	    
	    public Map<String, Object> originals() {
	        Map<String, Object> copy = new RecordingMap<>();
	        copy.putAll(originals);
	        return copy;
	    }
	    
	    protected Map<String, Object> postProcessParsedConfig(Map<String, Object> parsedValues) {
	        return Collections.emptyMap();
	    }
	    
	    /**
	     * Log warnings for any unused configurations
	     */
	    public void logUnused() {
	        for (String key : unused())
	            log.warn("The configuration '{}' was supplied but isn't a known config.", key);
	    }
	    
	    public Set<String> unused() {
	        Set<String> keys = new HashSet<>(originals.keySet());
	        keys.removeAll(used);
	        return keys;
	    }
	    
	    private void logAll() {
	        StringBuilder b = new StringBuilder();
	        b.append(getClass().getSimpleName());
	        b.append(" values: ");
	        b.append(Utils.NL);

	        for (Map.Entry<String, Object> entry : new TreeMap<>(this.values).entrySet()) {
	            b.append('\t');
	            b.append(entry.getKey());
	            b.append(" = ");
	            b.append(entry.getValue());
	            b.append(Utils.NL);
	        }
	        log.info(b.toString());
	    }
	    
	    /**
	     * Get a configured instance of the give class specified by the given configuration key. If the object implements
	     * Configurable configure it using the configuration.
	     *
	     * @param key The configuration key for the class
	     * @param t The interface the class should implement
	     * @return A configured instance of the class
	     */
	    public <T> T getConfiguredInstance(String key, Class<T> t) {
	        Class<?> c = getClass(key);
	        if (c == null)
	            return null;
	        Object o = Utils.newInstance(c);
	        if (!t.isInstance(o))
	            throw new KafkaException(c.getName() + " is not an instance of " + t.getName());
	        if (o instanceof Configurable)
	            ((Configurable) o).configure(originals());
	        return t.cast(o);
	    }

	    /**
	     * Get a list of configured instances of the given class specified by the given configuration key. The configuration
	     * may specify either null or an empty string to indicate no configured instances. In both cases, this method
	     * returns an empty list to indicate no configured instances.
	     * @param key The configuration key for the class
	     * @param t The interface the class should implement
	     * @return The list of configured instances
	     */
	    public <T> List<T> getConfiguredInstances(String key, Class<T> t) {
	        return getConfiguredInstances(key, t, Collections.<String, Object>emptyMap());
	    }

	    /**
	     * Get a list of configured instances of the given class specified by the given configuration key. The configuration
	     * may specify either null or an empty string to indicate no configured instances. In both cases, this method
	     * returns an empty list to indicate no configured instances.
	     * @param key The configuration key for the class
	     * @param t The interface the class should implement
	     * @param configOverrides Configuration overrides to use.
	     * @return The list of configured instances
	     */
	    public <T> List<T> getConfiguredInstances(String key, Class<T> t, Map<String, Object> configOverrides) {
	        return getConfiguredInstances(getList(key), t, configOverrides);
	    }


	    /**
	     * Get a list of configured instances of the given class specified by the given configuration key. The configuration
	     * may specify either null or an empty string to indicate no configured instances. In both cases, this method
	     * returns an empty list to indicate no configured instances.
	     * @param classNames The list of class names of the instances to create
	     * @param t The interface the class should implement
	     * @param configOverrides Configuration overrides to use.
	     * @return The list of configured instances
	     */
	    public <T> List<T> getConfiguredInstances(List<String> classNames, Class<T> t, Map<String, Object> configOverrides) {
	        List<T> objects = new ArrayList<T>();
	        if (classNames == null)
	            return objects;
	        Map<String, Object> configPairs = originals();
	        configPairs.putAll(configOverrides);
	        for (Object klass : classNames) {
	            Object o;
	            if (klass instanceof String) {
	                try {
	                    o = Utils.newInstance((String) klass, t);
	                } catch (ClassNotFoundException e) {
	                    throw new KafkaException(klass + " ClassNotFoundException exception occurred", e);
	                }
	            } else if (klass instanceof Class<?>) {
	                o = Utils.newInstance((Class<?>) klass);
	            } else
	                throw new KafkaException("List contains element of type " + klass.getClass().getName() + ", expected String or Class");
	            if (!t.isInstance(o))
	                throw new KafkaException(klass + " is not an instance of " + t.getName());
	            if (o instanceof Configurable)
	                ((Configurable) o).configure(configPairs);
	            objects.add(t.cast(o));
	        }
	        return objects;
	    }
	    
	    @Override
	    public boolean equals(Object o) {
	        if (this == o) return true;
	        if (o == null || getClass() != o.getClass()) return false;

	        AbstractConfig that = (AbstractConfig) o;

	        return originals.equals(that.originals);
	    }

	    @Override
	    public int hashCode() {
	        return originals.hashCode();
	    }
	    
	    /**
	     * Marks keys retrieved via `get` as used. This is needed because `Configurable.configure` takes a `Map` instead
	     * of an `AbstractConfig` and we can't change that without breaking public API like `Partitioner`.
	     */
	    private class RecordingMap<V> extends HashMap<String, V> {

	        private final String prefix;
	        private final boolean withIgnoreFallback;

	         RecordingMap() {
	            this("", false);
	        }

	        RecordingMap(String prefix, boolean withIgnoreFallback) {
	            this.prefix = prefix;
	            this.withIgnoreFallback = withIgnoreFallback;
	        }

	        RecordingMap(Map<String, ? extends V> m) {
	            this(m, "", false);
	        }

	        RecordingMap(Map<String, ? extends V> m, String prefix, boolean withIgnoreFallback) {
	            super(m);
	            this.prefix = prefix;
	            this.withIgnoreFallback = withIgnoreFallback;
	        }

	        @Override
	        public V get(Object key) {
	            if (key instanceof String) {
	                String stringKey = (String) key;
	                String keyWithPrefix;
	                if (prefix.isEmpty()) {
	                    keyWithPrefix = stringKey;
	                } else {
	                    keyWithPrefix = prefix + stringKey;
	                }
	                ignore(keyWithPrefix);
	                if (withIgnoreFallback)
	                    ignore(stringKey);
	            }
	            return super.get(key);
	        }
	    }
	    
}
