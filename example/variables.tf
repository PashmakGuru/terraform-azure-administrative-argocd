variable "azure_subscription_id" {
  type        = string
  description = "The subscription ID that defines the Azure subscription under which resources are deployed."
}

variable "azure_client_id" {
  type        = string
  description = "The client ID (also known as application ID) used to authenticate with Azure. This is used in conjunction with the client secret."
}

variable "azure_client_secret" {
  type        = string
  description = "The client secret (also known as application password) used for authentication with Azure when using a Service Principal."
}

variable "azure_tenant_id" {
  type        = string
  description = "The tenant ID associated with the Azure subscription. This is used to define the organization within Azure."
}
