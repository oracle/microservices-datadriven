package oracle.observability.metrics;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.dataformat.toml.TomlMapper;
import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import io.prometheus.client.CollectorRegistry;
import io.prometheus.client.Counter;
import io.prometheus.client.Gauge;
import io.prometheus.client.Collector;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.oracle.rlb.MetricsAccumulator;

import java.io.File;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.nio.charset.Charset;
import java.sql.Connection;
import java.sql.ResultSet;
import java.util.*;

public class OracleDBMetricsExporter {
    static final Counter totalRequests = Counter.build().name("total_requests").help("Total requests.").register();
    static final Gauge inprogressRequests = Gauge.build().name("inprogress_requests").help("Inprogress requests.").register();


    /**
     Context          string
     Labels           []string
     MetricsDesc      map[string]string
     MetricsType      map[string]string
     MetricsBuckets   map[string]map[string]string
     FieldToAppend    string
     Request          string
     IgnoreZeroResult bool


     - name: DEFAULT_METRICS
     value: /msdataworkshop/observability/db-metrics-%EXPORTER_NAME%-exporter-metrics.toml
     #            - name: CUSTOM_METRICS
     #              value: /msdataworkshop/observability/db-metrics-%EXPORTER_NAME%-exporter-metrics.toml
     - name: TNS_ADMIN
     value: "/msdataworkshop/creds"
     #          value: "/lib/oracle/instantclient_19_3/client64/lib/network/admin"
     - name: dbpassword
     valueFrom:
     secretKeyRef:
     name: dbuser
     key: dbpassword
     optional: true
     - name: DATA_SOURCE_NAME
     #              value: "admin/$(dbpassword)@%PDB_NAME%_tp"
     value: "%USER%/$(dbpassword)@%PDB_NAME%_tp"
     volumeMounts:
     - name: creds
     mountPath: /msdataworkshop/creds
     #          mountPath: /lib/oracle/instantclient_19_3/client64/lib/network/admin # 19.10

     *
     *
     *
     *
     * need to support all of these combos as doced for backward compat...
     * # export Oracle location:
     * export DATA_SOURCE_NAME=system/password@oracle-sid
     * # or using a complete url:
     * export DATA_SOURCE_NAME=user/password@//myhost:1521/service
     * # 19c client for primary/standby configuration
     * export DATA_SOURCE_NAME=user/password@//primaryhost:1521,standbyhost:1521/service
     * # 19c client for primary/standby configuration with options
     * export DATA_SOURCE_NAME=user/password@//primaryhost:1521,standbyhost:1521/service?connect_timeout=5&transport_connect_timeout=3&retry_count=3
     * # 19c client for ASM instance connection (requires SYSDBA)
     * export DATA_SOURCE_NAME=user/password@//primaryhost:1521,standbyhost:1521/+ASM?as=sysdba
     *
     * Usage of oracledb_exporter:
     *   --log.format value
     *        	If set use a syslog logger or JSON logging. Example: logger:syslog?appname=bob&local=7 or logger:stdout?json=true. Defaults to stderr.
     *   --log.level value
     *        	Only log messages with the given severity or above. Valid levels: [debug, info, warn, error, fatal].
     *   --custom.metrics string
     *         File that may contain various custom metrics in a TOML file.
     *   --default.metrics string
     *         Default TOML file metrics.
     *   --web.listen-address string
     *        	Address to listen on for web interface and telemetry. (default ":9161")
     *   --web.telemetry-path string
     *        	Path under which to expose metrics. (default "/metrics")
     *   --database.maxIdleConns string
     *         Number of maximum idle connections in the connection pool. (default "0")
     *   --database.maxOpenConns string
     *         Number of maximum open connections in the connection pool. (default "10")
     *   --web.secured-metrics  boolean
     *         Expose metrics using https server. (default "false")
     *   --web.ssl-server-cert string
     *         Path to the PEM encoded certificate file.
     *   --web.ssl-server-key string
     *         Path to the PEM encoded key file.
     *
     *
     */

//    String dbuser = System.getenv("dbuser");
//    String dbpassword = System.getenv("dbpassword");
    String DATA_SOURCE_NAME = System.getenv("DATA_SOURCE_NAME"); //eg %USER%/$(dbpassword)@%PDB_NAME%_tp
    String TNS_ADMIN = System.getenv("TNS_ADMIN");  //eg /msdataworkshop/creds
    String DEFAULT_METRICS = System.getenv("DEFAULT_METRICS");  //eg /msdataworkshop/creds
    String CUSTOM_METRICS = System.getenv("CUSTOM_METRICS");  //eg /msdataworkshop/creds

