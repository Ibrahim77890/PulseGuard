# PulseGuard

PulseGuard is a portfolio project for production observability, security, incident engineering, and AIOps on GCP. This repository currently implements Phase 01 through Phase 09: the secure platform foundation, observability stack, SLO engineering layer, shift-left security pipeline, runtime security layer, incident-engineering assets, compliance plus cost-observability controls, an AIOps assistant layer, and LLM plus agent observability.

## Phase 01-09 scope

- GKE Autopilot cluster with private nodes and private control plane endpoint
- Workload Identity per namespace: `frontend`, `backend`, `data`
- Namespace-scoped RBAC bindings with reusable ClusterRoles
- Deny-by-default network policies with explicit communication paths
- Mesh-wide strict mTLS manifest for Cloud Service Mesh / Anthos Service Mesh
- `kube-prometheus-stack` via Helm and Terraform
- `Grafana`, `Prometheus`, `Loki`, `Tempo`, and `OpenTelemetry Collector`
- Grafana dashboards-as-code for RED and USE views
- Network policy allowances for observability traffic without relaxing app-to-app isolation
- SLO definitions for `frontend`, `backend`, and `data`
- Error budget dashboard and burn-rate alerting as code
- Optional Cloud Monitoring uptime checks and native SLO resources
- Secret scanning, IaC scanning, SBOM generation, and signing workflow support
- Artifact Registry, Binary Authorization, and GKE Security Posture scaffolding
- Runtime detection with Falco and forwarded security alert plumbing
- Audit-log export, forensic SQL queries, and IAM drift alerting
- Runbooks, chaos experiments, load tests, and postmortem templates
- Gatekeeper policy enforcement, OpenCost scaffolding, billing export dataset setup, and FinOps queries
- Cloud Run AIOps assistant with read-only tool calling, session memory, and runbook/postmortem RAG
- OpenTelemetry GenAI spans, agent cost and latency metrics, eval harnesses, and agent SLO signals

## Repository layout

- [PHASE_01.md](/e:/pulseguard/PHASE_01.md)
- [PHASE_02.md](/e:/pulseguard/PHASE_02.md)
- [PHASE_03.md](/e:/pulseguard/PHASE_03.md)
- [PHASE_04.md](/e:/pulseguard/PHASE_04.md)
- [PHASE_05.md](/e:/pulseguard/PHASE_05.md)
- [PHASE_06.md](/e:/pulseguard/PHASE_06.md)
- [PHASE_07.md](/e:/pulseguard/PHASE_07.md)
- [PHASE_08.md](/e:/pulseguard/PHASE_08.md)
- [PHASE_09.md](/e:/pulseguard/PHASE_09.md)
- [terraform/environments/dev/main.tf](/e:/pulseguard/terraform/environments/dev/main.tf)
- [terraform/modules/gke-autopilot/main.tf](/e:/pulseguard/terraform/modules/gke-autopilot/main.tf)
- [terraform/modules/workload-identity/main.tf](/e:/pulseguard/terraform/modules/workload-identity/main.tf)
- [terraform/modules/observability-stack/main.tf](/e:/pulseguard/terraform/modules/observability-stack/main.tf)
- [kubernetes/overlays/dev/kustomization.yaml](/e:/pulseguard/kubernetes/overlays/dev/kustomization.yaml)
- [docs/phase-01-foundation.md](/e:/pulseguard/docs/phase-01-foundation.md)
- [docs/phase-02-observability.md](/e:/pulseguard/docs/phase-02-observability.md)
- [docs/traffic-matrix.md](/e:/pulseguard/docs/traffic-matrix.md)

## How to start

1. Copy `terraform/environments/dev/terraform.tfvars.example` to `terraform/environments/dev/terraform.tfvars`.
2. Fill in your `project_id`, VPC, subnet, and secondary range names.
3. Run `terraform init` and `terraform apply` inside `terraform/environments/dev`.
4. Fetch cluster credentials with the output command from Terraform.
5. Apply `kubectl apply -k kubernetes/overlays/dev` to create the observability namespace, network policy exceptions, and Grafana dashboards.
6. Enable Cloud Service Mesh according to GKE/ASM prerequisites, then apply the PeerAuthentication manifest.

Terraform manages the workload identity KSAs so the manifest overlay intentionally does not re-apply those service accounts.

## Validation

Use the checklists in [docs/validation-checklist.md](/e:/pulseguard/docs/validation-checklist.md), [docs/phase-02-validation-checklist.md](/e:/pulseguard/docs/phase-02-validation-checklist.md), [docs/phase-03-validation-checklist.md](/e:/pulseguard/docs/phase-03-validation-checklist.md), [docs/phase-04-validation-checklist.md](/e:/pulseguard/docs/phase-04-validation-checklist.md), [docs/phase-05-validation-checklist.md](/e:/pulseguard/docs/phase-05-validation-checklist.md), [docs/phase-06-validation-checklist.md](/e:/pulseguard/docs/phase-06-validation-checklist.md), [docs/phase-07-validation-checklist.md](/e:/pulseguard/docs/phase-07-validation-checklist.md), [docs/phase-08-validation-checklist.md](/e:/pulseguard/docs/phase-08-validation-checklist.md), and [docs/phase-09-validation-checklist.md](/e:/pulseguard/docs/phase-09-validation-checklist.md) to confirm the foundation, observability stack, SLO layer, shift-left security pipeline, runtime security layer, incident-engineering assets, compliance plus cost-observability controls, the AIOps assistant, and LLM plus agent observability are complete.
