# PulseGuard

PulseGuard is a portfolio project for production observability, security, incident engineering, and AIOps on GCP. This repository currently implements Phase 01: the secure platform foundation for a private GKE Autopilot cluster with Workload Identity, namespace isolation, least-privilege RBAC, and deny-by-default network controls.

## Phase 01 scope

- GKE Autopilot cluster with private nodes and private control plane endpoint
- Workload Identity per namespace: `frontend`, `backend`, `data`
- Namespace-scoped RBAC bindings with reusable ClusterRoles
- Deny-by-default network policies with explicit communication paths
- Mesh-wide strict mTLS manifest for Cloud Service Mesh / Anthos Service Mesh

## Repository layout

- [terraform/environments/dev/main.tf](/e:/pulseguard/terraform/environments/dev/main.tf)
- [terraform/modules/gke-autopilot/main.tf](/e:/pulseguard/terraform/modules/gke-autopilot/main.tf)
- [terraform/modules/workload-identity/main.tf](/e:/pulseguard/terraform/modules/workload-identity/main.tf)
- [kubernetes/overlays/dev/kustomization.yaml](/e:/pulseguard/kubernetes/overlays/dev/kustomization.yaml)
- [docs/phase-01-foundation.md](/e:/pulseguard/docs/phase-01-foundation.md)
- [docs/traffic-matrix.md](/e:/pulseguard/docs/traffic-matrix.md)

## How to start

1. Copy `terraform/environments/dev/terraform.tfvars.example` to `terraform/environments/dev/terraform.tfvars`.
2. Fill in your `project_id`, VPC, subnet, and secondary range names.
3. Run `terraform init` and `terraform apply` inside `terraform/environments/dev`.
4. Fetch cluster credentials with the output command from Terraform.
5. Apply the Kubernetes manifest overlay with `kubectl apply -k kubernetes/overlays/dev`.
6. Enable Cloud Service Mesh according to GKE/ASM prerequisites, then apply the PeerAuthentication manifest.

Terraform manages the workload identity KSAs so the manifest overlay intentionally does not re-apply those service accounts.

## Validation

Use the checklist in [docs/validation-checklist.md](/e:/pulseguard/docs/validation-checklist.md) to confirm that Phase 01 is complete before moving to Phase 02.
