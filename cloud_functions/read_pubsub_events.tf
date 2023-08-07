locals {
    function_name = "read_pubsub_events"
}

data "archive_file" "read_pubsub_events_source" {
  type        = "zip"
  source_dir  = "${path.module}/${local.function_name}"
  output_path = ".data/${local.function_name}.zip"
}

resource "google_storage_bucket_object" "read_pubsub_events_zip" {
  source       = data.archive_file.read_pubsub_events_source.output_path
  content_type = "application/zip"

  name   = "src-${data.archive_file.read_pubsub_events_source.output_md5}.zip"
  bucket = google_storage_bucket.function_files_bucket.name

  depends_on = [
    google_storage_bucket.function_files_bucket,
    data.archive_file.read_pubsub_events_source
  ]
}

resource "google_service_account" "read_events_service_account" {
  account_id   = "read-events"
  display_name = "Read pubsub events"
  description  = "Service Account used by cloud function ro read events"
  project      = var.project_id
}

resource "google_cloudfunctions_function" "read_pubsub_events_function" {
  name    = "read-pubsub-events"
  runtime = "python310"
  region  = var.region
  project = var.project_id
  source_archive_bucket = google_storage_bucket.function_files_bucket.name
  source_archive_object = google_storage_bucket_object.read_pubsub_events_zip.name
  max_instances = 1
  entry_point = "read_events_to_bucket"
  trigger_http = true
  service_account_email = google_service_account.read_events_service_account.email
  depends_on = [
    google_storage_bucket.function_files_bucket, # declared in `storage.tf`
    google_storage_bucket_object.read_pubsub_events_zip
  ]
}

resource "google_cloudfunctions_function_iam_member" "events_cloud_function_invoker" {
  project        = google_cloudfunctions_function.read_pubsub_events_function.project
  region         = google_cloudfunctions_function.read_pubsub_events_function.region
  cloud_function = google_cloudfunctions_function.read_pubsub_events_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "serviceAccount:${google_service_account.write_events_service_account.email}"
}

resource "google_pubsub_subscription_iam_binding" "read_events_pubsub_binding" {
  project = var.project_id
  subscription = "${var.project_id}-subscription-python-events"
  role = "roles/pubsub.subscriber"
  members = [
    "serviceAccount:${google_service_account.read_events_service_account.email}",
  ]
}