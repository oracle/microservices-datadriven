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
 */

package org.oracle.okafka.clients;

import java.util.HashMap;
import java.util.Map;

import org.oracle.okafka.common.config.AbstractConfig;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

/**
 * Some configurations shared by both producer and consumer
 */
public class CommonClientConfigs {
	private static final Logger log = LoggerFactory.getLogger(CommonClientConfigs.class);

    /*
     * NOTE: DO NOT CHANGE EITHER CONFIG NAMES AS THESE ARE PART OF THE PUBLIC API AND CHANGE WILL BREAK USER CODE.
     */

    public static final String BOOTSTRAP_SERVERS_CONFIG = "bootstrap.servers";
    public static final String BOOTSTRAP_SERVERS_DOC = "A host/port pair to use for establishing the connection to the TEQ. If list of host/port pairs of form  <code>host1:port1,host2:port2,...</code> are provieded then only first pair is used for connecting to cluster. "
                                                       + "The client uses only the first pair for connection. So it should be up and running.";

    // TODO include credentials (user/password)
    public static final String ORACLE_USER_NAME ="oracle.user.name";
    public static final String ORACLE_PASSWORD ="oracle.password";


    public static final String ORACLE_SERVICE_NAME ="oracle.service.name";
    public static final String ORACLE_SERVICE_NAME_DOC = "name of the service running on the oracle database instance.";
    public static final String ORACLE_INSTANCE_NAME ="oracle.instance.name";
    public static final String ORACLE_INSTANCE_NAME_DOC = "instance name of the oracle database instance to connect to";
    public static final String ORACLE_NET_TNS_ADMIN = "oracle.net.tns_admin";
	public static final String ORACLE_NET_TNS_ADMIN_DOC = "location of file tnsnames.ora and ojdbc.properties";
    public static final String METADATA_MAX_AGE_CONFIG = "metadata.max.age.ms";
    public static final String METADATA_MAX_AGE_DOC = "The period of time in milliseconds after which we force a refresh of metadata even if we haven't seen any partition leadership changes to proactively discover any new brokers or partitions.";

    public static final String SEND_BUFFER_CONFIG = "send.buffer.bytes";
    public static final String SEND_BUFFER_DOC = "The size of the TCP send buffer (SO_SNDBUF) to use when sending data. If the value is -1, the OS default will be used. This property is not yet supported.";

    public static final String RECEIVE_BUFFER_CONFIG = "receive.buffer.bytes";
    public static final String RECEIVE_BUFFER_DOC = "The size of the TCP receive buffer (SO_RCVBUF) to use when reading data. If the value is -1, the OS default will be used. This property is not yet supported.";

    public static final String CLIENT_ID_CONFIG = "client.id";
    public static final String CLIENT_ID_DOC = "An id string to pass to the server when making requests. The purpose of this is to be able to track the source of requests beyond just ip/port by allowing a logical application name to be included in server-side request logging.";

    public static final String RECONNECT_BACKOFF_MS_CONFIG = "reconnect.backoff.ms";
    public static final String RECONNECT_BACKOFF_MS_DOC = "The base amount of time to wait before attempting to reconnect to a given host. This avoids repeatedly connecting to a host in a tight loop. This backoff applies to all connection attempts by the client to a broker.";

    public static final String RECONNECT_BACKOFF_MAX_MS_CONFIG = "reconnect.backoff.max.ms";
    public static final String RECONNECT_BACKOFF_MAX_MS_DOC = "The maximum amount of time in milliseconds to wait when reconnecting to a broker that has repeatedly failed to connect. If provided, the backoff per host will increase exponentially for each consecutive connection failure, up to this maximum. After calculating the backoff increase, 20% random jitter is added to avoid connection storms.";
    public static final String RETRIES_CONFIG = "retries";
    public static final String RETRIES_DOC = "Setting a value greater than zero will cause the client to resend any request that fails with a potentially transient error.";

    public static final String RETRY_BACKOFF_MS_CONFIG = "retry.backoff.ms";
    public static final String RETRY_BACKOFF_MS_DOC = "The amount of time to wait before attempting to retry a failed request to a given topic partition. This avoids repeatedly sending requests in a tight loop under some failure scenarios.";
 
    public static final String METRICS_SAMPLE_WINDOW_MS_CONFIG = "metrics.sample.window.ms";
    public static final String METRICS_SAMPLE_WINDOW_MS_DOC = "The window of time a metrics sample is computed over. This property is not yet supported.";

    public static final String METRICS_NUM_SAMPLES_CONFIG = "metrics.num.samples";
    public static final String METRICS_NUM_SAMPLES_DOC = "The number of samples maintained to compute metrics. This property is not yet supported.";

    public static final String METRICS_RECORDING_LEVEL_CONFIG = "metrics.recording.level";
    public static final String METRICS_RECORDING_LEVEL_DOC = "The highest recording level for metrics. This property is not yet supported.";

    public static final String METRIC_REPORTER_CLASSES_CONFIG = "metric.reporters";
    public static final String METRIC_REPORTER_CLASSES_DOC = "A list of classes to use as metrics reporters. Implementing the <code>org.oracle.okafka.common.metrics.MetricsReporter</code> interface allows plugging in classes that will be notified of new metric creation. The JmxReporter is always included to register JMX statistics.";
    
    public static final String SECURITY_PROTOCOL_CONFIG = "security.protocol";
    public static final String SECURITY_PROTOCOL_DOC = "Protocol used to communicate with brokers. This property is not yet supported.";
    public static final String DEFAULT_SECURITY_PROTOCOL = "PLAINTEXT";

    public static final String CONNECTIONS_MAX_IDLE_MS_CONFIG = "connections.max.idle.ms";
    public static final String CONNECTIONS_MAX_IDLE_MS_DOC = "Close idle connections after the number of milliseconds specified by this config.This property is not yet supported.";

    public static final String REQUEST_TIMEOUT_MS_CONFIG = "request.timeout.ms";
    public static final String REQUEST_TIMEOUT_MS_DOC = "The configuration controls the maximum amount of time the client will wait "
                                                         + "for the response of a request. If the response is not received before the timeout "
                                                         + "elapses the client will resend the request if necessary or fail the request if "
                                                         + "retries are exhausted. This property is not yet supported.";

    /**
     * Postprocess the configuration so that exponential backoff is disabled when reconnect backoff
     * is explicitly configured but the maximum reconnect backoff is not explicitly configured.
     *
     * @param config                    The config object.
     * @param parsedValues              The parsedValues as provided to postProcessParsedConfig.
     *
     * @return                          The new values which have been set as described in postProcessParsedConfig.
     */
    public static Map<String, Object> postProcessReconnectBackoffConfigs(AbstractConfig config,
                                                    Map<String, Object> parsedValues) {
        HashMap<String, Object> rval = new HashMap<>();
        if ((!config.originals().containsKey(RECONNECT_BACKOFF_MAX_MS_CONFIG)) &&
                config.originals().containsKey(RECONNECT_BACKOFF_MS_CONFIG)) {
            log.debug("Disabling exponential reconnect backoff because " + RECONNECT_BACKOFF_MS_CONFIG +
                " is set, but " + RECONNECT_BACKOFF_MAX_MS_CONFIG + " is not.");
            rval.put(RECONNECT_BACKOFF_MAX_MS_CONFIG, parsedValues.get(RECONNECT_BACKOFF_MS_CONFIG));
        }
        return rval;
    }  
}
