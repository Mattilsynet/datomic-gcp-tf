output "vpc_id" {
  value = google_compute_network.datomic_vpc.id
}

output "vpc_name" {
  value = google_compute_network.datomic_vpc.name
}
