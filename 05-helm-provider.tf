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

resource "helm_release" "argocd" {
  name = "argocd"

  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = var.argocd_namespace
  create_namespace = true
  version          = var.argocd_version

  set {
    name = "configs.params.server\\.insecure"
    value = true
  }

  set {
    name = "server.ingress.enabled"
    value = true
  }

  set {
    name = "server.ingress.ingressClassName"
    value = "nginx"
  }
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
    server = var.administrative_kubernetes_host
    # TODO: Use caData (probably accessed via differenet providers) and enable TLS.
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
        "insecure": true,
      }
    }
    EOT
  }


}
