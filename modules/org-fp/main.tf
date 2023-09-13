locals {
  gce_zone = "${var.input_region}-b"
}

resource "google_compute_network" "tf_vpc" {
  project                 = var.input_project
  name                    = "${var.input_prefix}-vpc"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "tf_subnet" {
  name          = "${var.input_prefix}-${var.input_region}"
  ip_cidr_range = "192.168.0.0/24"
  region        = var.input_region
  network       = google_compute_network.tf_vpc.id
}

resource "google_compute_instance" "tf_vm" {
  for_each     = var.tf_vms
  name         = "${var.input_prefix}-vm-${each.value.suffix_name}"
  machine_type = "${each.value.machine_type}"
  zone         = local.gce_zone

  tags = ["www"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.tf_vpc.id
    subnetwork = google_compute_subnetwork.tf_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "apt update && apt install -y nginx"

}

resource "google_compute_firewall" "allow_ingress_80" {
  name    = "${var.input_prefix}-allow-ingress-80"
  network = google_compute_network.tf_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["192.168.0.0/24"]
  target_tags = ["www"]
}

resource "google_compute_firewall" "allow_ingress_iap" {
  name    = "${var.input_prefix}-allow-ingress-iap"
  network = google_compute_network.tf_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["35.235.240.0/20"]
}

resource "google_compute_instance_group" "fp_uig" {
  name        = "${var.input_prefix}-uig"
  description = "FP unmanaged instance group"
  zone        = local.gce_zone
  network     = google_compute_network.tf_vpc.id
  instances   = [for vm in google_compute_instance.tf_vm: vm.id]

  named_port {
    name = "http"
    port = "80"
  }
}

module "ilb" {
  source        = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-lb-int"
  project_id    = var.input_project
  region        = var.input_region
  name          = "${var.input_prefix}-ilb"
  service_label = "${var.input_prefix}-ilb"
  vpc_config = {
    network    = google_compute_network.tf_vpc.id
    subnetwork = google_compute_subnetwork.tf_subnet.id
  }
  backends = [{
    group = google_compute_instance_group.fp_uig.id
  }]
  health_check_config = {
    http = {
      port = 80
    }
  }
}

module "nat" {
  source         = "github.com/terraform-google-modules/cloud-foundation-fabric//modules/net-cloudnat"
  project_id     = var.input_project
  region         = var.input_region
  name           = "${var.input_prefix}-nat"
  router_network = google_compute_network.tf_vpc.id
}

resource "google_compute_firewall" "fw_health_check" {
  name    = "${var.input_prefix}-health-check"
  network = google_compute_network.tf_vpc.id

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = data.google_netblock_ip_ranges.hcs-range.cidr_blocks_ipv4
  target_tags = ["www"]
}

resource "google_compute_instance" "tf_vm_client" {

  name         = "${var.input_prefix}-client"
  machine_type = "e2-micro"
  zone         = local.gce_zone

  tags = ["www"]

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.tf_vpc.id
    subnetwork = google_compute_subnetwork.tf_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

  metadata_startup_script = "apt update && apt install -y nginx"

  lifecycle {
    ignore_changes = [
      metadata
    ]
  }

}

resource "google_compute_instance" "my_vm_client_manual" {

  name         = "${var.input_prefix}-client-manual"
  machine_type = "e2-micro"
  zone         = local.gce_zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    network = google_compute_network.tf_vpc.id
    subnetwork = google_compute_subnetwork.tf_subnet.id
    access_config {
      // Ephemeral public IP
    }
  }

}

data "google_netblock_ip_ranges" "hcs-range" {
  range_type = "health-checkers"
}

resource "google_storage_bucket" "default" {
  name                        = "${var.input_prefix}-tfstate"
  project                     = google_compute_network.tf_vpc.project
  location                    = "EU"
  uniform_bucket_level_access = true
  force_destroy               = true

  versioning {
    enabled = true
  }
}
