terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}
data "google_compute_subnetwork" "existing_subnetwork" {
  name   = var.subnetwork
  region = "us-central1"
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

resource "google_compute_disk" "web_disk" {
  name = "webserver-t-disk"
  size = 200
}

data "google_compute_address" "existing_static_ip" {
  name = var.static_ip
}
resource "google_compute_firewall" "http" {
  name    = "sep-allow-http"
  network = "sep-cluster-net"

  allow {
    protocol = "tcp"
    ports    = ["80"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["http-server-sep"]
}

resource "google_compute_firewall" "https" {
  name    = "sep-allow-https"
  network = "sep-cluster-net"

  allow {
    protocol = "tcp"
    ports    = ["443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["https-server-sep"]
}

resource "google_compute_instance" "webserver" {
  name         = var.webname
  machine_type = "n2-standard-4"
  zone         = var.zone

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-10"
      size  = 20
    }
  }

  attached_disk {
    source = google_compute_disk.web_disk.id
  }

  network_interface {
    network    = data.google_compute_subnetwork.existing_subnetwork.network
    subnetwork = data.google_compute_subnetwork.existing_subnetwork.self_link

    access_config {
      nat_ip = data.google_compute_address.existing_static_ip.address
    }
  }

  service_account {
    email = var.service_account
    scopes = [
      "https://www.googleapis.com/auth/devstorage.read_write",
      "https://www.googleapis.com/auth/logging.write",
      "https://www.googleapis.com/auth/monitoring.write",
    ]
  }

  metadata_startup_script = <<-EOT
    #!/bin/bash
    apt-get update
    apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release
    curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" > /etc/apt/sources.list.d/docker.list
    apt-get update
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose
    apt-get install -y google-cloud-sdk git nfs-kernel-server
    systemctl enable docker
    systemctl start docker 
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
    sudo mkdir /web
    echo UUID=$(sudo blkid -s UUID -o value /dev/sdb) /web ext4 defaults 0 0 | sudo tee -a /etc/fstab
    sudo mount /web
    mkdir -p /web/gitlab/etc /web/build /mnt/filestore
    mount -t nfs  ${var.filestore_ip_address}:/${var.filestore_name} /mnt/filestore
    ln -s /mnt/filestore/html /web/html
    cd /web &&\
    git clone https://github.com/rgclapp007/terraform-docker-gitlab-web.git build
    gsutil cp ${var.config_path}/env /web/build/web/compose/.env
    cd /web/build/web/compose &&
    docker-compose  up -d
  EOT

  tags = ["http-server-sep", "https-server-sep"]
}
