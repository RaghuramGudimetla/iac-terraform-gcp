resource "google_storage_bucket" "function_files_bucket" {
  name     = "${var.project_id}-function-files"
  location = "us-east1"
  project  = var.project_id
}

data "archive_file" "data_extraction_source" {
  type        = "zip"
  source_dir  = "${path.module}/upload_gcs_file"
  output_path = ".data/data_extraction_function.zip"
}

resource "google_storage_bucket_object" "data_extraction_zip" {
  source       = data.archive_file.data_extraction_source.output_path
  content_type = "application/zip"

  name   = "src-${data.archive_file.data_extraction_source.output_md5}.zip"
  bucket = google_storage_bucket.function_files_bucket.name

  depends_on = [
    google_storage_bucket.function_files_bucket,
    data.archive_file.data_extraction_source
  ]
}

resource "google_cloudfunctions_function" "data_extraction_function" {
  name    = "extract-data-into-gcs"
  runtime = "python39"
  region  = var.region
  project = var.project_id

  source_archive_bucket = google_storage_bucket.function_files_bucket.name
  source_archive_object = google_storage_bucket_object.data_extraction_zip.name

  max_instances = 1

  entry_point = "upload_blob"

  # 
  event_trigger {
    event_type = "google.pubsub.topic.publish"
    resource   = "projects/${var.project_id}/topics/${var.project_id}-topic-trigger-cf"
  }

  depends_on = [
    google_storage_bucket.function_files_bucket, # declared in `storage.tf`
    google_storage_bucket_object.data_extraction_zip
  ]
}

resource "google_cloudfunctions_function_iam_member" "cloud_function_invoker" {
  project        = google_cloudfunctions_function.data_extraction_function.project
  region         = google_cloudfunctions_function.data_extraction_function.region
  cloud_function = google_cloudfunctions_function.data_extraction_function.name
  role           = "roles/cloudfunctions.invoker"
  member         = "allUsers"
}
