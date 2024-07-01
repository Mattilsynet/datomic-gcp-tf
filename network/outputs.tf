output "vpc_id" {
  value = google_compute_network.datomic_vpc.id
}

output "subnet_link" {
  value = google_compute_subnetwork.datomic_subnet.self_link
}
