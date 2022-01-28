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

package org.oracle.okafka.clients.admin;

import org.oracle.okafka.clients.ClientRequest;
import org.oracle.okafka.clients.ClientResponse;
import org.oracle.okafka.clients.ClientUtils;
import org.oracle.okafka.clients.CommonClientConfigs;
import org.oracle.okafka.clients.KafkaClient;
import org.oracle.okafka.clients.NetworkClient;
import org.oracle.okafka.clients.admin.internals.AdminMetadataManager;
import org.oracle.okafka.common.Cluster;
import org.oracle.okafka.common.KafkaException;
import org.oracle.okafka.common.KafkaFuture;
import org.oracle.okafka.common.Node;
import org.oracle.okafka.common.TopicPartition;
import org.oracle.okafka.common.TopicPartitionReplica;
import org.oracle.okafka.common.acl.AclBinding;
import org.oracle.okafka.common.acl.AclBindingFilter;
import org.oracle.okafka.common.annotation.InterfaceStability;
import org.oracle.okafka.common.config.ConfigResource;
import org.oracle.okafka.common.config.SslConfigs;
import org.oracle.okafka.common.errors.ApiException;
import org.oracle.okafka.common.errors.AuthenticationException;
import org.oracle.okafka.common.errors.FeatureNotSupportedException;
import org.oracle.okafka.common.errors.InvalidLoginCredentialsException;
import org.oracle.okafka.common.errors.InvalidTopicException;
import org.oracle.okafka.common.errors.TimeoutException;
import org.oracle.okafka.common.internals.KafkaFutureImpl;
import org.oracle.okafka.common.metrics.JmxReporter;
import org.oracle.okafka.common.metrics.MetricConfig;
import org.oracle.okafka.common.metrics.Metrics;
import org.oracle.okafka.common.metrics.MetricsReporter;
import org.oracle.okafka.common.metrics.Sensor;
import org.oracle.okafka.common.requests.AbstractRequest;
import org.oracle.okafka.common.requests.AbstractResponse;
import org.oracle.okafka.common.requests.CreateTopicsRequest;
import org.oracle.okafka.common.requests.CreateTopicsResponse;
import org.oracle.okafka.common.requests.DeleteTopicsRequest;
import org.oracle.okafka.common.requests.DeleteTopicsResponse;
import org.oracle.okafka.common.requests.MetadataRequest;
import org.oracle.okafka.common.requests.MetadataResponse;
import org.oracle.okafka.common.utils.AppInfoParser;
import org.oracle.okafka.common.utils.KafkaThread;
import org.oracle.okafka.common.utils.LogContext;
import org.oracle.okafka.common.utils.TNSParser;
import org.oracle.okafka.common.utils.Time;
import org.oracle.okafka.clients.admin.internals.AQKafkaAdmin;
import org.slf4j.Logger;

import static org.oracle.okafka.common.utils.Utils.closeQuietly;

import java.net.InetSocketAddress;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Predicate;

/**
 * The default implementation of {@link AdminClient}. An instance of this class
 * is created by invoking one of the {@code create()} methods in
 * {@code AdminClient}. Users should not refer to this class directly.
 *
 * The API of this class is evolving, see {@link AdminClient} for details.
 * Note: Topic name has to be in uppercase wherever used.
 */
@InterfaceStability.Evolving
public class KafkaAdminClient extends AdminClient {

	/**
	 * The next integer to use to name a KafkaAdminClient which the user hasn't
	 * specified an explicit name for.
	 */
	private static final AtomicInteger ADMIN_CLIENT_ID_SEQUENCE = new AtomicInteger(1);

	/**
	 * The prefix to use for the JMX metrics for this class
	 */
	private static final String JMX_PREFIX = "kafka.admin.client";

	/**
	 * An invalid shutdown time which indicates that a shutdown has not yet been
	 * performed.
	 */
	private static final long INVALID_SHUTDOWN_TIME = -1;

	/**
	 * Thread name prefix for admin client network thread
	 */
	static final String NETWORK_THREAD_PREFIX = "kafka-admin-client-thread";

	private final Logger log;

	/**
	 * The default timeout to use for an operation.
	 */
	private final int defaultTimeoutMs;

	/**
	 * The name of this AdminClient instance.
	 */
	private final String clientId;

	/**
	 * Provides the time.
	 */
	private final Time time;

	/**
	 * The cluster metadata manager used by the KafkaClient.
	 */
	private final AdminMetadataManager metadataManager;
	
	/**
	 * The metrics for this KafkaAdminClient.
	 */
	private final Metrics metrics;

	/**
	 * The network client to use.
	 */
	private final KafkaClient client;

	/**
	 * The runnable used in the service thread for this admin client.
	 */
	private final AdminClientRunnable runnable;

	/**
	 * The network service thread for this admin client.
	 */
	private final Thread thread;

	/**
	 * During a close operation, this is the time at which we will time out all
	 * pending operations and force the RPC thread to exit. If the admin client is
	 * not closing, this will be 0.
	 */
	private final AtomicLong hardShutdownTimeMs = new AtomicLong(INVALID_SHUTDOWN_TIME);

	/**
	 * A factory which creates TimeoutProcessors for the RPC thread.
	 */
	private final TimeoutProcessorFactory timeoutProcessorFactory;

	private final int maxRetries;

	private final long retryBackoffMs;

