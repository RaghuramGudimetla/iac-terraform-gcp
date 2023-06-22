resource "google_cloud_scheduler_job" "cloud_function_scheduler" {
  name        = "${var.project_id}-cloud-function-scheduler"
  description = "Scheduler to trigger pubsub to run cloud function"
  schedule    = "0 10 * * *"
  region = var.region
  project = var.project_id
  time_zone = "Pacific/Auckland"

  pubsub_target {
    topic_name = var.topic_id
    data       = base64encode("test")
  }
}