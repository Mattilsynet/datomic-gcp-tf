locals {
  database_name = "datomic"
  database_username = "datomic-user"
}

resource "google_compute_global_address" "cloudsql_private_ip" {
  provider = google-beta
  name = "datomic-storage-private-ip"
  purpose = "VPC_PEERING"
  address_type = "INTERNAL"
  prefix_length = 24
  network = var.vpc_self_link
}

resource "google_service_networking_connection" "private_vpc_connection" {
  provider = google-beta
  network = var.vpc_self_link
  service = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.cloudsql_private_ip.name]
}

resource "google_project_service" "vpc_access_connector" {
  service = "vpcaccess.googleapis.com"

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_vpc_access_connector" "vpc_access_connector" {
  name = "datomic-storage-vpc-access-conn"
  network = var.vpc_self_link
  ip_cidr_range = "10.8.0.0/24"
  depends_on = [google_project_service.vpc_access_connector]
}

resource "google_sql_database_instance" "db_instance" {
  name = "datomic-storage"
  database_version = "POSTGRES_15"

  settings {
    deletion_protection_enabled = var.deletion_protection
    activation_policy = "ALWAYS"
    availability_type = var.availability_type
    tier = var.storage_instance_tier

    ip_configuration {
      ipv4_enabled = false
      private_network = var.vpc_self_link
      require_ssl = true
      ssl_mode = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
    }
  }

  deletion_protection = var.deletion_protection
}

resource "google_sql_database" "database" {
  name = local.database_name
  instance = google_sql_database_instance.db_instance.name
  charset = "UTF8"
  collation = "en_US.UTF8"
  deletion_policy = var.db_deletion_policy
}

resource "google_secret_manager_secret" "cloudsql_db_server_cert" {
  secret_id = "db-datomic-server-cert"

  labels = {
    "type" = "db-server-cert"
    "db" = local.database_name
  }
}

resource "google_secret_manager_secret_version" "cloudsql_db_server_cert" {
  secret = google_secret_manager_secret.cloudsql_db_server_cert.id
  secret_data = google_sql_database_instance.db_instance.server_ca_cert.cert
}

resource "random_string" "cloudsql_user_password" {
  length = 16
  special = false
}

resource "google_secret_manager_secret" "cloudsql_database_user_password" {
  secret_id = "db-${local.database_username}-password"

  labels = {
    "type" = "db-user-password"
    "db-user" = local.database_username
    "db" = local.database_name
  }
}

resource "google_secret_manager_secret" "cloudsql_database_user_name" {
  secret_id = "db-${local.database_username}-name"

  labels = {
    "type" = "db-username"
    "db-user" = local.database_username
    "db" = local.database_name
  }
}

resource "google_secret_manager_secret_version" "cloudsql_database_user_password" {
  secret = google_secret_manager_secret.cloudsql_database_user_password.id
  secret_data = random_string.cloudsql_user_password.result
}

resource "google_secret_manager_secret_version" "cloudsql_database_user_name" {
  secret = google_secret_manager_secret.cloudsql_database_user_name.id
  secret_data = local.database_username
}

resource "google_sql_user" "cloudsql_database_user" {
  instance = google_sql_database.database.name
  name = local.database_username
  password = google_secret_manager_secret_version.cloudsql_database_user_password.secret_data
  deletion_policy = var.user_deletion_policy
}

resource "google_sql_ssl_cert" "client_cert" {
  common_name = local.database_username
  instance = google_sql_database.database.name
}

resource "google_secret_manager_secret" "cloudsql_sm_user_private_keys" {
  secret_id = "db-${var.database_name}-${local.database_username}-client-private-key"

  labels = {
    type = "private-key"
    "db-user" = local.database_username
    "db" = var.database_name
  }
}

resource "google_secret_manager_secret_version" "cloudsql_sm_user_private_keys" {
  secret = google_secret_manager_secret.cloudsql_sm_user_private_keys.id
  secret_data = google_sql_ssl_cert.client_cert.private_key
}

resource "google_secret_manager_secret" "cloudsql_sm_user_client_certs" {
  secret_id = "db-${var.database_name}-${local.database_username}-client-cert"

  labels = {
    type = "client-cert"
    "db-user" = local.database_username
    "db" = var.database_name
  }
}

resource "google_secret_manager_secret_version" "cloudsql_sm_user_client_certs" {
  secret = google_secret_manager_secret.cloudsql_sm_user_client_certs.id
  secret_data = google_sql_ssl_cert.client_cert.cert
}
