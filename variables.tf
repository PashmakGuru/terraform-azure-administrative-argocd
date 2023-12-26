variable "kubernetes_cluster_resource_group_name" {
  type = string
}

variable "kubernetes_cluster_name" {
  type = string
}

variable "argocd_identity_name" {
    type = string
    default = "argocd"
}

variable "argocd_version" {
    type = string
    default = "5.51.6"
}

variable "argocd_namespace" {
    type = string
    default = "argocd"
}
