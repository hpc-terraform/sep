terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "3.5.0"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
}

resource "google_compute_disk" "web_disk" {
  name = "web-disk"
  size = 1200
}

resource "google_compute_address" "static_ip" {
  name = "webserver-static-ip"
}


resource "google_compute_instance" "webserver" {
  name         = var.webname
  machine_type = "n1-standard-2"
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
    network = "default"

    access_config {
      nat_ip = google_compute_address.static_ip.address
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
    apt-get install -y google-cloud-sdk git
    systemctl enable docker
    systemctl start docker 
    sudo mkfs.ext4 -m 0 -E lazy_itable_init=0,lazy_journal_init=0,discard /dev/sdb
    sudo mkdir /web
    echo UUID=$(sudo blkid -s UUID -o value /dev/sdb) /web ext4 defaults 0 0 | sudo tee -a /etc/fstab
    sudo mount /web
    mkdir -p /web/gitlab/etc /web/build
    cd /web &&\
    git clone https://github.com/rgclapp007/terraform-docker-gitlab-web.git build
    gsutil cp ${var.config_path}/env /web/build/compose/.env
    gsutil cp -r ${var.config_path}/nginx /web/nginx
    cd /web/build/compose &&
    docker-compose  up -d
  EOT

  tags = ["http-server","https-server"]
}

