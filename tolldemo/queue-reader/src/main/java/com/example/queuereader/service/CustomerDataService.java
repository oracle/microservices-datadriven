package com.example.queuereader.service;

import java.util.ArrayList;
import java.util.Date;
import java.util.List;

import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import com.example.queuereader.model.AccountDetails;

import lombok.extern.slf4j.Slf4j;

@Service
@Slf4j
public class CustomerDataService {

    private final JdbcTemplate jdbcTemplate;

    public CustomerDataService(JdbcTemplate jdbcTemplate) {
        this.jdbcTemplate = jdbcTemplate;
    }
    

    final String accountDetailsQuery = 
    "select c.customer_id, c.account_number, c.first_name, c.last_name, c.address, c.city, c.zipcode, "
    + "v.vehicle_id, v.tag_id, v.state, v.license_plate, v.vehicle_type "
    + "from customer c, vehicle v " 
    + "where c.customer_id like '%'||v.customer_id||'%' "
    + "and c.customer_id like ("
    + "  select '%'||customer_id||'%' "
    + "  from vehicle "
    + "  where license_plate like '%XXXXXX%'"
    + ")";


    public List<AccountDetails> getAccountDetails(String licensePlate) {
        List<AccountDetails> result = new ArrayList<AccountDetails>();
        long startTime = System.currentTimeMillis();
        jdbcTemplate.query(accountDetailsQuery.replace("XXXXXX", licensePlate),
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
        log.info("The query took " + (endTime - startTime) + "ms");

        log.info("returning " + result.size() + " account detail rows");
        return result;
    }

}
