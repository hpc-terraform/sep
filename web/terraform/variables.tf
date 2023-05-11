variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Google Cloud region"
  type        = string
  default     = "us-central1"
}
variable "zone" {
  description = "Google Cloud zone"
  type        = string
  default     = "us-central1-c"
}

variable "webname" {
  description = "Name of the webserver instance"
  type        = string
}
variable "service_account" {
  description = "Sevice account to use"
  type        = string
}
variable "config_path" {
  description = "GCS path for configuration"
  type        = string
}
variable "network" {
  description = "Network to use"
  type        = string
}
variable "subnetwork" {
  description = "Subnetwork to use"
  type        = string
}
variable "filestore_name" {
  description = "Name of filestore"
  type        = string
}

variable "filestore_ip_address" {
  description = "IP address of filestore"
  type        = string
}

variable "static_ip" {
  description = "Static IP for"
  type        = string
}