	/**
	 * Get or create a list value from a map.
	 *
	 * @param map The map to get or create the element from.
	 * @param key The key.
	 * @param     <K> The key type.
	 * @param     <V> The value type.
	 * @return The list value.
	 */
	static <K, V> List<V> getOrCreateListValue(Map<K, List<V>> map, K key) {
		List<V> list = map.get(key);
		if (list != null)
			return list;
		list = new LinkedList<>();
		map.put(key, list);
		return list;
	}

	/**
	 * Send an exception to every element in a collection of KafkaFutureImpls.
	 *
	 * @param futures The collection of KafkaFutureImpl objects.
	 * @param exc     The exception
	 * @param         <T> The KafkaFutureImpl result type.
	 */
	private static <T> void completeAllExceptionally(Collection<KafkaFutureImpl<T>> futures, Throwable exc) {
		for (KafkaFutureImpl<?> future : futures) {
			future.completeExceptionally(exc);
		}
	}

	/**
	 * Get the current time remaining before a deadline as an integer.
	 *
	 * @param now        The current time in milliseconds.
	 * @param deadlineMs The deadline time in milliseconds.
	 * @return The time delta in milliseconds.
	 */
	static int calcTimeoutMsRemainingAsInt(long now, long deadlineMs) {
		long deltaMs = deadlineMs - now;
		if (deltaMs > Integer.MAX_VALUE)
			deltaMs = Integer.MAX_VALUE;
		else if (deltaMs < Integer.MIN_VALUE)
			deltaMs = Integer.MIN_VALUE;
		return (int) deltaMs;
	}

	/**
	 * Generate the client id based on the configuration.
	 *
	 * @param config The configuration
	 *
	 * @return The client id
	 */
	static String generateClientId(AdminClientConfig config) {
		String clientId = config.getString(AdminClientConfig.CLIENT_ID_CONFIG);
		if (!clientId.isEmpty())
			return clientId;
		return "adminclient-" + ADMIN_CLIENT_ID_SEQUENCE.getAndIncrement();
	}

	/**
	 * Get the deadline for a particular call.
	 *
	 * @param now             The current time in milliseconds.
	 * @param optionTimeoutMs The timeout option given by the user.
	 *
	 * @return The deadline in milliseconds.
	 */
	private long calcDeadlineMs(long now, Integer optionTimeoutMs) {
		if (optionTimeoutMs != null)
			return now + Math.max(0, optionTimeoutMs);
		return now + defaultTimeoutMs;
	}

	/**
	 * Pretty-print an exception.
	 *
	 * @param throwable The exception.
	 *
	 * @return A compact human-readable string.
	 */
	static String prettyPrintException(Throwable throwable) {
		if (throwable == null)
			return "Null exception.";
		if (throwable.getMessage() != null) {
			return throwable.getClass().getSimpleName() + ": " + throwable.getMessage();
		}
		return throwable.getClass().getSimpleName();
	}

	static KafkaAdminClient createInternal(AdminClientConfig config, TimeoutProcessorFactory timeoutProcessorFactory) {
		Metrics metrics = null;
		Time time = Time.SYSTEM;
		String clientId = generateClientId(config);
		LogContext logContext = createLogContext(clientId);
        KafkaClient client = null;
		try {
			AdminMetadataManager metadataManager = new AdminMetadataManager(logContext,
					config.getLong(AdminClientConfig.RETRY_BACKOFF_MS_CONFIG),
					config.getLong(AdminClientConfig.METADATA_MAX_AGE_CONFIG));
			List<MetricsReporter> reporters = config
					.getConfiguredInstances(AdminClientConfig.METRIC_REPORTER_CLASSES_CONFIG, MetricsReporter.class);
			Map<String, String> metricTags = Collections.singletonMap("client-id", clientId);
			MetricConfig metricConfig = new MetricConfig()
					.samples(config.getInt(AdminClientConfig.METRICS_NUM_SAMPLES_CONFIG))
					.timeWindow(config.getLong(AdminClientConfig.METRICS_SAMPLE_WINDOW_MS_CONFIG),
							TimeUnit.MILLISECONDS)
					.recordLevel(Sensor.RecordingLevel
							.forName(config.getString(AdminClientConfig.METRICS_RECORDING_LEVEL_CONFIG)))
					.tags(metricTags);
			reporters.add(new JmxReporter(JMX_PREFIX));
			metrics = new Metrics(metricConfig, reporters, time);
			AQKafkaAdmin admin= new AQKafkaAdmin(logContext, config, time);
			client = new NetworkClient(admin, metadataManager.updater(), clientId,
					config.getLong(AdminClientConfig.RECONNECT_BACKOFF_MS_CONFIG),
					config.getLong(AdminClientConfig.RECONNECT_BACKOFF_MAX_MS_CONFIG),
					config.getInt(AdminClientConfig.SEND_BUFFER_CONFIG),
					config.getInt(AdminClientConfig.RECEIVE_BUFFER_CONFIG), (int) TimeUnit.HOURS.toMillis(1), time,
					logContext);
			return new KafkaAdminClient(config, clientId, time, metadataManager, metrics, client,
					timeoutProcessorFactory, logContext);
		} catch (Throwable exc) {
			closeQuietly(metrics, "Metrics");
			closeQuietly(client, "NetworkClient");
			throw new KafkaException("Failed create new KafkaAdminClient", exc);
		}
	}

