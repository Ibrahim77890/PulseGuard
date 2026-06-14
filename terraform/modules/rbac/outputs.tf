output "rbac_roles_created" {
  value       = ["pulseguard-viewer", "pulseguard-deployer", "pulseguard-namespace-admin"]
  description = "List of RBAC roles generated per namespace."
}
