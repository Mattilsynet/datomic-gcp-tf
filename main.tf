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
