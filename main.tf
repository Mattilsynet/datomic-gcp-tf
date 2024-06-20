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

resource "google_compute_address" "datomic_server_ip" {
  project = var.project_id
  name = "datomic-ip"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.datomic-subnet.self_link
  region = var.region
}

resource "google_compute_instance" "datomic_server" {
  project = var.project_id

  labels = {
    project = var.project_id
    server = "datomic"
  }

  name = "datomic-vm"
  machine_type = var.machine_type
  zone = "${var.region}-${var.zone}"

  tags = ["datomic-server"]

  metadata = {
    enable-oslogin = "TRUE"
    enable-osconfig = "TRUE"
    enable-guest-attributes = "TRUE"
  }

  min_cpu_platform = "AUTOMATIC"

  scheduling {
    on_host_maintenance = "MIGRATE"
  }

  boot_disk {
    initialize_params {
      image = "ubuntu-minimal-2204-jammy-v20230918"
      labels = {
        os = "ubuntu"
      }
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.datomic-subnet.self_link
    network_ip = google_compute_address.datomic_server_ip.address
  }

  service_account {
    email = google_service_account.datomic-sa.email
    scopes = [
      "userinfo-email",
      "compute-ro",
      "storage-ro",
      "cloud-platform"
    ]
  }

  metadata_startup_script = "#!/bin/bash\necho Hello, World! > /home/username/gce-test.txt"
}
