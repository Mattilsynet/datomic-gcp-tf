resource "google_compute_network" "datomic-vpc" {
  provider = google-beta
  project = var.project_id
  name = "datomic-network"
}

resource "google_compute_subnetwork" "datomic-subnet" {
  provider = google-beta
  project = var.project_id
  name = "datomic-ip"
  ip_cidr_range = "10.124.0.0/28"
  network = google_compute_network.datomic-vpc.id
  region = var.region
}

resource "google_project_service" "vpcaccess" {
  provider = google-beta
  project = var.project_id
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_vpc_access_connector" "datomic-access-connector" {
  provider = google-beta
  project = var.project_id
  name = "datomic-access-connector"
  region = var.region
  subnet {
    name = google_compute_subnetwork.datomic-subnet.name
  }
  depends_on = [
    google_project_service.vpcaccess
  ]
}

resource "google_service_account" "datomic-sa" {
  project = var.project_id
  account_id = "datomic-sa"
}

resource "google_project_iam_binding" "map_cloud_sql_client" {
  project = var.project_id
  role = "roles/cloudsql.client"

  members = [
    "serviceAccount:${google_service_account.datomic-sa.email}"
  ]
}

resource "google_project_iam_binding" "map_compute_viewer" {
  project = var.project_id
  role = "roles/compute.viewer"

  members = [
    "serviceAccount:${google_service_account.datomic-sa.email}"
  ]
}
