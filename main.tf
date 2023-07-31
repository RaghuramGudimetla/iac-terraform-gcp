terraform {
  required_providers {
    google-beta = {
      source = "hashicorp/google-beta"
      version = "4.40.0"
    }
  }
}

provider "google" {
  credentials = file("raghuram-exec.json")
  project = "raghuram-exec"
  region  = "australia-southeast1"
  zone    = "australia-southeast1-a"
}

terraform {
  backend "gcs" {
    bucket  = "iac-terraform-gcp"
    prefix  = "terraform/state"
  }
}

module "iam" {
  source = "./iam"
  project_id = var.project_id
  region = var.region
  zone = var.zone
}

module "buckets" {
  source = "./buckets"
  project_id = var.project_id
  region = var.region
  zone = var.zone
}

module "pub_sub" {
  source = "./pub_sub"
  project_id = var.project_id
  region = var.region
  zone = var.zone
  depends_on = [ 
    module.buckets,
    google_project_service.project_active_services
  ]
}

module "cloud_scheduler" {
  source = "./cloud_scheduler"
  project_id = var.project_id
  region = var.region
  zone = var.zone
  topic_id = module.pub_sub.topic_id
  depends_on = [ 
    module.pub_sub,
    google_project_service.project_active_services
  ]
}

module "cloud_functions" {
  source = "./cloud_functions"
  project_id = var.project_id
  region = var.region
  zone = var.zone
  depends_on = [ 
    module.pub_sub,
    module.cloud_scheduler,
    module.buckets,
    google_project_service.project_active_services
  ]
}

module "prefect" {
  source = "./prefect"
  project_id = var.project_id
  region = var.region
  zone = var.zone
}

resource "google_project_service" "project_active_services" {
  for_each = toset(var.active_services)
  project = var.project_id
  service = each.key
  disable_dependent_services = true
}