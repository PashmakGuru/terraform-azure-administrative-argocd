locals {
  administrative_cluster_name = "admin-cluster"
  administrative_cluster_resource_group_name = "module-azure-administrative-kubernetes-cluster"
  administrative_cluster_resource_group_location = "East US"
}

module "kubernetes_cluster" {
  source  = "app.terraform.io/PashmakGuru/kubernetes-cluster/azure"
  version = "0.0.1-alpha.8"

  environment = "testing"
  location = local.administrative_cluster_resource_group_location
  name = local.administrative_cluster_name
  resource_group_name = local.administrative_cluster_resource_group_name
}

locals {
  kuber_host = module.kubernetes_cluster.kubernetes_cluster.kube_config.0.host
  kuber_client_cert = base64decode(module.kubernetes_cluster.kubernetes_cluster.kube_config.0.client_certificate)
  kuber_client_key = base64decode(module.kubernetes_cluster.kubernetes_cluster.kube_config.0.client_key)
  kuber_ca_cert = base64decode(module.kubernetes_cluster.kubernetes_cluster.kube_config.0.cluster_ca_certificate)
}

resource "helm_release" "ingress_nginx" {
  name = "ingress-nginx"

  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true
  version          = "4.9.0"

  set {
    name = "controller.healthStatus"
    value = true
  }



  #set {
  #  name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/azure-load-balancer-internal"
  #  value = true
  #}
}

provider "helm" {
  kubernetes {
    host                   = local.kuber_host
    client_certificate     = local.kuber_client_cert
    client_key             = local.kuber_client_key
    cluster_ca_certificate = local.kuber_ca_cert
  }
}

provider "kubernetes" {
    host                   = local.kuber_host
    client_certificate     = local.kuber_client_cert
    client_key             = local.kuber_client_key
    cluster_ca_certificate = local.kuber_ca_cert
}

module "administrative_argocd" {
  source  = "./../"

  depends_on = [
    module.kubernetes_cluster,
    helm_release.ingress_nginx
  ]

  kubernetes_cluster_name = local.administrative_cluster_name
  kubernetes_cluster_resource_group_name = local.administrative_cluster_resource_group_name
  administrative_kubernetes_host = module.kubernetes_cluster.kubernetes_cluster.kube_config.0.host

  providers = {
    kubernetes = kubernetes
  }
}
