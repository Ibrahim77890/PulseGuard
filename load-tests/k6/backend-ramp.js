import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  scenarios: {
    ramping_load: {
      executor: "ramping-vus",
      startVUs: 0,
      stages: [
        { duration: "2m", target: 100 },
        { duration: "3m", target: 250 },
        { duration: "3m", target: 500 },
        { duration: "2m", target: 0 },
      ],
    },
  },
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(99)<500"],
  },
};

const baseUrl = __ENV.TARGET_URL || "http://backend.default.svc.cluster.local";

export default function () {
  const res = http.get(`${baseUrl}/healthz`);
  check(res, {
    "backend healthy": (r) => r.status === 200,
  });
  sleep(1);
}
