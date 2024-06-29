# Datomic on GCP

A Terraform module, a Docker image, and an Ansible collection to run a Datomic
transactor on Google Cloud Platform (GCP).

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
tested with a postgresql CloudSQL instance. See below for instructions on how to
set this up.

The Ansible collection prepares the VM for running the Datomic transactor as a
Docker container on ports 4337, 4338 and 4339.

## How to use

To spin up the transactor you will perform three steps:

1. Run the Terraform module
2. Create a Cloud SQL instance in the same VPC
3. Configure and run the Ansible collection

### Running the Terraform module

### Creating a Cloud SQL instance

### Running the Ansible collection

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

## Local access to production

To access the production transactor you need to run two proxies: one for the
Postgresql storage backend and one for the transactor VM.

Download the [GCP Cloud SQL Auth
proxy](https://cloud.google.com/sql/docs/mysql/sql-proxy) to your machine. Make
sure to get one for your specific architecture, the following example works on
ARM Macs (otherwise see the link):

```sh
curl -o ~/bin/cloud-sql-proxy https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v2.11.4/cloud-sql-proxy.darwin.amd64
```

With the proxy installed, run it for your Cloud SQL instance:

```sh
cloud-sql-proxy $(gcloud sql instances describe datomic --format 'value(connectionName)')
```

This will run the proxy on the default host and port for Postgresql, e.g.
localhost:5432. This will not work if you're already running Postgres locally.
If so, adjust as necessary -- you can run it on another port, see `--help`.

Verify your connection:

```sh
psql -h localhost -U datomic-user datomic
```

When a Datomic peer establishes a connection, it will go to the storage to find
the location of the transactor. The transactor will give its location as
`10.124.0.2`, thus we need for that IP to resolve from our local machine in
order to reach it. You can add it as an alias on your en0 interface:

```sh
sudo ifconfig en0 alias 10.124.0.2 netmask 255.255.255.0
```

Next, run an SSH tunnel to the Datomic VM on this IP:

```sh
gcloud compute start-iap-tunnel \
  --local-host-port 10.124.0.2:4337 \
  datomic-vm 4337 \
  --zone europe-north1-a \
  --project project-id
```

Adjust project id and zone as appropriate. With the two proxies established, you
should now be able to connect to the transactor with the following connections
string:

```clj
"datomic:sql://datomic-db-name?jdbc:postgresql:///datomic?user=datomic-user&password=..."
```