	static KafkaAdminClient createInternal(AdminClientConfig config, KafkaClient client, Time time) {
		Metrics metrics = null;
		String clientId = generateClientId(config);

		try {
			metrics = new Metrics(new MetricConfig(), new LinkedList<MetricsReporter>(), time);
			LogContext logContext = createLogContext(clientId);
			AdminMetadataManager metadataManager = new AdminMetadataManager(logContext,
					config.getLong(AdminClientConfig.RETRY_BACKOFF_MS_CONFIG),
					config.getLong(AdminClientConfig.METADATA_MAX_AGE_CONFIG));
			return new KafkaAdminClient(config, clientId, time, metadataManager, metrics, client, null, logContext);
		} catch (Throwable exc) {
			closeQuietly(metrics, "Metrics");
			throw new KafkaException("Failed create new KafkaAdminClient", exc);
		}
	}

	static LogContext createLogContext(String clientId) {
		return new LogContext("[AdminClient clientId=" + clientId + "] ");
	}

	private KafkaAdminClient(AdminClientConfig config, String clientId, Time time, AdminMetadataManager metadataManager,
			Metrics metrics, KafkaClient client, TimeoutProcessorFactory timeoutProcessorFactory,
			LogContext logContext) throws Exception {
		this.defaultTimeoutMs = config.getInt(AdminClientConfig.REQUEST_TIMEOUT_MS_CONFIG);
		this.clientId = clientId;
		this.log = logContext.logger(KafkaAdminClient.class);
		this.time = time;
		this.metadataManager = metadataManager;
		
		List<InetSocketAddress> addresses = null;
        String serviceName = null;
        String instanceName = null;
        System.setProperty("oracle.net.tns_admin", config.getString(AdminClientConfig.ORACLE_NET_TNS_ADMIN));
        if( config.getString( CommonClientConfigs.SECURITY_PROTOCOL_CONFIG).equalsIgnoreCase("PLAINTEXT"))
          addresses = ClientUtils.parseAndValidateAddresses(config.getList(AdminClientConfig.BOOTSTRAP_SERVERS_CONFIG));
        else {
     	   if( config.getString(SslConfigs.TNS_ALIAS) == null)
     		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
     	   TNSParser parser = new TNSParser(config);
     	   parser.readFile();
     	   String connStr = parser.getConnectionString(config.getString(SslConfigs.TNS_ALIAS).toUpperCase());
     	   if (connStr == null)
     		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
     	   String host = parser.getProperty(connStr, "HOST");
     	   String  portStr = parser.getProperty(connStr, "PORT");
     	   serviceName = parser.getProperty(connStr, "SERVICE_NAME");
     	   int port;
     	   if( host == null || portStr == null || serviceName == null)
     		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
     	   try {
     	   port = Integer.parseInt(portStr);
     	   } catch(NumberFormatException nfe) {
     		   throw new InvalidLoginCredentialsException("Please provide valid connection string");
     	   }
     	   instanceName = parser.getProperty(connStr, "INSTANCE_NAME");
     	   addresses =  new ArrayList<>();
     	   addresses.add(new InetSocketAddress(host, port));  
        }
		metadataManager.update(Cluster.bootstrap(addresses, config, serviceName, instanceName), time.milliseconds());
		this.metrics = metrics;
		this.client = client;
		this.runnable = new AdminClientRunnable();
		String threadName = NETWORK_THREAD_PREFIX + " | " + clientId;
		this.thread = new KafkaThread(threadName, runnable, true);
		this.timeoutProcessorFactory = (timeoutProcessorFactory == null) ? new TimeoutProcessorFactory()
				: timeoutProcessorFactory;
		this.maxRetries = config.getInt(AdminClientConfig.RETRIES_CONFIG);
		this.retryBackoffMs = config.getLong(AdminClientConfig.RETRY_BACKOFF_MS_CONFIG);
		config.logUnused();
		AppInfoParser.registerAppInfo(JMX_PREFIX, clientId, metrics);
		log.debug("Kafka admin client initialized");
		thread.start();
	}

	Time time() {
		return time;
	}

	@Override
	public void close(long duration, TimeUnit unit) {
		long waitTimeMs = unit.toMillis(duration);
		waitTimeMs = Math.min(TimeUnit.DAYS.toMillis(365), waitTimeMs); // Limit the timeout to a year.
		long now = time.milliseconds();
		long newHardShutdownTimeMs = now + waitTimeMs;
		long prev = INVALID_SHUTDOWN_TIME;
		while (true) {
			if (hardShutdownTimeMs.compareAndSet(prev, newHardShutdownTimeMs)) {
				if (prev == INVALID_SHUTDOWN_TIME) {
					log.debug("Initiating close operation.");
				} else {
					log.debug("Moving hard shutdown time forward.");
				}
				break;
			}
			prev = hardShutdownTimeMs.get();
			if (prev < newHardShutdownTimeMs) {
				log.debug("Hard shutdown time is already earlier than requested.");
				newHardShutdownTimeMs = prev;
				break;
			}
		}
		if (log.isDebugEnabled()) {
			long deltaMs = Math.max(0, newHardShutdownTimeMs - time.milliseconds());
			log.debug("Waiting for the I/O thread to exit. Hard shutdown in {} ms.", deltaMs);
		}
		try {
			// Wait for the thread to be joined.
			thread.join();

			AppInfoParser.unregisterAppInfo(JMX_PREFIX, clientId, metrics);

			log.debug("Kafka admin client closed.");
		} catch (InterruptedException e) {
			log.debug("Interrupted while joining I/O thread", e);
			Thread.currentThread().interrupt();
		}
	}

	/**
	 * An interface for providing a node for a call.
	 */
	private interface NodeProvider {
		Node provide();
	}

	private class MetadataUpdateNodeIdProvider implements NodeProvider {
		@Override
		public Node provide() {
			return client.leastLoadedNode(time.milliseconds());
		}
	}

