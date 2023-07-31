resource "google_storage_bucket" "data_extraction" {
  name          = "${var.project_id}-data-extraction"
  project       = "${var.project_id}"
  location      = "us-east1"
}