    PoolDataSource atpBankPDB ;

    private PoolDataSource getPoolDataSource()  throws Exception {
        if(atpBankPDB!=null) return atpBankPDB;
        atpBankPDB = PoolDataSourceFactory.getPoolDataSource();
        atpBankPDB.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
        //todo parse DATA_SOURCE_NAME
        String user = DATA_SOURCE_NAME.substring(0, DATA_SOURCE_NAME.indexOf("/"));
        String pw = DATA_SOURCE_NAME.substring(DATA_SOURCE_NAME.indexOf("/") + 1, DATA_SOURCE_NAME.indexOf("@"));
        String serviceName = DATA_SOURCE_NAME.substring(DATA_SOURCE_NAME.indexOf("@") + 1);
        String bankdburl ="jdbc:oracle:thin:@" + serviceName + "?TNS_ADMIN=" + TNS_ADMIN;
        System.out.println("OracleDBMetricsExporter.getPoolDataSource bankdburl:" + bankdburl);
        atpBankPDB.setURL(bankdburl);
        atpBankPDB.setUser(user);
        atpBankPDB.setPassword(pw);
        System.out.println("bank atpBankPDB:" + atpBankPDB);
        return atpBankPDB;
    }

    public void init() throws Exception {
        int port = 8080;
        HttpServer httpServer = com.sun.net.httpserver.HttpServer.create(new InetSocketAddress(port), 0);
        // Test urls
        httpServer.createContext("/", new MetricsHandler());
        httpServer.start();
        System.out.println("Server ready on http://127.0.0.1:" + port);

        Connection connection  = getPoolDataSource().getConnection();
        System.out.println("OracleDBMetricsExporter connection:" + connection);
        System.out.println("OracleDBMetricsExporter DEFAULT_METRICS:" + DEFAULT_METRICS);
        System.out.println("OracleDBMetricsExporter CUSTOM_METRICS:" + CUSTOM_METRICS);
        File tomlfile = new File(DEFAULT_METRICS);
//                "/Users/pparkins/go/src/github.com/paulparkinson/microservices-datadriven/cloudbank/observability/db-metrics-exporter/db-metrics-banka-exporter-metrics.toml");
        TomlMapper mapper = new TomlMapper();
        JsonNode jsonNode = mapper.readerFor(MetricEntry.class).readTree(new FileInputStream(tomlfile));
        Iterator<JsonNode> metric = jsonNode.get("metric").iterator();
        String context, labels, metricsdesc,request, ignorezeroresult;
        while (metric.hasNext()) {
            JsonNode next = metric.next();
            context = next.get("context").asText();
            labels = next.get("labels")==null?"false":next.get("labels").asText();//this is an array
            metricsdesc = next.get("metricsdesc").asText();
            request = next.get("request").asText();
            ignorezeroresult = next.get("ignorezeroresult")==null?"false":next.get("ignorezeroresult").asText();
            System.out.println("OracleDBMetricsExporter.init context:"+context);
            ResultSet resultSet = connection.prepareStatement(request).executeQuery();
            while (resultSet.next()) {
                int columnCount = resultSet.getMetaData().getColumnCount();
                for (int i=0;i<columnCount;i++) {
                    //usually... name and label same , typename is 2/NUMBER or 12/VARCHAR2
                    System.out.println("OracleDBMetricsExporter.init resultSet.getObject(i+1):" + resultSet.getObject(i+1));
                    System.out.println("OracleDBMetricsExporter.init resultSet.getColumnName(i+1):" + resultSet.getMetaData().getColumnName(i+1));
                    System.out.println("OracleDBMetricsExporter.init resultSet.getColumnType(i+1):" + resultSet.getMetaData().getColumnType(i+1));
                    System.out.println("OracleDBMetricsExporter.init resultSet.getColumnTypeName(i+1):" + resultSet.getMetaData().getColumnTypeName(i+1));
                    System.out.println("OracleDBMetricsExporter.init resultSet.getColumnLabel(i+1):" + resultSet.getMetaData().getColumnLabel(i+1));
                    ;
                }
            }
//            System.out.println("OracleDBMetricsExporter.init context:"+context+
//                    ", metricsdesc:"+ metricsdesc + ", request:"+request +", ignorezeroresult:"+ ignorezeroresult);
        }

        /**
         key bits...
         collect sql query with column name as key in map...
         https://github.com/iamseth/oracledb_exporter/blob/5fc3b515f9822976c85bcfc4a305bf75bc13cfcb/main.go#L479
         parse metrics from that  map[string]string...
         https://github.com/iamseth/oracledb_exporter/blob/5fc3b515f9822976c85bcfc4a305bf75bc13cfcb/main.go#L354

         */

        inprogressRequests.inc();
        totalRequests.inc();
        collectorNames(inprogressRequests);
        collectorNames(totalRequests);
        getValues(inprogressRequests);
        getValues(totalRequests);
  //      System.out.println("OracleDBMetricsExporter.init getMetricsString():" + getMetricsString());
        /**


         [[metric]]
         context = "teq"
         labels = ["inst_id", "queue_name", "subscriber_name"]
         metricsdesc = { enqueued_msgs = "Total enqueued messages.", dequeued_msgs = "Total dequeued messages.", remained_msgs = "Total remained messages.", time_since_last_dequeue = "Time since last dequeue.", estd_time_to_drain_no_enq = "Estimated time to drain if no enqueue.", message_latency_1 = "Message latency for last 5 mins.", message_latency_2 = "Message latency for last 1 hour.", message_latency_3 = "Message latency for last 5 hours."}
         request = '''
         SELECT DISTINCT
         t1.inst_id,
         t1.queue_id,
         t2.queue_name,
         t1.subscriber_id AS subscriber_name,
         t1.enqueued_msgs,
         t1.dequeued_msgs,
         t1.remained_msgs,
         t1.message_latency_1,
         t1.message_latency_2,
         t1.message_latency_3
         FROM
         (
         SELECT
         inst_id,
         queue_id,
         subscriber_id,
         SUM(enqueued_msgs) AS enqueued_msgs,
         SUM(dequeued_msgs) AS dequeued_msgs,
         SUM(enqueued_msgs - dequeued_msgs) AS remained_msgs,
         AVG(10) AS message_latency_1,
         AVG(20) AS message_latency_2,
         AVG(30) AS message_latency_3
         FROM
         gv$persistent_subscribers
         GROUP BY
         queue_id,
         subscriber_id,
         inst_id
         ) t1
         JOIN gv$persistent_queues t2 ON t1.queue_id = t2.queue_id
         '''

         GIVES, eg...

         oracledb_teq_remained_msgs

         oracledb_[context]_[valuefromselect]
         add labels from the array provided

         context = "teq"
         labels = ["inst_id", "queue_name", "subscriber_name"]

         # HELP oracledb_teq_remained_msgs Total remained messages.
         # TYPE oracledb_teq_remained_msgs gauge
         oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 5
         oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 13
         oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 0

         */
    }
    private List<String> collectorNames(Collector collector) {
        List<Collector.MetricFamilySamples> mfs;
        boolean autoDescribe = true;
        if (collector instanceof Collector.Describable) {
            mfs = ((Collector.Describable) collector).describe();
        } else if (autoDescribe) {
            mfs = collector.collect();
        } else {
            mfs = Collections.emptyList();
        }
        List<String> names = new ArrayList<String>();
        for (Collector.MetricFamilySamples family : mfs) {
            switch (family.type) {
                case SUMMARY:
                    names.add(family.name + "_count");
                    names.add(family.name + "_sum");
                    names.add(family.name);
                    break;
                case HISTOGRAM:
                    names.add(family.name + "_count");
                    names.add(family.name + "_sum");
                    names.add(family.name + "_bucket");
                    names.add(family.name);
                    break;
                default:
                    names.add(family.name);
            }
        }
        return names;
    }