	private class ConstantNodeIdProvider implements NodeProvider {
		private final int nodeId;

		ConstantNodeIdProvider(int nodeId) {
			this.nodeId = nodeId;
		}

		@Override
		public Node provide() {
			if (metadataManager.isReady() && (metadataManager.nodeById(nodeId) != null)) {
				return metadataManager.nodeById(nodeId);
			}
			// If we can't find the node with the given constant ID, we schedule a
			// metadata update and hope it appears. This behavior is useful for avoiding
			// flaky behavior in tests when the cluster is starting up and not all nodes
			// have appeared.
			metadataManager.requestUpdate();
			return null;
		}
	}

	/**
	 * Provides the controller node.
	 */
	private class ControllerNodeProvider implements NodeProvider {
		@Override
		public Node provide() {
			if (metadataManager.isReady() && (metadataManager.controller() != null)) {
				return metadataManager.controller();
			}
			metadataManager.requestUpdate();
			return null;
		}
	}

	/**
	 * Provides the least loaded node.
	 */
	private class LeastLoadedNodeProvider implements NodeProvider {
		@Override
		public Node provide() {
			if (metadataManager.isReady()) {
				// This may return null if all nodes are busy.
				// In that case, we will postpone node assignment.
				return client.leastLoadedNode(time.milliseconds());
			}
			metadataManager.requestUpdate();
			return null;
		}
	}

	abstract class Call {
		private final boolean internal;
		private final String callName;
		private final long deadlineMs;
		private final NodeProvider nodeProvider;
		private int tries = 0;
		private boolean aborted = false;
		private Node curNode = null;
		private long nextAllowedTryMs = 0;

		Call(boolean internal, String callName, long deadlineMs, NodeProvider nodeProvider) {
			this.internal = internal;
			this.callName = callName;
			this.deadlineMs = deadlineMs;
			this.nodeProvider = nodeProvider;
		}

		Call(String callName, long deadlineMs, NodeProvider nodeProvider) {
			this(false, callName, deadlineMs, nodeProvider);
		}

		protected Node curNode() {
			return curNode;
		}

		/**
		 * Handle a failure.
		 *
		 * Depending on what the exception is and how many times we have already tried,
		 * we may choose to fail the Call, or retry it.
		 *
		 * @param now       The current time in milliseconds.
		 * @param throwable The failure exception.
		 */
		final void fail(long now, Throwable throwable) {

			// If the call has timed out, fail.
			if (calcTimeoutMsRemainingAsInt(now, deadlineMs) < 0) {
				if (log.isDebugEnabled()) {
					log.debug("{} timed out at {} after {} attempt(s)", this, now, tries,
							new Exception(prettyPrintException(throwable)));
				}
				handleFailure(throwable);
				return;
			}
			handleFailure(throwable);
		}

		/**
		 * Create an AbstractRequest.Builder for this Call.
		 *
		 * @param timeoutMs The timeout in milliseconds.
		 *
		 * @return The AbstractRequest builder.
		 */
		abstract AbstractRequest.Builder createRequest(int timeoutMs);

		/**
		 * Process the call response.
		 *
		 * @param abstractResponse The AbstractResponse.
		 *
		 */
		abstract void handleResponse(AbstractResponse abstractResponse);

		/**
		 * Handle a failure. This will only be called if the failure exception was not
		 * retryable, or if we hit a timeout.
		 *
		 * @param throwable The exception.
		 */
		abstract void handleFailure(Throwable throwable);

		@Override
		public String toString() {
			return "Call(callName=" + callName + ", deadlineMs=" + deadlineMs + ")";
		}

		public boolean isInternal() {
			return internal;
		}
	}

	static class TimeoutProcessorFactory {
		TimeoutProcessor create(long now) {
			return new TimeoutProcessor(now);
		}
	}

	static class TimeoutProcessor {
		/**
		 * The current time in milliseconds.
		 */
		private final long now;

		/**
		 * The number of milliseconds until the next timeout.
		 */
		private int nextTimeoutMs;

		/**
		 * Create a new timeout processor.
		 *
		 * @param now The current time in milliseconds since the epoch.
		 */
		TimeoutProcessor(long now) {
			this.now = now;
			this.nextTimeoutMs = Integer.MAX_VALUE;
		}

		/**
		 * Check for calls which have timed out. Timed out calls will be removed and
		 * failed. The remaining milliseconds until the next timeout will be updated.
		 *
		 * @param calls The collection of calls.
		 *
		 * @return The number of calls which were timed out.
		 */
		int handleTimeouts(Collection<Call> calls, String msg) {
			int numTimedOut = 0;
			for (Iterator<Call> iter = calls.iterator(); iter.hasNext();) {
				Call call = iter.next();
				int remainingMs = calcTimeoutMsRemainingAsInt(now, call.deadlineMs);
				if (remainingMs < 0) {
					call.fail(now, new TimeoutException(msg));
					iter.remove();
					numTimedOut++;
				} else {
					nextTimeoutMs = Math.min(nextTimeoutMs, remainingMs);
				}
			}
			return numTimedOut;
		}
		
		/**
		 * Timeout all the calls.
		 *
		 * @param calls The collection of calls.
		 *
		 * @return The number of calls which were timed out.
		 */
		int timeoutAll(Collection<Call> calls, String msg) {
			int numTimedOut = 0;
			for (Iterator<Call> iter = calls.iterator(); iter.hasNext();) {
				Call call = iter.next();
				call.fail(now, new TimeoutException(msg));
				iter.remove();
				numTimedOut++;
			}
			return numTimedOut;
		}

