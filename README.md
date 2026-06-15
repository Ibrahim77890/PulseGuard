# PulseGuard

PulseGuard is a portfolio project for production observability, security, incident engineering, and AIOps on GCP. This repository currently implements Phase 01 and Phase 02: the secure platform foundation plus the full observability stack for metrics, logs, and traces.

## Phase 01-02 scope

- GKE Autopilot cluster with private nodes and private control plane endpoint
- Workload Identity per namespace: `frontend`, `backend`, `data`
- Namespace-scoped RBAC bindings with reusable ClusterRoles
- Deny-by-default network policies with explicit communication paths
- Mesh-wide strict mTLS manifest for Cloud Service Mesh / Anthos Service Mesh
- `kube-prometheus-stack` via Helm and Terraform
- `Grafana`, `Prometheus`, `Loki`, `Tempo`, and `OpenTelemetry Collector`
- Grafana dashboards-as-code for RED and USE views
- Network policy allowances for observability traffic without relaxing app-to-app isolation

## Repository layout

- [PHASE_01.md](/e:/pulseguard/PHASE_01.md)
- [PHASE_02.md](/e:/pulseguard/PHASE_02.md)
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

Use the checklists in [docs/validation-checklist.md](/e:/pulseguard/docs/validation-checklist.md) and [docs/phase-02-validation-checklist.md](/e:/pulseguard/docs/phase-02-validation-checklist.md) to confirm the foundation and observability stack are complete.
