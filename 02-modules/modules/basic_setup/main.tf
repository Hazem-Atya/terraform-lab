resource "kubernetes_namespace" "example" {
  metadata {
    labels = {
      environment = "var.environment"
    }
    generate_name =  "gl5-"  # name generated automatically with gl5 as a prefix
  }
}
