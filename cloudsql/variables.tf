variable "vpc_self_link" {
  type = string
  description = "self_link of the Datomic VPC"
}

variable "storage_instance_tier" {
  type = string
  description = "Cloud SQL instance tier, see https://cloud.google.com/sql/pricing"
  default = "db-f1-micro"
}

variable "deletion_protection" {
  type = boolean
  description = "Cloud SQL instance deletion protection"
  default = true
}

variable "db_deletion_policy" {
  type = string
  description = "Deletion policy for the database, one of ABANDON or DELETE"
  default = "ABANDON"
}

variable "availability_type" {
  type = string
  description = "The availability type of the Cloud SQL instance, high availability (REGIONAL) or single zone (ZONAL)."
  default = "ZONAL"
}
