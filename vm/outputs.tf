output "service_account_email" {
  value = google_service_account.datomic_sa.email
}
