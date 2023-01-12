# creating a resrouce group

resource "azurerm_resource_group" "example" {
  name     = "example-resources"
  location = "West Europe"
}

resource "azurerm_kubernetes_cluster" "example" {
  name                = "example-aks1"
  location            = azurerm_resource_group.example.location
  resource_group_name = azurerm_resource_group.example.name
  dns_prefix          = "exampleaks1"
  sku_tier            = "Free"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_D2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Development"
  }
}

# provider "kubernetes" {
#   alias                  = "my-cluster"
#   host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
#   username               = azurerm_kubernetes_cluster.example.kube_config.0.username
#   password               = azurerm_kubernetes_cluster.example.kube_config.0.password
#   client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
#   client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
#   cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
# }

locals {
  host                   = azurerm_kubernetes_cluster.example.kube_config.0.host
  username               = azurerm_kubernetes_cluster.example.kube_config.0.username
  password               = azurerm_kubernetes_cluster.example.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.example.kube_config.0.cluster_ca_certificate)
}

provider "kubernetes" {
  alias                  = "my-cluster"
  host                   = local.host
  username               = local.username
  password               = local.password
  client_certificate     = local.client_certificate
  client_key             = local.client_key
  cluster_ca_certificate = local.cluster_ca_certificate
}



module "basic_setup" {
  source = "./modules/basic_setup"
  providers = {
    kubernetes = kubernetes.my-cluster
  }
  environment = "dev"
}





provider "helm" {
  kubernetes {
    host                   = local.host
    username               = local.username
    password               = local.password
    client_certificate     = local.client_certificate
    client_key             = local.client_key
    cluster_ca_certificate = local.cluster_ca_certificate
  }
}

module "setup_gitops" {
  source = "./modules/git_ops"
  providers = {
    helm = helm
  }
  namespace = module.basic_setup.namespace_id
}