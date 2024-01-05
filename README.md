# Azure Administrative ArgoCD

[![Terraform CI](https://github.com/PashmakGuru/terraform-azure-administrative-argocd/actions/workflows/terraform-ci.yaml/badge.svg)](https://github.com/PashmakGuru/terraform-azure-administrative-argocd/actions/workflows/terraform-ci.yaml)

## Overview
This Terraform configuration is designed to automate the deployment and configuration of Argo CD on Azure Kubernetes Service (AKS). It simplifies the process of setting up Argo CD with the necessary Azure integrations.

### Terraform Architecture
```mermaid
%%tfmermaid
%%{init:{"theme":"default","themeVariables":{"lineColor":"#6f7682","textColor":"#6f7682"}}}%%
flowchart LR
classDef r fill:#5c4ee5,stroke:#444,color:#fff
classDef v fill:#eeedfc,stroke:#eeedfc,color:#5c4ee5
classDef ms fill:none,stroke:#dce0e6,stroke-width:2px
classDef vs fill:none,stroke:#dce0e6,stroke-width:4px,stroke-dasharray:10
classDef ps fill:none,stroke:none
classDef cs fill:#f7f8fa,stroke:#dce0e6,stroke-width:2px
subgraph "n0"["Authorization"]
n1["azurerm_federated_identity_credential.<br/>federated_credential"]:::r
n2["azurerm_user_assigned_identity.<br/>argocd"]:::r
end
class n0 cs
subgraph "n3"["Base"]
n4{{"data.<br/>azurerm_client_config.<br/>current"}}:::r
n5{{"data.<br/>azurerm_resource_group.<br/>this"}}:::r
end
class n3 cs
subgraph "n6"["Container"]
n7{{"data.<br/>azurerm_kubernetes_cluster.<br/>this"}}:::r
end
class n6 cs
n8["helm_release.argocd"]:::r
subgraph "n9"["core/v1"]
na["kubernetes_secret.<br/>argocd_clusters"]:::r
end
class n9 cs
subgraph "nb"["Input Variables"]
nc(["var.<br/>administrative_kubernetes_host"]):::v
nd(["var.argocd_identity_name"]):::v
ne(["var.argocd_namespace"]):::v
nf(["var.argocd_version"]):::v
ng(["var.ingress_class_name"]):::v
nh(["var.kubernetes_cluster_name"]):::v
ni(["var.<br/>kubernetes_cluster_resource_group_name"]):::v
end
class nb vs
n2-->n1
n7-->n1
ne--->n1
n5-->n2
nd--->n2
n5-->n7
nh--->n7
ni--->n5
ne--->n8
nf--->n8
n2-->na
n4-->na
n7-->na
nc--->na
```

## Features
- **Kubernetes Cluster Data Retrieval**: Fetches data about an existing AKS cluster.
- **User-Assigned Identity Creation**: Sets up a user-assigned identity for Argo CD.
- **Federated Identity Credential Management**: Manages federated identity credentials for seamless integration with Azure.
- **Helm Chart Deployment**: Deploys Argo CD using a Helm chart, with options for ingress and server configurations.
- **Secret Management for Kubernetes Clusters**: Creates a Kubernetes secret for Argo CD cluster configurations.

## File Structure
- [01-providers.tf](./01-providers.tf): Specifies the required providers such as AzureRM, Helm, and Kubernetes.
- [outputs.tf](./outputs.tf): This file is intended for defining module outputs. (Note: Currently, this file does not contain any outputs as per the provided code.)
- [variables.tf](./variables.tf): Defines variables required for the configuration, like Kubernetes cluster details and Argo CD settings.

## Example
For usage examples, please refer to the [`example`](./example) directory. This directory will provide practical examples of how to use this Terraform module in your projects.

## Workflows
| Name | Description |
|---|---|
| [terraform-ci.yaml](.github/workflows/terraform-ci.yaml) | A workflow for linting and auto-formatting Terraform code. Triggered by pushes to  `main` and `dev` branches or on pull requests, it consists of two jobs: `tflint` for lint checks, `format` for code formatting and submit a PR, and `tfmermaid` to update architecture graph and submit a PR. |