    public Map<Map<String, String>, Double> getValues(Collector metric) {
        Map<Map<String, String>, Double> result = new HashMap<>();
        for (Collector.MetricFamilySamples samples : metric.collect()) {
            for (Collector.MetricFamilySamples.Sample sample : samples.samples) {
                Map<String, String> labels = new HashMap<>();
                for (int i = 0; i < sample.labelNames.size(); i++) {
                    labels.put(sample.labelNames.get(i), sample.labelValues.get(i));
                }
                result.put(labels, sample.value);
            }
        }
        return result;
    }


    public class MetricsHandler implements HttpHandler {
        @Override
        public void handle(HttpExchange exchange) throws IOException {
            System.out.println("MetricsHandler.handle");
            String response =  getMetricsString();
            exchange.sendResponseHeaders(200, response.length());
            OutputStream os = exchange.getResponseBody();
            os.write(response.getBytes(Charset.defaultCharset()));
            os.close();
        }
    }


    private String getMetricsString() {
//        Set<String> filters = new HashSet<>(req.queryParams().all("name[]"));
        Set<String> filters = new HashSet<>();
        CollectorRegistry collectorRegistry = CollectorRegistry.defaultRegistry;
        Enumeration<Collector.MetricFamilySamples> mfs = collectorRegistry.filteredMetricFamilySamples(filters);
//        res.headers().contentType(CONTENT_TYPE);
//        res.send(compose(mfs));
        return compose(mfs);
    }

