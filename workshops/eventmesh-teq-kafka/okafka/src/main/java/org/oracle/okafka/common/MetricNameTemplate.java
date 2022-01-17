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

package org.oracle.okafka.common;

import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Objects;
import java.util.Set;

import org.oracle.okafka.common.utils.Utils;

/**
 * Metrics Feature is not yet supported.
 */
public class MetricNameTemplate {
    private final String name;
    private final String group;
    private final String description;
    private LinkedHashSet<String> tags;

    public MetricNameTemplate(String name, String group, String description, Set<String> tagsNames) {
        this.name = Utils.notNull(name);
        this.group = Utils.notNull(group);
        this.description = Utils.notNull(description);
        this.tags = new LinkedHashSet<>(Utils.notNull(tagsNames));
    }

    public MetricNameTemplate(String name, String group, String description, String... tagsNames) {
        this(name, group, description, getTags(tagsNames));
    }

    private static LinkedHashSet<String> getTags(String... keys) {
        LinkedHashSet<String> tags = new LinkedHashSet<>();

        Collections.addAll(tags, keys);

        return tags;
    }

    public String name() {
        return this.name;
    }

    public String group() {
        return this.group;
    }

    public String description() {
        return this.description;
    }

    public Set<String> tags() {
        return tags;
    }

    @Override
    public int hashCode() {
        return Objects.hash(name, group, tags);
    }

    @Override
    public boolean equals(Object o) {
        if (this == o)
            return true;
        if (o == null || getClass() != o.getClass())
            return false;
        MetricNameTemplate other = (MetricNameTemplate) o;
        return Objects.equals(name, other.name) && Objects.equals(group, other.group) &&
                Objects.equals(tags, other.tags);
    }

    @Override
    public String toString() {
        return String.format("name=%s, group=%s, tags=%s", name, group, tags);
    }
}
