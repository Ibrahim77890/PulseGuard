# Game Day: Network Latency

## Hypothesis

Injecting latency between backend and data should degrade latency SLOs and surface timeout / retry weaknesses.

## Blast Radius

- Source namespace: `backend`
- Target namespace: `data`

## Expected Alert

- `PulseGuardSLOSlowBurn`

## Success Criteria

- Latency dashboards show clear regression
- Traces isolate backend-to-data calls as the bottleneck
- Recovery completes within the planned experiment window
