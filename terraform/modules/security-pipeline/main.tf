locals {
  attestor_enabled        = var.enable_binary_authorization && length(var.attestor_public_keys) > 0
  evaluation_mode         = local.attestor_enabled ? "REQUIRE_ATTESTATION" : var.binary_authorization_default_evaluation_mode
  attestor_resource_names = local.attestor_enabled ? [google_binary_authorization_attestor.ci[0].name] : []
}

resource "google_artifact_registry_repository" "workloads" {
  count = var.create_artifact_registry_repository ? 1 : 0

  location      = var.region
  repository_id = var.artifact_registry_repository_id
  description   = var.artifact_registry_repository_description
  format        = "DOCKER"
  project       = var.project_id
}

resource "google_container_analysis_note" "attestor" {
  count = local.attestor_enabled ? 1 : 0

  project           = var.project_id
  name              = var.attestor_note_name
  short_description = "PulseGuard Binary Authorization attestation note"
  long_description  = "Container Analysis note used by the PulseGuard CI attestor for signed workload images."

  attestation_authority {
    hint {
      human_readable_name = var.attestor_note_hint
    }
  }
}

resource "google_binary_authorization_attestor" "ci" {
  count = local.attestor_enabled ? 1 : 0

  project     = var.project_id
  name        = var.attestor_name
  description = "PulseGuard CI attestor used for signed images and SBOM attestations."

  attestation_authority_note {
    note_reference = google_container_analysis_note.attestor[0].name

    dynamic "public_keys" {
      for_each = var.attestor_public_keys

      content {
        id      = try(public_keys.value.id, null)
        comment = try(public_keys.value.comment, null)

        pkix_public_key {
          public_key_pem      = public_keys.value.public_key_pem
          signature_algorithm = public_keys.value.signature_algorithm
        }
      }
    }
  }
}

resource "google_binary_authorization_policy" "project_policy" {
  count = var.enable_binary_authorization ? 1 : 0

  project                       = var.project_id
  description                   = var.binary_authorization_policy_description
  global_policy_evaluation_mode = "ENABLE"

  default_admission_rule {
    evaluation_mode         = local.evaluation_mode
    enforcement_mode        = var.binary_authorization_enforcement_mode
    require_attestations_by = local.attestor_resource_names
  }

  admission_whitelist_patterns {
    name_pattern = "gcr.io/google-containers/*"
  }

  admission_whitelist_patterns {
    name_pattern = "registry.k8s.io/*"
  }
}
