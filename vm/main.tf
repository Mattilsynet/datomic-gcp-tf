resource "google_service_account" "datomic_sa" {
  project = var.project_id
  account_id = "datomic-sa"
}

resource "google_project_iam_member" "cloud_sql_client" {
  project = var.project_id
  role = "roles/cloudsql.client"
  member = "serviceAccount:${google_service_account.datomic_sa.email}"
}

resource "google_project_iam_member" "secretmanager_access" {
  project = var.project_id
  role = "roles/secretmanager.secretAccessor"
  member = "serviceAccount:${google_service_account.datomic_sa.email}"
}

resource "google_project_iam_member" "secretmanager_viewer" {
  project = var.project_id
  role = "roles/secretmanager.viewer"
  member = "serviceAccount:${google_service_account.datomic_sa.email}"
}

resource "google_project_iam_member" "compute_viewer" {
  project = var.project_id
  role = "roles/compute.viewer"
  member = "serviceAccount:${google_service_account.datomic_sa.email}"
}

resource "google_compute_address" "datomic_server_ip" {
  project = var.project_id
  region = var.region
  name = "datomic-ip"
  address_type = "INTERNAL"
  subnetwork = var.subnet_link
}

resource "google_compute_instance" "datomic_server" {
  project = var.project_id

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
    subnetwork = var.subnet_link
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

resource "google_project_iam_member" "iap_tunnel_accessor" {
  count = length(var.iap_access_members)
  project = var.project_id
  member = var.iap_access_members[count.index]
  role = "roles/iap.tunnelResourceAccessor"
}

# Allow SSH in from outside of GCP through IAP

resource "google_compute_firewall" "allow_ssh_ingress_from_iap" {
  project = var.project_id
  name = "allow-ssh-ingress-from-iap"
  network = var.vpc_id
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
  network = var.vpc_id
  direction = "EGRESS"
  allow {
    protocol = "all"
  }

  destination_ranges = ["0.0.0.0/0"]
}

resource "google_compute_firewall" "gcf_ingress_datomic_from_servers" {
  project = var.project_id
  name = "gcf-ingress-datomic-from-servers"
  network = var.vpc_id
  direction = "INGRESS"
  allow {
    protocol = "tcp"
    ports = ["4337", "4338", "4339"]
  }

  source_ranges = ["0.0.0.0/0"]
}

# These are required for the machine to reach the internet

resource "google_compute_router" "datomic_router" {
  project = var.project_id
  region = var.region
  network = var.vpc_id
  name = "datomic-router"

  bgp {
    asn = 64514
  }
}

module "cloud-nat" {
  source = "terraform-google-modules/cloud-nat/google"
  project_id = var.project_id
  region = var.region
  version = "~> 5.0"
  router = google_compute_router.datomic_router.name
  name = "nat-config"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}
