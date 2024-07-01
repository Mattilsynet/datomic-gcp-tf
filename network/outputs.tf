output "vpc_id" {
  value = google_compute_network.datomic_vpc.id
}

output "vpc_self_link" {
  value = google_compute_network.datomic_vpc.self_link
}

output "vpc_name" {
  value = google_compute_network.datomic_vpc.name
}

output "subnet_name" {
  value = google_compute_subnetwork.datomic_subnet.name
}

output "subnet_link" {
  value = google_compute_subnetwork.datomic_subnet.self_link
}
