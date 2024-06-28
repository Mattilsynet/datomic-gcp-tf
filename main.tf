locals {
  vpc_connector_name = "datomic-access-connector"
}

resource "google_compute_network" "datomic_vpc" {
  provider = google-beta
  name = "datomic-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "datomic_subnet" {
  provider = google-beta
  name = "datomic-ip"
  ip_cidr_range = "10.124.0.0/28"
  network = google_compute_network.datomic_vpc.id
  region = var.region
}

resource "google_project_service" "vpcaccess" {
  provider = google-beta
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_vpc_access_connector" "datomic_access_connector" {
  provider = google-beta
  name = local.vpc_connector_name
  region = var.region
  subnet {
    name = google_compute_subnetwork.datomic_subnet.name
  }
  depends_on = [
    google_project_service.vpcaccess
  ]
}

resource "google_service_account" "datomic_sa" {
  account_id = "datomic-sa"
}

resource "google_project_iam_binding" "cloud_sql_client" {
  project = var.project_id
  role = "roles/cloudsql.client"

  members = [
    "serviceAccount:${google_service_account.datomic_sa.email}"
  ]
}

resource "google_project_iam_binding" "secretmanager_access" {
  project = var.project_id
  role = "roles/secretmanager.secretAccessor"

  members = [
    "serviceAccount:${google_service_account.datomic_sa.email}"
  ]
}

resource "google_project_iam_binding" "secretmanager_viewer" {
  project = var.project_id
  role = "roles/secretmanager.viewer"

  members = [
    "serviceAccount:${google_service_account.datomic_sa.email}"
  ]
}

resource "google_project_iam_binding" "map_compute_viewer" {
  project = var.project_id
  role = "roles/compute.viewer"

  members = [
    "serviceAccount:${google_service_account.datomic_sa.email}"
  ]
}

resource "google_compute_address" "datomic_server_ip" {
  name = "datomic-ip"
  address_type = "INTERNAL"
  subnetwork = google_compute_subnetwork.datomic_subnet.self_link
  region = var.region
}

resource "google_compute_instance" "datomic_server" {
  labels = {
    server = "datomic"
  }

  name = "datomic-vm"
  machine_type = var.vm_machine_type
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
    subnetwork = google_compute_subnetwork.datomic_subnet.self_link
    network_ip = google_compute_address.datomic_server_ip.address
  }

  service_account {
    email = google_service_account.datomic_sa.email
    scopes = [
      "userinfo-email",
      "compute-ro",
      "storage-ro",
      "cloud-platform"
    ]
  }

  metadata_startup_script = "#!/bin/bash\necho Hello, World! > /home/username/gce-test.txt"
}

resource "google_project_iam_binding" "iam_binding_iap_tunnel_accessor" {
  project = var.project_id
  members = var.iap_access_members
  role = "roles/iap.tunnelResourceAccessor"
}

# Allow SSH in from outside of GCP through IAP

resource "google_compute_firewall" "allow_ssh_ingress_from_iap" {
  project = var.project_id
  name = "allow-ssh-ingress-from-iap"
  network = google_compute_network.datomic_vpc.id
  direction = "INGRESS"
  allow {
    protocol = "TCP"
    ports = [22]
  }
  source_ranges = ["35.235.240.0/20"]
}

# Allow outbound traffic from the VM

resource "google_compute_firewall" "gcf_egress_general_from_servers" {
  project = var.project_id
  name = "gcf-egress-general-from-servers"
  network = google_compute_network.datomic_vpc.id
  direction = "EGRESS"
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcf_ingress_datomic_from_servers" {
  project = var.project_id
  name = "gcf-ingress-datomic-from-servers"
  network = google_compute_network.datomic_vpc.id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["4337", "4338", "4339"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# These are required for the machine to reach the internet

resource "google_compute_router" "datomic_router" {
  name = "datomic-router"
  region = google_compute_subnetwork.datomic_subnet.region
  network = google_compute_network.datomic_vpc.id

  bgp {
    asn = 64514
  }
}

module "cloud-nat" {
  source = "terraform-google-modules/cloud-nat/google"
  version = "~> 5.0"
  project_id = google_compute_router.datomic_router.project
  region = google_compute_router.datomic_router.region
  router = google_compute_router.datomic_router.name
  name = "nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
