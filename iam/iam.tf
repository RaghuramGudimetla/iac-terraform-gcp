resource "google_project_iam_custom_role" "gcs_read" {
  role_id     = "gcsreadsnowflake"
  title       = "GCS Read"
  project     = var.project_id
  description = "Role to read the files from storage location"
  permissions = [
    "storage.objects.list", 
    "storage.objects.get", 
    "storage.buckets.get"
    ]
}