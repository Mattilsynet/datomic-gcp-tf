locals {
  vpc_connector_name = "datomic-access-connector"
}

resource "google_compute_network" "datomic_vpc" {
  provider = google-beta
  project = var.project_id
  name = "datomic-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "datomic_subnet" {
  provider = google-beta
  project = var.project_id
  name = "datomic-ip"
  ip_cidr_range = "10.0.0.0/28"
  network = google_compute_network.datomic_vpc.id
}

resource "google_project_service" "vpcaccess" {
  provider = google-beta
  project = var.project_id
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false

  timeouts {
    create = "10m"
    delete = "10m"
  }
}

resource "google_vpc_access_connector" "datomic_access_connector" {
  provider = google-beta
  project = var.project_id
  region = var.region
  name = local.vpc_connector_name
  subnet {
    name = google_compute_subnetwork.datomic_subnet.name
  }
  depends_on = [google_project_service.vpcaccess]
}