		/**
		 * Check whether a call should be timed out. The remaining milliseconds until
		 * the next timeout will be updated.
		 *
		 * @param call The call.
		 *
		 * @return True if the call should be timed out.
		 */
		boolean callHasExpired(Call call) {
			int remainingMs = calcTimeoutMsRemainingAsInt(now, call.deadlineMs);
			if (remainingMs < 0)
				return true;
			nextTimeoutMs = Math.min(nextTimeoutMs, remainingMs);
			return false;
		}

		int nextTimeoutMs() {
			return nextTimeoutMs;
		}
	}

	private final class AdminClientRunnable implements Runnable {
		/**
		 * Calls which have not yet been assigned to a node. Only accessed from this
		 * thread.
		 */
		private final ArrayList<Call> pendingCalls = new ArrayList<>();

		/**
		 * Maps nodes to calls that we want to send. Only accessed from this thread.
		 */
		private final Map<Node, List<Call>> callsToSend = new HashMap<>();

		/**
		 * Pending calls. Protected by the object monitor. This will be null only if the
		 * thread has shut down.
		 */
		private List<Call> newCalls = new LinkedList<>();

		/**
		 * Time out the elements in the pendingCalls list which are expired.
		 *
		 * @param processor The timeout processor.
		 */
		private void timeoutPendingCalls(TimeoutProcessor processor) {
			int numTimedOut = processor.handleTimeouts(pendingCalls, "Timed out waiting for a node assignment.");
			if (numTimedOut > 0)
				log.debug("Timed out {} pending calls.", numTimedOut);
		}

		/**
		 * Time out calls which have been assigned to nodes.
		 *
		 * @param processor The timeout processor.
		 */
		private int timeoutCallsToSend(TimeoutProcessor processor) {
			int numTimedOut = 0;
			for (List<Call> callList : callsToSend.values()) {
				numTimedOut += processor.handleTimeouts(callList, "Timed out waiting to send the call.");
			}
			if (numTimedOut > 0)
				log.debug("Timed out {} call(s) with assigned nodes.", numTimedOut);
			return numTimedOut;
		}
		
		/**
		 * Time out calls which have been assigned to nodes.
		 *
		 * @param processor The timeout processor.
		 */
		private int timeoutAllCallsToSend(TimeoutProcessor processor, String msg) {
			int numTimedOut = 0;
			for (List<Call> callList : callsToSend.values()) {
				numTimedOut += processor.timeoutAll(callList, msg);
			}
			if (numTimedOut > 0)
				log.debug("Timed out {} call(s) with assigned nodes.", numTimedOut);
			return numTimedOut;
		}

		/**
		 * Drain all the calls from newCalls into pendingCalls.
		 *
		 * This function holds the lock for the minimum amount of time, to avoid
		 * blocking users of AdminClient who will also take the lock to add new calls.
		 */
		private synchronized void drainNewCalls() {
			if (!newCalls.isEmpty()) {
				pendingCalls.addAll(newCalls);
				newCalls.clear();
			}
		}

		/**
		 * Choose nodes for the calls in the pendingCalls list.
		 *
		 * @param now The current time in milliseconds.
		 * @return The minimum time until a call is ready to be retried if any of the
		 *         pending calls are backing off after a failure
		 */
		private long maybeDrainPendingCalls(long now) {
			long pollTimeout = Long.MAX_VALUE;
			log.trace("Trying to choose nodes for {} at {}", pendingCalls, now);

			Iterator<Call> pendingIter = pendingCalls.iterator();
			while (pendingIter.hasNext()) {
				Call call = pendingIter.next();

				// If the call is being retried, await the proper backoff before finding the
				// node
				if (now < call.nextAllowedTryMs) {
					pollTimeout = Math.min(pollTimeout, call.nextAllowedTryMs - now);
				} else if (maybeDrainPendingCall(call, now)) {
					pendingIter.remove();
				}
			}
			return pollTimeout;
		}

		/**
		 * Check whether a pending call can be assigned a node. Return true if the
		 * pending call was either transferred to the callsToSend collection or if the
		 * call was failed. Return false if it should remain pending.
		 */
		private boolean maybeDrainPendingCall(Call call, long now) {
			try {
				Node node = call.nodeProvider.provide();
				if (node != null) {
					log.trace("Assigned {} to node {}", call, node);
					call.curNode = node;
					getOrCreateListValue(callsToSend, node).add(call);
					return true;
				} else {
					log.trace("Unable to assign {} to a node.", call);
					return false;
				}
			} catch (Throwable t) {
				// Handle authentication errors while choosing nodes.
				log.debug("Unable to choose node for {}", call, t);
				call.fail(now, t);
				return true;
			}
		}

