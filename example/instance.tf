locals {
  administrative_cluster_name = "admin-cluster"
  administrative_cluster_resource_group_name = "module-azure-administrative-kubernetes-cluster"
  administrative_cluster_resource_group_location = "West US"
}

module "kubernetes_cluster" {
  source  = "app.terraform.io/PashmakGuru/kubernetes-cluster/azure"
  version = "0.0.1-alpha.3"

  environment = "testing"
  location = local.administrative_cluster_resource_group_location
  name = local.administrative_cluster_name
  resource_group_name = local.administrative_cluster_resource_group_name
}

module "administrative_argocd" {
  source  = "./../"

  depends_on = [ module.kubernetes_cluster ]

  kubernetes_cluster_name = local.administrative_cluster_name
  kubernetes_cluster_resource_group_name = local.administrative_cluster_resource_group_name
}
