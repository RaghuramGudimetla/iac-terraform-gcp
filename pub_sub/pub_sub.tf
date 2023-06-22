resource "google_pubsub_topic" "pubsub_topic_trigger" {
  project = "${var.project_id}"
  name = "${var.project_id}-topic-trigger-cf"
}


resource "google_pubsub_subscription" "pubsub_subscription_trigger" {
  name = "${var.project_id}-subscription-trigger-cf"
  project = "${var.project_id}"
  topic = "${google_pubsub_topic.pubsub_topic_trigger.name}"
  ack_deadline_seconds = 20
}