		/**
		 * Send the calls which are ready.
		 *
		 * @param now The current time in milliseconds.
		 * @return The minimum timeout we need for poll().
		 */
		private void sendEligibleCalls(long now) {

			for (Iterator<Map.Entry<Node, List<Call>>> iter = callsToSend.entrySet().iterator(); iter.hasNext();) {
				Map.Entry<Node, List<Call>> entry = iter.next();
				List<Call> calls = entry.getValue();
				if (calls.isEmpty()) {
					iter.remove();
					continue;
				}
				Node node = entry.getKey();
				try {
					if (!client.ready(node, now)) {
						long nodeTimeout = client.pollDelayMs(node, now);
						log.trace("Client is not ready to send to {}. Must delay {} ms", node, nodeTimeout);
						continue;
					}
				} catch(InvalidLoginCredentialsException ilc) {
					calls.remove(0).fail(now, new AuthenticationException(ilc.getMessage()));
					continue;
				}
				Call call = calls.remove(0);
				int timeoutMs = calcTimeoutMsRemainingAsInt(now, call.deadlineMs);
				if(timeoutMs< 0) {
					call.fail(now, new TimeoutException("Timed out waiting to send the call."));
					continue;
				}
				
				AbstractRequest.Builder<?> requestBuilder = null;
				try {
					requestBuilder = call.createRequest(timeoutMs);
				} catch (Throwable throwable) {
					call.fail(now,
							new KafkaException(String.format("Internal error sending %s to %s.", call.callName, node)));
					continue;
				}
				ClientRequest clientRequest = client.newClientRequest(node, requestBuilder, now, true);
				log.trace("Sending {} to {}. correlationId={}", requestBuilder, node, clientRequest.correlationId());
				ClientResponse response = client.send(clientRequest, now);
				log.trace("Received response for {} from {}. correlationId={}", requestBuilder, node, response.requestHeader().correlationId());
				handleResponse(time.milliseconds(), call, response);
			}
		}


		/**
		 * Handle responses from the server.
		 *
		 * @param now       The current time in milliseconds.
		 * @param responses The latest responses from KafkaClient.
		 **/
		private void handleResponse(long now, Call call, ClientResponse response) {

			try {
				    if(response.wasDisconnected()) {
				    	client.disconnected(response.destination(), now);
				    	metadataManager.requestUpdate();
				    	
				    }
					call.handleResponse(response.responseBody());
				} catch (Throwable t) {
					if (log.isTraceEnabled())
						log.trace("{} handleResponse failed with {}", call, prettyPrintException(t));
					call.fail(now, t);
				}
		}
		
		private boolean hasActiveExternalCalls(Collection<Call> calls) {
			for (Call call : calls) {
				if (!call.isInternal()) {
					return true;
				}
			}
			return false;
		}
		
		/**
		 * Return true if there are currently active external calls.
		 */
		private boolean hasActiveExternalCalls() {
			if (hasActiveExternalCalls(pendingCalls)) {
				return true;
			}
			for (List<Call> callList : callsToSend.values()) {
				if (hasActiveExternalCalls(callList)) {
					return true;
				}
			}
			return false;
		}


		private boolean threadShouldExit(long now, long curHardShutdownTimeMs) {
			if (!hasActiveExternalCalls()) {
				log.trace("All work has been completed, and the I/O thread is now exiting.");
				return true;
			}
			if (now >= curHardShutdownTimeMs) {
				log.info("Forcing a hard I/O thread shutdown. Requests in progress will be aborted.");
				return true;
			}
			log.debug("Hard shutdown in {} ms.", curHardShutdownTimeMs - now);
			return false;
		}

		@Override
		public void run() {
			long now = time.milliseconds();
			log.trace("Thread starting");
			while (true) {
				// Copy newCalls into pendingCalls.
				drainNewCalls();

				// Check if the AdminClient thread should shut down.
				long curHardShutdownTimeMs = hardShutdownTimeMs.get();
				if ((curHardShutdownTimeMs != INVALID_SHUTDOWN_TIME) && threadShouldExit(now, curHardShutdownTimeMs))
					break;

				// Handle timeouts.
				TimeoutProcessor timeoutProcessor = timeoutProcessorFactory.create(now);
				timeoutPendingCalls(timeoutProcessor);
				timeoutCallsToSend(timeoutProcessor);
				
				maybeDrainPendingCalls(now);
				
				long metadataFetchDelayMs = metadataManager.metadataFetchDelayMs(now);
				if (metadataFetchDelayMs == 0) {
					metadataManager.transitionToUpdatePending(now);
					Call metadataCall = makeMetadataCall(now);
					// Create a new metadata fetch call and add it to the end of pendingCalls.
					// Assign a node for just the new call (we handled the other pending nodes
					// above).

					if (!maybeDrainPendingCall(metadataCall, now))
						pendingCalls.add(metadataCall);
				}

				sendEligibleCalls(now);
				unassignUnsentCalls(client::connectionFailed);
				now = time.milliseconds();
			}
			int numTimedOut = 0;
			TimeoutProcessor timeoutProcessor = new TimeoutProcessor(Long.MAX_VALUE);
			
			numTimedOut += timeoutProcessor.timeoutAll(pendingCalls, "The AdminClient thread has exited.");
			numTimedOut += timeoutAllCallsToSend(timeoutProcessor, "The AdminClient thread has exited.");
			synchronized (this) {
				numTimedOut += timeoutProcessor.timeoutAll(newCalls, "The AdminClient thread has exited.");
				newCalls = null;
			}
			if (numTimedOut > 0) {
				log.debug("Timed out {} remaining operation(s).", numTimedOut);
			}
			//closeQuietly(client, "KafkaClient");
			try {
				client.close();
			} catch(Exception e) {
				log.trace("Failed to close network client");
			}
			
			closeQuietly(metrics, "Metrics");
			log.debug("Exiting AdminClientRunnable thread.");
		}

		/**
		 * Queue a call for sending.
		 *
		 * If the AdminClient thread has exited, this will fail. Otherwise, it will
		 * succeed (even if the AdminClient is shutting down). This function should
		 * called when retrying an existing call.
		 *
		 * @param call The new call object.
		 * @param now  The current time in milliseconds.
		 */
		void enqueue(Call call, long now) {
			if (log.isDebugEnabled()) {
				log.debug("Queueing {} with a timeout {} ms from now.", call, call.deadlineMs - now);
			}
			boolean accepted = false;
			synchronized (this) {
				if (newCalls != null) {
					newCalls.add(call);
					accepted = true;
				}
			}
			if (!accepted) {
				log.debug("The AdminClient thread has exited. Timing out {}.", call);
				call.fail(Long.MAX_VALUE, new TimeoutException("The AdminClient thread has exited.")); 
			} 
		}

