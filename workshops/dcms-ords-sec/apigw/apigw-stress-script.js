import { check } from 'k6';
        import http from 'k6/http';
        const params = {
            headers: {
              'Authorization': 'Bearer '+`${__ENV.TOKEN}`,
            },
          };
        export const options = {
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36',
        scenarios: {
            constant_request_rate: {
            executor: 'constant-arrival-rate',
            rate: 400,
            timeUnit: '1s', // 1000 iterations per second, i.e. 1000 RPS
            duration: '1s',
            preAllocatedVUs: 100, // how large the initial pool of VUs would be
            maxVUs: 200, // if the preAllocatedVUs are not enough, we can initialize more
            },
        },
        }
        export default function () {
        const res = http.get(`${__ENV.MY_HOSTNAME}`,params);
            check(res, {
                'is status 200': (r) => r.status === 200,
                'is status 300': (r) => (r.status >= 300 && r.status < 400 ), 
                'is status 400': (r) => (r.status >= 400 && r.status < 500 ) ,
            });
        }
        