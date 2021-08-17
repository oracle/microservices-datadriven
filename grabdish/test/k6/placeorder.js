// Copyright (c) 2021 Oracle and/or its affiliates.
// Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
import http from 'k6/http';
import { sleep, check } from 'k6';

const rps = 10.0;
const think = 1.0/rps;

export default function() {
  const delay = think * Math.random();
//  sleep(delay);
  let orderid=(10000000 * __ENV.RUN + 100000 * __VU + __ITER).toString();
  const res = http.get(`https://${__ENV.LB}:443/placeOrder?orderid=${orderid}&itemid=34&deliverylocation=London`);
//  sleep(think - delay);

  const checkRes = check(res, {
    'status is 200': r => r.status === 200,
    'status is other': r => r.status !== 200,
  });

}