		/**
		 * Initiate a new call.
		 *
		 * This will fail if the AdminClient is scheduled to shut down.
		 *
		 * @param call The new call object.
		 * @param now  The current time in milliseconds.
		 */
		void call(Call call, long now) {
			if (hardShutdownTimeMs.get() != INVALID_SHUTDOWN_TIME) {
				log.debug("The AdminClient is not accepting new calls. Timing out {}.", call);
				call.fail(Long.MAX_VALUE, new TimeoutException("The AdminClient thread is not accepting new calls."));
			} else {
				enqueue(call, now);
			}
		}
		
		/**
		 * Create a new metadata call.
		 */
		private Call makeMetadataCall(long now) {
			return new Call(true, "fetchMetadata", calcDeadlineMs(now, defaultTimeoutMs),
					new MetadataUpdateNodeIdProvider()) {
				@Override
				public AbstractRequest.Builder createRequest(int timeoutMs) {
					// Since this only requests node information, it's safe to pass true
					// for allowAutoTopicCreation (and it simplifies communication with
					// older brokers)
					return new MetadataRequest.Builder(Collections.<String>emptyList(), true);
				}

				@Override
				public void handleResponse(AbstractResponse abstractResponse) {
					MetadataResponse response = (MetadataResponse) abstractResponse;
					long now = time.milliseconds();
					metadataManager.update(response.cluster(null), now);

					// Unassign all unsent requests after a metadata refresh to allow for a new
					// destination to be selected from the new metadata
					unassignUnsentCalls(node -> true);
				}

				@Override
				public void handleFailure(Throwable e) {
					metadataManager.updateFailed(e);
				}
			};
		}
		
		/**
		 * Unassign calls that have not yet been sent based on some predicate. For
		 * example, this is used to reassign the calls that have been assigned to a
		 * disconnected node.
		 *
		 * @param shouldUnassign Condition for reassignment. If the predicate is true,
		 *                       then the calls will be put back in the pendingCalls
		 *                       collection and they will be reassigned
		 */
		private void unassignUnsentCalls(Predicate<Node> shouldUnassign) {
			for (Iterator<Map.Entry<Node, List<Call>>> iter = callsToSend.entrySet().iterator(); iter.hasNext();) {
				Map.Entry<Node, List<Call>> entry = iter.next();
				Node node = entry.getKey();
				List<Call> awaitingCalls = entry.getValue();

				if (awaitingCalls.isEmpty()) {
					iter.remove();
				} else if (shouldUnassign.test(node)) {
					pendingCalls.addAll(awaitingCalls);
					iter.remove();
				}
			}
		}

	
	}

	private static boolean topicNameIsUnrepresentable(String topicName) {
		return topicName == null || topicName.isEmpty();
	}

	private static boolean groupIdIsUnrepresentable(String groupId) {
		return groupId == null;
	}

	@Override
	public CreateTopicsResult createTopics(final Collection<NewTopic> newTopics, final CreateTopicsOptions options) {
		final Map<String, KafkaFutureImpl<Void>> topicFutures = new HashMap<>(newTopics.size());
		final Map<String, CreateTopicsRequest.TopicDetails> topicsMap = new HashMap<>(newTopics.size());
		for (NewTopic newTopic : newTopics) {
			if (topicNameIsUnrepresentable(newTopic.name())) {
				KafkaFutureImpl<Void> future = new KafkaFutureImpl<>();
				future.completeExceptionally(new InvalidTopicException(
						"The given topic name '" + newTopic.name() + "' cannot be represented in a request."));
				topicFutures.put(newTopic.name(), future);
			} else if (!topicFutures.containsKey(newTopic.name())) {
				topicFutures.put(newTopic.name(), new KafkaFutureImpl<Void>());
				topicsMap.put(newTopic.name(), newTopic.convertToTopicDetails());
			}
		}
		final long now = time.milliseconds();
		Call call = new Call("createTopics", calcDeadlineMs(now, options.timeoutMs()), new ControllerNodeProvider()) {

			@Override
			public AbstractRequest.Builder createRequest(int timeoutMs) {
				return new CreateTopicsRequest.Builder(topicsMap, timeoutMs, options.shouldValidateOnly());
			}

			@Override
			public void handleResponse(AbstractResponse abstractResponse) {
				CreateTopicsResponse response = (CreateTopicsResponse) abstractResponse;
				// Handle server responses for particular topics.
				for (Map.Entry<String, Exception> entry : response.errors().entrySet()) {
					KafkaFutureImpl<Void> future = topicFutures.get(entry.getKey());
					if (future == null) {
						log.warn("Server response mentioned unknown topic {}", entry.getKey());
					} else {
						Exception exception = entry.getValue();
						if (exception != null) {
						    future.completeExceptionally(exception);
						} else {
							future.complete(null);
						}
					}
				}
				// The server should send back a response for every topic. But do a sanity check
				// anyway.
				for (Map.Entry<String, KafkaFutureImpl<Void>> entry : topicFutures.entrySet()) {
					KafkaFutureImpl<Void> future = entry.getValue();
					if (!future.isDone()) {
					    if(response.getResult() != null) {
					    	future.completeExceptionally(response.getResult());
					    } else future.completeExceptionally(new ApiException(
								"The server response did not " + "contain a reference to node " + entry.getKey()));
					}
				}
			}

			@Override
			void handleFailure(Throwable throwable) {
				completeAllExceptionally(topicFutures.values(), throwable);
			}
		};
		if (!topicsMap.isEmpty()) {
			runnable.call(call, now);
		}
		return new CreateTopicsResult(new HashMap<String, KafkaFuture<Void>>(topicFutures));
	}

