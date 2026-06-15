variable "project_id" {
  type        = string
  description = "The ID of the GCP project where APIs will be enabled."
}

variable "gcp_api_list" {
  type        = list(string)
  description = "The list of Google APIs to enable."
  default = [
    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com",
    "bigquery.googleapis.com",
    "cloudfunctions.googleapis.com",
    "cloudbuild.googleapis.com",
    "containeranalysis.googleapis.com",
    "gkehub.googleapis.com",
    "mesh.googleapis.com",
    "iam.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "run.googleapis.com",
    "securitycenter.googleapis.com",
    "securityposture.googleapis.com"
  ]
}
