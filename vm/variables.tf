variable "project_id" {
  type = string
  description = "The project id"
}

variable "region" {
  type = string
  description = "The GCP region"
  default = "europe-north1"
}

variable "subnet_link" {
  type = string
  description = "The self_link of the subnetwork to put the VM in"
}

variable "zone" {
  type = string
  description = "The GCP availability zone, a/b/c"
  default = "a"
}

variable "vpc_id" {
  type = string
  description = "The VPC id"
}

variable "vm_machine_type" {
  type = string
  description = "The GCP instance type for the Datomic transactor VM"
  default = "e2-standard-2"
}

variable "iap_access_members" {
  type = list
  description = "Which members should have access to the Datomic VPC IAP accessor"
}
