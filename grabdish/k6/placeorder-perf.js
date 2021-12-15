// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
import http from 'k6/http';
import { sleep, check } from 'k6';

//this is used by test suite, not by workshop itself
export default function() {
  let orderid=(100000 * __VU + __ITER).toString();
  const res = http.get(`https://${__ENV.LB}:443/placeOrder?orderid=${orderid}&itemid=sushi&deliverylocation=London`);

  const checkRes = check(res, {
    'status is 200': r => r.status === 200,
    'status is other': r => r.status !== 200,
  });
}