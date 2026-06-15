# Game Day: CPU Hog

## Hypothesis

CPU stress on a backend pod should surface saturation metrics and demonstrate whether autoscaling or capacity headroom is sufficient.

## Blast Radius

- Namespace: `backend`
- Target: one backend pod

## Expected Signal

- Increased CPU utilization on USE dashboard
- Possible error or latency increase depending on capacity

## Success Criteria

- Saturation is visible in dashboards
- Team can identify the issue from metrics alone
- Recovery occurs without long-lived instability
