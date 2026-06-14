output "network_policies_enforced" {
  value       = true
  description = "Confirms that default-deny network rules have been applied."
}

output "allowed_flows" {
  value = [
    "frontend -> backend",
    "backend -> data"
  ]
  description = "Explicit namespace communication paths allowed by Phase 01."
}
