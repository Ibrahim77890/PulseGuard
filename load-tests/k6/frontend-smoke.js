import http from "k6/http";
import { check, sleep } from "k6";

export const options = {
  vus: 20,
  duration: "2m",
  thresholds: {
    http_req_failed: ["rate<0.01"],
    http_req_duration: ["p(99)<500"],
  },
};

const baseUrl = __ENV.TARGET_URL || "http://frontend.default.svc.cluster.local";

export default function () {
  const res = http.get(`${baseUrl}/`);
  check(res, {
    "status is 200": (r) => r.status === 200,
  });
  sleep(1);
}
