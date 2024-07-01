output "vpc_connector_name" {
  value = local.vpc_connector_name
}

output "service_account_email" {
  value = google_service_account.datomic_sa.email
}
