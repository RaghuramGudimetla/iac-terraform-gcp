# Bucket
resource "google_storage_bucket" "bucket" {
  name     = replace("${var.project_id}-${var.name}", "_", "-")
  project  = var.project_id
  location = var.region
}

# Pubsub
resource "google_pubsub_topic" "topic_snowflake_events" {
  project = var.project_id
  name    = replace("${var.project_id}-topic-${var.name}", "_", "-")
}

resource "google_pubsub_subscription" "subscription_snowflake_events" {
  name    = replace("${var.project_id}-subscription-${var.name}", "_", "-")
  project = var.project_id
  topic   = google_pubsub_topic.topic_snowflake_events.name

  message_retention_duration = "604800s"
  retain_acked_messages      = true
  ack_deadline_seconds       = 20
}

# Notifications
resource "google_storage_notification" "notification" {
  bucket         = google_storage_bucket.bucket.name
  payload_format = "JSON_API_V1"
  topic          = google_pubsub_topic.topic_snowflake_events.id
  event_types    = ["OBJECT_FINALIZE", "OBJECT_METADATA_UPDATE"]
  depends_on     = [google_pubsub_topic_iam_binding.binding]
}

# Roles

data "google_storage_project_service_account" "gcs_account" {
}

resource "google_pubsub_topic_iam_binding" "binding" {
  topic   = google_pubsub_topic.topic_snowflake_events.id
  role    = "roles/pubsub.publisher"
  members = ["serviceAccount:${data.google_storage_project_service_account.gcs_account.email_address}"]
}

resource "google_project_iam_custom_role" "snowflake_role" {
  role_id     = "snowflake_role"
  title       = "Snowflake role"
  description = "Role for snowflake to access bucket data"
  permissions = [
    "storage.buckets.get",
    "storage.objects.create",
    "storage.objects.delete",
    "storage.objects.get",
    "storage.objects.list"
  ]
}

resource "google_storage_bucket_iam_binding" "binding" {
  bucket = google_storage_bucket.bucket.name
  role   = google_project_iam_custom_role.snowflake_role.id
  members = [
    "serviceAccount:${var.storage_int_sa}",
  ]
}

resource "google_pubsub_subscription_iam_member" "editor" {
  subscription = google_pubsub_subscription.subscription_snowflake_events.name
  role         = "roles/pubsub.subscriber"
  member       = "serviceAccount:${var.notification_int_sa}"
}