    /**
     * Compose the text version 0.0.4 of the given MetricFamilySamples.
     */
    private static String compose(Enumeration<Collector.MetricFamilySamples> mfs) {
        /* See http://prometheus.io/docs/instrumenting/exposition_formats/
         * for the output format specification. */
        StringBuilder result = new StringBuilder();
        while (mfs.hasMoreElements()) {
            Collector.MetricFamilySamples metricFamilySamples = mfs.nextElement();
            result.append("# HELP ")
                    .append(metricFamilySamples.name)
                    .append(' ');
            appendEscapedHelp(result, metricFamilySamples.help);
            result.append('\n');

            result.append("# TYPE ")
                    .append(metricFamilySamples.name)
                    .append(' ')
                    .append(typeString(metricFamilySamples.type))
                    .append('\n');

            for (Collector.MetricFamilySamples.Sample sample: metricFamilySamples.samples) {
                result.append(sample.name);
                if (!sample.labelNames.isEmpty()) {
                    result.append('{');
                    for (int i = 0; i < sample.labelNames.size(); ++i) {
                        result.append(sample.labelNames.get(i))
                                .append("=\"");
                        appendEscapedLabelValue(result, sample.labelValues.get(i));
                        result.append("\",");
                    }
                    result.append('}');
                }
                result.append(' ')
                        .append(Collector.doubleToGoString(sample.value))
                        .append('\n');
            }
        }
        return result.toString();
    }

    private static void appendEscapedHelp(StringBuilder sb, String s) {
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\':
                    sb.append("\\\\");
                    break;
                case '\n':
                    sb.append("\\n");
                    break;
                default:
                    sb.append(c);
            }
        }
    }

    private static void appendEscapedLabelValue(StringBuilder sb, String s) {
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '\\':
                    sb.append("\\\\");
                    break;
                case '\"':
                    sb.append("\\\"");
                    break;
                case '\n':
                    sb.append("\\n");
                    break;
                default:
                    sb.append(c);
            }
        }
    }

    private static String typeString(Collector.Type t) {
        switch (t) {
            case GAUGE:
                return "gauge";
            case COUNTER:
                return "counter";
            case SUMMARY:
                return "summary";
            case HISTOGRAM:
                return "histogram";
            default:
                return "untyped";
        }
    }

}

