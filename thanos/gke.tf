provider "google" {
  project = "bob-lab-320120"
  region  = "europe-central2"
}

terraform {
  required_providers {
    kubernetes = {
      source  = "kubernetes"
      version = ">=2.36"
    }
  }
}

locals {
  # create bucket manually to keep the content for some time
  thanos_tsdb_bucket = "thanos-lab-bucket"
}

# sidecar pushes tsdb blocks to the bucket
# resource "google_storage_bucket" "prom" {
#   location = "EU"
#   name     = local.thanos_tsdb_bucket
# }


# cannot create cluster and pass attributes to kubernetes provider in the same module due to TF race condition
# hard to debug problems
module "gke" {
  source       = "../../../gcp-laboratory/modules/simple-gke"
  cluster_name = "thanos-lab"
}

resource "google_service_account" "thanos" {
  account_id = "thanos-sidecar"
}

resource "google_project_iam_member" "creator" {
  member  = format("serviceAccount:%s", google_service_account.thanos.email)
  project = data.google_project.this.id
  role    = "roles/storage.objectCreator"
}

resource "google_project_iam_member" "viewer" {
  member  = format("serviceAccount:%s", google_service_account.thanos.email)
  project = data.google_project.this.id
  role    = "roles/storage.objectViewer"
}

resource "google_service_account_iam_member" "this" {
  # service account in k8s
  member             = format("serviceAccount:%s.svc.id.goog[%s/%s]", data.google_client_config.this.project, "prometheus", "thanos-sidecar")
  role               = "roles/iam.workloadIdentityUser"
  service_account_id = google_service_account.thanos.id
}

# ensure bucket exists
data "google_storage_bucket" "thanos" {
  name = local.thanos_tsdb_bucket
}

output "cluster" {
  value = module.gke
}