	@Override
	public DeleteTopicsResult deleteTopics(Collection<String> topicNames, DeleteTopicsOptions options) {
		final Map<String, KafkaFutureImpl<Void>> topicFutures = new HashMap<>(topicNames.size());
		final List<String> validTopicNames = new ArrayList<>(topicNames.size());
		for (String topicName : topicNames) {
			if (topicNameIsUnrepresentable(topicName)) {
				KafkaFutureImpl<Void> future = new KafkaFutureImpl<>();
				future.completeExceptionally(new InvalidTopicException(
						"The given topic name '" + topicName + "' cannot be represented in a request."));
				topicFutures.put(topicName, future);
			} else if (!topicFutures.containsKey(topicName)) {
				topicFutures.put(topicName, new KafkaFutureImpl<Void>());
				validTopicNames.add(topicName);
			}
		}
		final long now = time.milliseconds();
		Call call = new Call("deleteTopics", calcDeadlineMs(now, options.timeoutMs()), new ControllerNodeProvider()) {

			@Override
			AbstractRequest.Builder createRequest(int timeoutMs) {
				return new DeleteTopicsRequest.Builder(new HashSet<>(validTopicNames), timeoutMs);
			}

			@Override
			void handleResponse(AbstractResponse abstractResponse) {
				DeleteTopicsResponse response = (DeleteTopicsResponse) abstractResponse;
				// Handle server responses for particular topics.
				for (Map.Entry<String, SQLException> entry : response.errors().entrySet()) {
					KafkaFutureImpl<Void> future = topicFutures.get(entry.getKey());
					if (future == null) {
						log.warn("Server response mentioned unknown topic {}", entry.getKey());
					} else {
						SQLException exception = entry.getValue();
						if (exception != null) {
							future.completeExceptionally(new KafkaException(exception.getMessage()));
						} else {
							future.complete(null);
						}
					}
				}
				// The server should send back a response for every topic. But do a sanity check
				// anyway.
				for (Map.Entry<String, KafkaFutureImpl<Void>> entry : topicFutures.entrySet()) {
					KafkaFutureImpl<Void> future = entry.getValue();
					if (!future.isDone()) {
						if(response.getResult() != null) {
					    	future.completeExceptionally(response.getResult());
					    } else future.completeExceptionally(new ApiException(
								"The server response did not " + "contain a reference to node " + entry.getKey()));
					}
				}
			}

			@Override
			void handleFailure(Throwable throwable) {
				completeAllExceptionally(topicFutures.values(), throwable);
			}
		};
		if (!validTopicNames.isEmpty()) {
			runnable.call(call, now);
		}
		return new DeleteTopicsResult(new HashMap<String, KafkaFuture<Void>>(topicFutures));
	}

	@Override
	public ListTopicsResult listTopics(final ListTopicsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeTopicsResult describeTopics(final Collection<String> topicNames, DescribeTopicsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeClusterResult describeCluster(DescribeClusterOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeAclsResult describeAcls(final AclBindingFilter filter, DescribeAclsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public CreateAclsResult createAcls(Collection<AclBinding> acls, CreateAclsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DeleteAclsResult deleteAcls(Collection<AclBindingFilter> filters, DeleteAclsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeConfigsResult describeConfigs(Collection<ConfigResource> configResources,
			final DescribeConfigsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public AlterConfigsResult alterConfigs(Map<ConfigResource, Config> configs, final AlterConfigsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public AlterReplicaLogDirsResult alterReplicaLogDirs(Map<TopicPartitionReplica, String> replicaAssignment,
			final AlterReplicaLogDirsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeLogDirsResult describeLogDirs(Collection<Integer> brokers, DescribeLogDirsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeReplicaLogDirsResult describeReplicaLogDirs(Collection<TopicPartitionReplica> replicas,
			DescribeReplicaLogDirsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public CreatePartitionsResult createPartitions(Map<String, NewPartitions> newPartitions,
			final CreatePartitionsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DeleteRecordsResult deleteRecords(final Map<TopicPartition, RecordsToDelete> recordsToDelete,
			final DeleteRecordsOptions options) {

		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public CreateDelegationTokenResult createDelegationToken(final CreateDelegationTokenOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public RenewDelegationTokenResult renewDelegationToken(final byte[] hmac,
			final RenewDelegationTokenOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public ExpireDelegationTokenResult expireDelegationToken(final byte[] hmac,
			final ExpireDelegationTokenOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeDelegationTokenResult describeDelegationToken(final DescribeDelegationTokenOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DescribeConsumerGroupsResult describeConsumerGroups(final Collection<String> groupIds,
			final DescribeConsumerGroupsOptions options) {

		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public ListConsumerGroupsResult listConsumerGroups(ListConsumerGroupsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public ListConsumerGroupOffsetsResult listConsumerGroupOffsets(final String groupId,
			final ListConsumerGroupOffsetsOptions options) {
		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}

	@Override
	public DeleteConsumerGroupsResult deleteConsumerGroups(Collection<String> groupIds,
			DeleteConsumerGroupsOptions options) {

		throw new FeatureNotSupportedException("This feature is not suported for this release.");
	}
}
