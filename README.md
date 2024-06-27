# Datomic on GCP

A Terraform module and Ansible collection to run a Datomic transactor on Google
Cloud Platform (GCP).

## Overview

The Terraform module installs the following resources (see [main.tf](./main.tf)
for details:

- A virtual private network (VPC) with a single subnet
- A VPC access connector for Google serverless components (e.g. to be able to
  connect from CloudRun)
- A service account with the following roles:
  - [`roles/cloudsql.client`](https://cloud.google.com/sql/docs/mysql/iam-roles)
  - [`roles/secretmanager.secretAccessor`](https://cloud.google.com/secret-manager/docs/access-control)
  - [`roles/secretmanager.viewer`](https://cloud.google.com/secret-manager/docs/access-control)
  - [`roles/compute.viewer`](https://cloud.google.com/compute/docs/access/iam)
- A Compute Engine VM
- An [IAP tunnel accessor](https://cloud.google.com/iap/docs/concepts-overview)
  for GCP authorized SSH access.
- A NAT for outbound traffic from the VM

The Terraform module does not set up a storage backend. It is recommended to
manage the life-cycle of the storage backend (where your data lives) and the
transactor VM (stateless) separately. The module has been developed for, and
tested with a postgresql CloudSQL instance. See below for how to set this up.

The Ansible collection prepares the VM for running the Datomic transactor 

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