/**
 # HELP go_gc_duration_seconds A summary of the GC invocation durations.
 # TYPE go_gc_duration_seconds summary
 go_gc_duration_seconds{quantile="0"} 3.2421e-05
 go_gc_duration_seconds{quantile="0.25"} 4.7641e-05
 go_gc_duration_seconds{quantile="0.5"} 6.1035e-05
 go_gc_duration_seconds{quantile="0.75"} 0.00012294
 go_gc_duration_seconds{quantile="1"} 0.000239659
 go_gc_duration_seconds_sum 0.00055388
 go_gc_duration_seconds_count 6
 # HELP go_goroutines Number of goroutines that currently exist.
 # TYPE go_goroutines gauge
 go_goroutines 9
 # HELP go_info Information about the Go environment.
 # TYPE go_info gauge
 go_info{version="go1.14.15"} 1
 # HELP go_memstats_alloc_bytes Number of bytes allocated and still in use.
 # TYPE go_memstats_alloc_bytes gauge
 go_memstats_alloc_bytes 3.955256e+06
 # HELP go_memstats_alloc_bytes_total Total number of bytes allocated, even if freed.
 # TYPE go_memstats_alloc_bytes_total counter
 go_memstats_alloc_bytes_total 1.4990424e+07
 # HELP go_memstats_buck_hash_sys_bytes Number of bytes used by the profiling bucket hash table.
 # TYPE go_memstats_buck_hash_sys_bytes gauge
 go_memstats_buck_hash_sys_bytes 1.447274e+06
 # HELP go_memstats_frees_total Total number of frees.
 # TYPE go_memstats_frees_total counter
 go_memstats_frees_total 176595
 # HELP go_memstats_gc_cpu_fraction The fraction of this program's available CPU time used by the GC since the program started.
 # TYPE go_memstats_gc_cpu_fraction gauge
 go_memstats_gc_cpu_fraction 7.168172706287853e-06
 # HELP go_memstats_gc_sys_bytes Number of bytes used for garbage collection system metadata.
 # TYPE go_memstats_gc_sys_bytes gauge
 go_memstats_gc_sys_bytes 3.574024e+06
 # HELP go_memstats_heap_alloc_bytes Number of heap bytes allocated and still in use.
 # TYPE go_memstats_heap_alloc_bytes gauge
 go_memstats_heap_alloc_bytes 3.955256e+06
 # HELP go_memstats_heap_idle_bytes Number of heap bytes waiting to be used.
 # TYPE go_memstats_heap_idle_bytes gauge
 go_memstats_heap_idle_bytes 6.1489152e+07
 # HELP go_memstats_heap_inuse_bytes Number of heap bytes that are in use.
 # TYPE go_memstats_heap_inuse_bytes gauge
 go_memstats_heap_inuse_bytes 4.702208e+06
 # HELP go_memstats_heap_objects Number of allocated objects.
 # TYPE go_memstats_heap_objects gauge
 go_memstats_heap_objects 26891
 # HELP go_memstats_heap_released_bytes Number of heap bytes released to OS.
 # TYPE go_memstats_heap_released_bytes gauge
 go_memstats_heap_released_bytes 6.1374464e+07
 # HELP go_memstats_heap_sys_bytes Number of heap bytes obtained from system.
 # TYPE go_memstats_heap_sys_bytes gauge
 go_memstats_heap_sys_bytes 6.619136e+07
 # HELP go_memstats_last_gc_time_seconds Number of seconds since 1970 of last garbage collection.
 # TYPE go_memstats_last_gc_time_seconds gauge
 go_memstats_last_gc_time_seconds 1.6524112031002352e+09
 # HELP go_memstats_lookups_total Total number of pointer lookups.
 # TYPE go_memstats_lookups_total counter
 go_memstats_lookups_total 0
 # HELP go_memstats_mallocs_total Total number of mallocs.
 # TYPE go_memstats_mallocs_total counter
 go_memstats_mallocs_total 203486
 # HELP go_memstats_mcache_inuse_bytes Number of bytes in use by mcache structures.
 # TYPE go_memstats_mcache_inuse_bytes gauge
 go_memstats_mcache_inuse_bytes 3472
 # HELP go_memstats_mcache_sys_bytes Number of bytes used for mcache structures obtained from system.
 # TYPE go_memstats_mcache_sys_bytes gauge
 go_memstats_mcache_sys_bytes 16384
 # HELP go_memstats_mspan_inuse_bytes Number of bytes in use by mspan structures.
 # TYPE go_memstats_mspan_inuse_bytes gauge
 go_memstats_mspan_inuse_bytes 60248
 # HELP go_memstats_mspan_sys_bytes Number of bytes used for mspan structures obtained from system.
 # TYPE go_memstats_mspan_sys_bytes gauge
 go_memstats_mspan_sys_bytes 81920
 # HELP go_memstats_next_gc_bytes Number of heap bytes when next garbage collection will take place.
 # TYPE go_memstats_next_gc_bytes gauge
 go_memstats_next_gc_bytes 4.344288e+06
 # HELP go_memstats_other_sys_bytes Number of bytes used for other system allocations.
 # TYPE go_memstats_other_sys_bytes gauge
 go_memstats_other_sys_bytes 729742
 # HELP go_memstats_stack_inuse_bytes Number of bytes in use by the stack allocator.
 # TYPE go_memstats_stack_inuse_bytes gauge
 go_memstats_stack_inuse_bytes 917504
 # HELP go_memstats_stack_sys_bytes Number of bytes obtained from system for stack allocator.
 # TYPE go_memstats_stack_sys_bytes gauge
 go_memstats_stack_sys_bytes 917504
 # HELP go_memstats_sys_bytes Number of bytes obtained from system.
 # TYPE go_memstats_sys_bytes gauge
 go_memstats_sys_bytes 7.2958208e+07
 # HELP go_threads Number of OS threads created.
 # TYPE go_threads gauge
 go_threads 17
 # HELP oracledb_activity_value Generic counter metric from gv$sysstat view in Oracle.
 # TYPE oracledb_activity_value gauge
 oracledb_activity_value{inst_id="4",name="execute count"} 4.564542e+06
 oracledb_activity_value{inst_id="4",name="parse count (total)"} 4.885457e+06
 oracledb_activity_value{inst_id="4",name="user commits"} 2631
 oracledb_activity_value{inst_id="4",name="user rollbacks"} 20
 # HELP oracledb_asm_diskgroup_free Free space available on ASM disk group.
 # TYPE oracledb_asm_diskgroup_free gauge
 oracledb_asm_diskgroup_free{inst_id="4",name="DATA"} 8.95444053917696e+14
 oracledb_asm_diskgroup_free{inst_id="4",name="RECO"} 3.79687872233472e+14
 # HELP oracledb_asm_diskgroup_total Total size of ASM disk group.
 # TYPE oracledb_asm_diskgroup_total gauge
 oracledb_asm_diskgroup_total{inst_id="4",name="DATA"} 1.579740511076352e+15
 oracledb_asm_diskgroup_total{inst_id="4",name="RECO"} 3.94896473063424e+14
 # HELP oracledb_bankpdb_sessions_value Gauge metric with count of bankpdb sessions by status and type.
 # TYPE oracledb_bankpdb_sessions_value gauge
 oracledb_bankpdb_sessions_value{inst_id="4",status="ACTIVE",type="USER"} 6
 oracledb_bankpdb_sessions_value{inst_id="4",status="INACTIVE",type="USER"} 8
 # HELP oracledb_bankqueue_dequeuerate_count_value  number of messages dequeued from bank queue
 # TYPE oracledb_bankqueue_dequeuerate_count_value gauge
 oracledb_bankqueue_dequeuerate_count_value 0
 # HELP oracledb_bankqueue_enqueuerate_count_value  number of messages enqueued to bank queue by
 # TYPE oracledb_bankqueue_enqueuerate_count_value gauge
 oracledb_bankqueue_enqueuerate_count_value 0
 # HELP oracledb_bankqueue_messages_by_state_value Total number of messages in bank queue by state
 # TYPE oracledb_bankqueue_messages_by_state_value gauge
 oracledb_bankqueue_messages_by_state_value{state="0"} 3
 # HELP oracledb_exporter_last_scrape_duration_seconds Duration of the last scrape of metrics from Oracle DB.
 # TYPE oracledb_exporter_last_scrape_duration_seconds gauge
 oracledb_exporter_last_scrape_duration_seconds 5.094380854
 # HELP oracledb_exporter_last_scrape_error Whether the last scrape of metrics from Oracle DB resulted in an error (1 for error, 0 for success).
 # TYPE oracledb_exporter_last_scrape_error gauge
 oracledb_exporter_last_scrape_error 0
 # HELP oracledb_exporter_scrape_errors_total Total number of times an error occured scraping a Oracle database.
 # TYPE oracledb_exporter_scrape_errors_total counter
 oracledb_exporter_scrape_errors_total{collector="activity"} 4
 oracledb_exporter_scrape_errors_total{collector="asm_diskgroup"} 4
 oracledb_exporter_scrape_errors_total{collector="bankpdb_sessions"} 3
 oracledb_exporter_scrape_errors_total{collector="bankqueue_dequeuerate_count"} 3
 oracledb_exporter_scrape_errors_total{collector="bankqueue_enqueuerate_count"} 3
 oracledb_exporter_scrape_errors_total{collector="bankqueue_messages_by_state"} 3
 oracledb_exporter_scrape_errors_total{collector="ownership"} 3
 oracledb_exporter_scrape_errors_total{collector="process"} 3
 oracledb_exporter_scrape_errors_total{collector="sessions"} 3
 oracledb_exporter_scrape_errors_total{collector="system"} 30
 oracledb_exporter_scrape_errors_total{collector="system_network"} 9
 oracledb_exporter_scrape_errors_total{collector="teq"} 12
 oracledb_exporter_scrape_errors_total{collector="wait_class"} 3
 # HELP oracledb_exporter_scrapes_total Total number of times Oracle DB was scraped for metrics.
 # TYPE oracledb_exporter_scrapes_total counter
 oracledb_exporter_scrapes_total 30
 # HELP oracledb_ownership_inst_id Owner instance of the current queues.
 # TYPE oracledb_ownership_inst_id gauge
 oracledb_ownership_inst_id 4
 # HELP oracledb_process_count Gauge metric with count of processes.
 # TYPE oracledb_process_count gauge
 oracledb_process_count{inst_id="4"} 15
 # HELP oracledb_sessions_value Gauge metric with count of sessions by status and type.
 # TYPE oracledb_sessions_value gauge
 oracledb_sessions_value{inst_id="4",status="ACTIVE",type="USER"} 7
 oracledb_sessions_value{inst_id="4",status="INACTIVE",type="USER"} 7
 # HELP oracledb_system_network_received_from_client Bytes received from client.
 # TYPE oracledb_system_network_received_from_client gauge
 oracledb_system_network_received_from_client{inst_id="4"} 7.41296844e+08
 # HELP oracledb_system_network_sent_to_client Bytes sent to client.
 # TYPE oracledb_system_network_sent_to_client gauge
 oracledb_system_network_sent_to_client{inst_id="4"} 1.273105574e+09
 # HELP oracledb_teq_curr_inst_id ID of current instance
 # TYPE oracledb_teq_curr_inst_id gauge
 oracledb_teq_curr_inst_id 4
 # HELP oracledb_teq_dequeued_msgs Total dequeued messages.
 # TYPE oracledb_teq_dequeued_msgs gauge
 oracledb_teq_dequeued_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 8
 oracledb_teq_dequeued_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 0
 oracledb_teq_dequeued_msgs{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 1
 # HELP oracledb_teq_enqueued_msgs Total enqueued messages.
 # TYPE oracledb_teq_enqueued_msgs gauge
 oracledb_teq_enqueued_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 13
 oracledb_teq_enqueued_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 13
 oracledb_teq_enqueued_msgs{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 1
 # HELP oracledb_teq_message_latency_1 Message latency for last 5 mins.
 # TYPE oracledb_teq_message_latency_1 gauge
 oracledb_teq_message_latency_1{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 10
 oracledb_teq_message_latency_1{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 10
 oracledb_teq_message_latency_1{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 10
 # HELP oracledb_teq_message_latency_2 Message latency for last 1 hour.
 # TYPE oracledb_teq_message_latency_2 gauge
 oracledb_teq_message_latency_2{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 20
 oracledb_teq_message_latency_2{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 20
 oracledb_teq_message_latency_2{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 20
 # HELP oracledb_teq_message_latency_3 Message latency for last 5 hours.
 # TYPE oracledb_teq_message_latency_3 gauge
 oracledb_teq_message_latency_3{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 30
 oracledb_teq_message_latency_3{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 30
 oracledb_teq_message_latency_3{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 30
 # HELP oracledb_teq_remained_msgs Total remained messages.
 # TYPE oracledb_teq_remained_msgs gauge
 oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="1"} 5
 oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKAQUEUE",subscriber_name="4"} 13
 oracledb_teq_remained_msgs{inst_id="4",queue_name="BANKBQUEUE",subscriber_name="1"} 0
 # HELP oracledb_teq_total_queues Total number of queues
 # TYPE oracledb_teq_total_queues gauge
 oracledb_teq_total_queues{inst_id="4"} 2
 # HELP oracledb_teq_total_subscribers Total number of subscribers
 # TYPE oracledb_teq_total_subscribers gauge
 oracledb_teq_total_subscribers{inst_id="4"} 2
 # HELP oracledb_up Whether the Oracle database server is up.
 # TYPE oracledb_up gauge
 oracledb_up 1
 # HELP oracledb_wait_class_time_waited Amount of time spent in the wait by all sessions in the instance
 # TYPE oracledb_wait_class_time_waited gauge
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Administrative"} 413
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Application"} 1748
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Cluster"} 19243
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Commit"} 855
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Concurrency"} 4657
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Configuration"} 646
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Idle"} 8.6472573e+07
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Network"} 1761
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Other"} 2.581407e+06
 oracledb_wait_class_time_waited{inst_id="4",wait_class="Scheduler"} 1.079906e+06
 oracledb_wait_class_time_waited{inst_id="4",wait_class="System I/O"} 8329
 oracledb_wait_class_time_waited{inst_id="4",wait_class="User I/O"} 42929
 # HELP oracledb_wait_class_total_waits Number of times waits of the class occurred
 # TYPE oracledb_wait_class_total_waits gauge
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Administrative"} 144
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Application"} 7007
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Cluster"} 6934
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Commit"} 2096
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Concurrency"} 171155
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Configuration"} 110
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Idle"} 2.236605e+06
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Network"} 2.850185e+06
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Other"} 1.2495296e+07
 oracledb_wait_class_total_waits{inst_id="4",wait_class="Scheduler"} 187153
 oracledb_wait_class_total_waits{inst_id="4",wait_class="System I/O"} 185311
 oracledb_wait_class_total_waits{inst_id="4",wait_class="User I/O"} 772615
 # HELP process_cpu_seconds_total Total user and system CPU time spent in seconds.
 # TYPE process_cpu_seconds_total counter
 process_cpu_seconds_total 16.02
 # HELP process_max_fds Maximum number of open file descriptors.
 # TYPE process_max_fds gauge
 process_max_fds 1.048576e+06
 # HELP process_open_fds Number of open file descriptors.
 # TYPE process_open_fds gauge
 process_open_fds 11
 # HELP process_resident_memory_bytes Resident memory size in bytes.
 # TYPE process_resident_memory_bytes gauge
 process_resident_memory_bytes 7.8979072e+07
 # HELP process_start_time_seconds Start time of the process since unix epoch in seconds.
 # TYPE process_start_time_seconds gauge
 process_start_time_seconds 1.65241071159e+09
 # HELP process_virtual_memory_bytes Virtual memory size in bytes.
 # TYPE process_virtual_memory_bytes gauge
 process_virtual_memory_bytes 2.118565888e+09
 # HELP process_virtual_memory_max_bytes Maximum amount of virtual memory available in bytes.
 # TYPE process_virtual_memory_max_bytes gauge
 process_virtual_memory_max_bytes -1
 [ root@curlpod:/ ]$

 */