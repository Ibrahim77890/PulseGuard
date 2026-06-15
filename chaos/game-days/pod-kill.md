# Game Day: Pod Kill

## Hypothesis

If a backend pod is killed, the service should recover quickly and the SLO alert should fire within the expected detection window.

## Blast Radius

- Namespace: `backend`
- Target: one backend pod

## Expected Alert

- `PulseGuardSLOFastBurn`

## Success Criteria

- Alert fires within 2 minutes
- Service recovers without manual restart
- MTTR stays under 5 minutes
