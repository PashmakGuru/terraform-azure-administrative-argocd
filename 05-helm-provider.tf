data "azurerm_client_config" "current" {
}

data "azurerm_resource_group" "this" {
  name = var.kubernetes_cluster_resource_group_name
}

data "azurerm_kubernetes_cluster" "this" {
  name                = var.kubernetes_cluster_name
  resource_group_name = data.azurerm_resource_group.this.name
}

resource "azurerm_user_assigned_identity" "argocd" {
  name                = var.argocd_identity_name
  location            = data.azurerm_resource_group.this.location
  resource_group_name = data.azurerm_resource_group.this.name
}

// @see https://github.com/Azure-Samples/aks-workload-identity-terraform
resource "azurerm_federated_identity_credential" "federated_credential" {
  name                = "fic-${var.argocd_identity_name}"
  resource_group_name = data.azurerm_resource_group.this.name
  audience            = ["api://AzureADTokenExchange"]
  issuer              = data.azurerm_kubernetes_cluster.this.oidc_issuer_url
  parent_id           = azurerm_user_assigned_identity.argocd.id
  subject             = "system:serviceaccount:${var.argocd_namespace}:argocd"
}

locals {
  kuber_host = data.azurerm_kubernetes_cluster.this.kube_config.0.host
  kuber_client_cert = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  kuber_client_key = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  kuber_ca_cert = base64decode(data.azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
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

resource "helm_release" "cert_manager" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argocd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = var.argocd_version
}

resource "kubernetes_secret" "argocd_clusters" {
  metadata {
    name = "argo-cluster-${data.azurerm_kubernetes_cluster.this.name}"
    annotations = {
      "terraform-module" = "terraform-azure-administrative-argocd"
    }
    labels = {
      "argocd.argoproj.io/secret-type" = "cluster"
    }
  }

  type = "Opaque"

  data = {
    name =  data.azurerm_kubernetes_cluster.this.name
    server = local.kuber_host
    config = <<-EOT
      {
      "execProviderConfig": {
        "command": "argocd-k8s-auth",
        "env": {
          "AAD_ENVIRONMENT_NAME": "AzurePublicCloud",
          "AZURE_CLIENT_ID": "${ azurerm_user_assigned_identity.argocd.client_id }",
          "AZURE_TENANT_ID": "${ data.azurerm_client_config.current.tenant_id }",
          "AZURE_FEDERATED_TOKEN_FILE": "/opt/path/to/federated_file.json",
          "AZURE_AUTHORITY_HOST": "https://login.microsoftonline.com/",
          "AAD_LOGIN_METHOD": "workloadidentity"
        },
        "args": ["azure"],
        "apiVersion": "client.authentication.k8s.io/v1beta1"
      },
      "tlsClientConfig": {
        "insecure": false,
        "caData": "${ base64encode(local.kuber_ca_cert) }"
      }
    }
    EOT
  }


}
