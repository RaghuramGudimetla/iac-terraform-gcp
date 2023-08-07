locals {
  write_function_name = "write_pubsub_events"
}

data "archive_file" "write_pubsub_events_source" {
  type        = "zip"
  source_dir  = "${path.module}/${local.write_function_name}"
  output_path = ".data/${local.write_function_name}.zip"
}

resource "google_storage_bucket_object" "write_pubsub_events_zip" {
  source       = data.archive_file.write_pubsub_events_source.output_path
  content_type = "application/zip"

  name   = "src-${data.archive_file.write_pubsub_events_source.output_md5}.zip"
  bucket = google_storage_bucket.function_files_bucket.name

  depends_on = [
    google_storage_bucket.function_files_bucket,
    data.archive_file.write_pubsub_events_source
  ]
}

resource "google_service_account" "write_events_service_account" {
  account_id   = "write-events"
  display_name = "Write pubsub events"
  description  = "Service Account used by cloud function ro write events"
  project      = var.project_id
}

resource "google_cloudfunctions_function" "write_pubsub_events_function" {
  name    = "write-pubsub-events"
  runtime = "python310"
  region  = var.region
  project = var.project_id
  source_archive_bucket = google_storage_bucket.function_files_bucket.name
  source_archive_object = google_storage_bucket_object.write_pubsub_events_zip.name
  max_instances = 1
  entry_point = "write_events"
  trigger_http = true
  service_account_email = google_service_account.write_events_service_account.email
  depends_on = [
    google_storage_bucket.function_files_bucket, # declared in `storage.tf`
    google_storage_bucket_object.write_pubsub_events_zip
  ]
}

resource "google_cloudfunctions_function_iam_member" "write_events_cloud_function_invoker" {
  project        = google_cloudfunctions_function.write_pubsub_events_function.project
  region         = google_cloudfunctions_function.write_pubsub_events_function.region
  cloud_function = google_cloudfunctions_function.write_pubsub_events_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.write_events_service_account.email}"
}

resource "google_pubsub_topic_iam_binding" "write_events_pubsub_binding" {
  project = var.project_id
  topic = "${var.project_id}-topic-python-events"
  role = "roles/pubsub.publisher"
  members = [
    "serviceAccount:${google_service_account.write_events_service_account.email}",
  ]
}

# Write function
/*
resource "google_cloudfunctions2_function" "write_pubsub_events_function" {
  name        = "write-pubsub-events"
  provider    = "google-beta"
  location    = var.region
  project     = var.project_id
  description = "Function to write events to pubsub"

  build_config {
    runtime     = "python310"
    entry_point = "write_events"
    source {
      storage_source {
        bucket = google_storage_bucket.function_files_bucket.name
        object = google_storage_bucket_object.write_pubsub_events_zip.name
      }
    }
  }
  service_config {
    max_instance_count    = 1
    min_instance_count    = 1
    available_memory      = "256M"
    timeout_seconds       = 30
    service_account_email = google_service_account.write_events_service_account.email
  }

  depends_on = [
    google_storage_bucket.function_files_bucket,
    google_storage_bucket_object.write_pubsub_events_zip
  ]
}

resource "google_cloudfunctions_function_iam_member" "invoker" {
  project        = google_cloudfunctions2_function.write_pubsub_events_function.project
  region         = google_cloudfunctions2_function.write_pubsub_events_function.location
  cloud_function = google_cloudfunctions2_function.write_pubsub_events_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.write_events_service_account.email}"
}
*/