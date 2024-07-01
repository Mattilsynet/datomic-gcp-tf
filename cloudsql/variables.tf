variable "project_id" {
  type = string
  description = "The project id"
}

variable "region" {
  type = string
  description = "The GCP region"
  default = "europe-north1"
}

variable "vpc_id" {
  description = "The ID of the VPC to deploy to"
  type = string
}

variable "storage_instance_tier" {
  type = string
  description = "Cloud SQL instance tier, see https://cloud.google.com/sql/pricing"
  default = "db-f1-micro"
}

variable "deletion_protection" {
  type = bool
  description = "Cloud SQL instance deletion protection"
  default = true
}

variable "db_deletion_policy" {
  type = string
  description = "Deletion policy for the database, one of ABANDON or DELETE"
  default = "ABANDON"
}

variable "user_deletion_policy" {
  type = string
  description = "Deletion policy for the database user, one of ABANDON or DELETE"
  default = "ABANDON"
}

variable "availability_type" {
  type = string
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)."
  default = "ZONAL"
}
