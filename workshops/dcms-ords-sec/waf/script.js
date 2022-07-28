import { check } from 'k6';
        import http from 'k6/http';
        export const options = {
            userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/102.0.0.0 Safari/537.36',
        scenarios: {
            constant_request_rate: {
            executor: 'constant-arrival-rate',
            rate: 50,
            timeUnit: '1s', // 50 iterations per second, i.e. 50 RPS
            duration: '10s',
            preAllocatedVUs: 10, // how large the initial pool of VUs would be
            maxVUs: 10, // if the preAllocatedVUs are not enough, we can initialize more
            },
        },
        }
        export default function () {
        const res = http.get(`http://${__ENV.MY_HOSTNAME}/get/status.json`);
            check(res, {
                'is status 200': (r) => r.status === 200,
                'is status 401': (r) => r.status === 401,
            });
        }