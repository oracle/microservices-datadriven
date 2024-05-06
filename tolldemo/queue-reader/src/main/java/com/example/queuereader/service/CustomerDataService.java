package com.example.queuereader.service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import com.example.queuereader.model.AccountDetails;

import io.micrometer.core.instrument.Tags;
import io.micrometer.core.instrument.Timer;
import io.micrometer.prometheus.PrometheusMeterRegistry;
import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CustomerDataService {

    private Timer timer;

    private final JdbcTemplate jdbcTemplate;

    public CustomerDataService(JdbcTemplate jdbcTemplate, PrometheusMeterRegistry registry) {
        this.jdbcTemplate = jdbcTemplate;
        timer = registry.timer("get.account.details", Tags.empty());
    }
    
    // slower query
    final String accountDetailsQuery = 
    "select /*+ ORDERED_PREDICATES */ c.customer_id, c.account_number, c.first_name, c.last_name, c.address, c.city, c.zipcode, "
    + "v.vehicle_id, v.tag_id, v.state, v.license_plate, v.vehicle_type "
    + "from customer c, vehicle v " 
    + "where c.customer_id like '%'||v.customer_id||'%' "
    + "and c.customer_id like ("
    + "  select /*+ ORDERED_PREDICATES */ '%'||customer_id||'%' "
    + "  from vehicle "
    + "  where vehicle_type = 'TTTTTT' "
    + "  and license_plate like '%'|| remove_state('XXXXXX') || '%'"
    + ")";

    // faster query
    final String fasterAccountDetailsQuery = 
    "select c.customer_id, c.account_number, c.first_name, c.last_name, c.address, c.city, c.zipcode, "
    + "v.vehicle_id, v.tag_id, v.state, v.license_plate, v.vehicle_type "
    + "from customer c, vehicle v " 
    + "where c.customer_id = v.customer_id "
    + "and c.customer_id = ("
    + "  select customer_id "
    + "  from vehicle "
    + "  where license_plate = regexp_replace('XXXXXX', '[A-Z]+-', 1, 1)"
    + ")";


    public List<AccountDetails> getAccountDetails(String licensePlate, String vehicleType) {
        List<AccountDetails> result = new ArrayList<AccountDetails>();
        long startTime = System.currentTimeMillis();
        Timer.Sample sample = Timer.start();
        jdbcTemplate.query(accountDetailsQuery.replace("XXXXXX", licensePlate).replace("TTTTTT", vehicleType),
        (rs, rowNum) -> new AccountDetails(
            rs.getString("customer_id"),
            rs.getString("account_number"),
            rs.getString("first_name"),
            rs.getString("last_name"),
            rs.getString("address"),
            rs.getString("city"),
            rs.getString("zipcode"),
            rs.getString("vehicle_id"),
            rs.getString("tag_id"),
            rs.getString("state"),
            rs.getString("license_plate"),
            rs.getString("vehicle_type")
        )).forEach(accountDetails -> result.add(accountDetails));
        long endTime = System.currentTimeMillis();
        timer.record(() -> sample.stop(timer) / 1_000);
        log.info("The query took " + (endTime - startTime) + "ms");

        log.info("returning " + result.size() + " account detail rows");
        return result;
    }

}
