resource "google_compute_network" "datomic_vpc" {
  provider = google-beta
  name = "datomic-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "datomic_subnet" {
  provider = google-beta
  name = "datomic-ip"
  ip_cidr_range = "10.0.0.0/24"
  network = google_compute_network.datomic_vpc.id
}
