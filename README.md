# Datomic on GCP

A Terraform module to run Datomic on a Compute Engine VM in a VPC on Google
Cloud Platform.

## SSH into the VM

```
gcloud compute ssh --zone "europe-north1-a" "datomic-vm" --tunnel-through-iap --project "matnyttig-bb8c"
```

## Setting up a Cloudsql instance

```hcl
resource "google_sql_database_instance" "db_instance" {
  name = "pluggable-storage"
  database_version = "POSTGRES_15"
  region = var.region

  settings {
    tier = var.storage_instance_tier
  }

  deletion_protection = "true"
}

resource "google_sql_database" "database" {
  name = "datomic"
  instance = google_sql_database_instance.db_instance.name
  charset = "UTF8"
  collation = "en_US.UTF8"
}

resource "random_password" "db_password" {
  length = 24
  special = true
}

resource "google_sql_user" "user" {
  name = "datomic"
  instance = google_sql_database_instance.db_instance.name
  password = random_password.db_password.result
}
```
