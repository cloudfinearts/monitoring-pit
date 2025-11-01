provider "kubernetes" {
  # private nodes setting will mess up host and CA read from data source
  host                   = format("https://%s", data.google_container_cluster.this.endpoint)
  token                  = data.google_client_config.this.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = "https://${data.google_container_cluster.this.endpoint}"
    token                  = data.google_client_config.this.access_token
    cluster_ca_certificate = base64decode(data.google_container_cluster.this.master_auth[0].cluster_ca_certificate)

    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      command     = "gke-gcloud-auth-plugin"
    }
  }
}

resource "kubernetes_namespace" "this" {
  metadata {
    name = "prometheus"
  }
}

resource "kubernetes_service_account" "thanos" {
  metadata {
    namespace = kubernetes_namespace.this.metadata[0].name
    name      = "thanos-sidecar"
    # Workload Identity Federation
    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.thanos.email
    }
  }
}

resource "kubernetes_secret" "thanos" {
  metadata {
    name      = "thanos-objstore-config"
    namespace = kubernetes_namespace.this.metadata[0].name
  }

  # warning! data field is wrong for base64 value
  binary_data = {
    "objstore.yml" = base64encode(yamlencode({
      type = "GCS"
      config = {
        bucket = local.thanos_tsdb_bucket
      }
    }))
  }
}

resource "helm_release" "prom" {
  chart     = "prometheus/kube-prometheus-stack"
  name      = "prom-stack"
  namespace = kubernetes_namespace.this.metadata[0].name

  values = [templatefile("${path.module}/values-prom.tpl.yaml", {
    THANOS_SECRET = kubernetes_secret.thanos.metadata[0].name
    THANOS_SA     = kubernetes_service_account.thanos.metadata[0].name
  })]
}

resource "helm_release" "thanos" {
  chart     = "oci://registry-1.docker.io/bitnamicharts/thanos"
  name      = "thanos"
  namespace = kubernetes_namespace.this.metadata[0].name
  values = [templatefile("${path.module}/values-thanos.tpl.yaml", {
    THANOS_SECRET = kubernetes_secret.thanos.metadata[0].name
    THANOS_SA     = kubernetes_service_account.thanos.metadata[0].name
  })]
}
