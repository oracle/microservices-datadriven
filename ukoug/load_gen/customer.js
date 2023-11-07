import http from 'k6/http';
import { check } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';
export const options = {
    stages: [
      { target: 3200, duration: '5m'},
      { target: 4800, duration: '5m'},
      { target: 9600, duration: '5m'},
      { target: 0, duration: '1m'},
    ],
  };

export default function () {
  const stress_endpoint = `http://localhost:8081/api/v1`;
  const params = {
    headers: {
      'Content-Type': 'application/json'
    },
  };
  // create a customer
  let customerResponse = createCustomer(stress_endpoint, params);
  check(customerResponse, {
    'create customer is status 201': (r) => r.status === 201
  });
  // get its customer id from response  
  let customerId = getResponseKey(getSafePayload(customerResponse), 'customerId');
  if (customerId) {
    // get the customer by its id     
    customerResponse = http.get(stress_endpoint + "/customer/" + customerId, params); 
    check(customerResponse, {
        'GET customer is status 200': (r) => r.status === 200
    });
    if (customerResponse.status == 200) {
        // update and delete a customer
        let customerPayload = getSafePayload(customerResponse);
        if (customerPayload.customerId) {
            customerPayload.customerOtherDetails = "updated details";
            customerResponse = http.put(stress_endpoint + "/customer/" + customerPayload.customerId, JSON.stringify(customerPayload), params);
            check(customerResponse, {
                'UPDATE customer is status 200': (r) => r.status === 200
            });
            // delete one customer
            let res = http.del(stress_endpoint + "/customer/" + customerPayload.customerId,null, params);
            check(res, {
                    'Delete customer is status 204': (r) => r.status === 204
            });   
        }
    } else {
        console.error("get customer response is not 200",customerResponse )
    }
  } else {
    console.error("customer id not found", customerResponse);
  }
}

function getResponseKey(obj, key) {
    try {
        return obj && obj[key] ? obj[key]: null;
    } catch(e) {
      console.error("error during parsing response", e);
      return null;
    }
}

function createCustomer(stress_endpoint,params) {
 var payload = JSON.stringify({
    customerId: randomString(19),
    customerName: randomString(8),
    customerEmail: randomString(4) + '@oracle.com',
    customerPassword: 'welcome1',
    customerOtherDetails: randomString(20)
  });
  return http.post(stress_endpoint + "/customer", payload, params);
}


function getSafePayload(obj) {
    try {
        return obj.json();
    } catch (err) {
        return {}
    }
}

export function handleSummary(data) {
  // add total num of req per check and % of succ
  let checkCounter = 0, reqCount = 0, pcntAvg = 0;
  if  (data && data.root_group && data.root_group.checks){
    for (let check of data.root_group.checks){
      let fails = check.fails || 0;
      let pass = check.passes || 0;
      let total = fails + pass;
      let pcnt = (100 / total) * pass;
      check.percentage_of_succ = pcnt;
      check.totalRequests = total;
      checkCounter += 1;
      reqCount += total;
      pcntAvg += pcnt;
    }
    let overall_stats = {"name":"overall stats", "totalRequets": reqCount, "avgPercentageOfSuccess": (pcntAvg / checkCounter)}
    data.root_group.checks.push(overall_stats);
  }
        return {
    'summary.json': JSON.stringify(data), //the default data object
  };
}
