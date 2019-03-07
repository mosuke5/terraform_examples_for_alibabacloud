provider "kubernetes" {}

resource "kubernetes_deployment" "test" {
  metadata {
    name = "nginx-sample-deployment"
  }

  spec {
    selector {
      match_labels {
        app = "nginx-sample-deployment"
      }
    }
    replicas = 3
    template {
      metadata {
        labels {
          app = "nginx-sample-deployment"
        }
      }
      spec {
        container {
          name = "nignx"
          image = "nginx:latest"
          port {
            container_port = 80
          }
        }
      }
    }
  }
}
