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

# Pubsub topic and subscription to consume multiple events at once
resource "google_pubsub_topic" "pubsub_topic_python_events" {
  project = "${var.project_id}"
  name = "${var.project_id}-topic-python-events"
}

resource "google_pubsub_subscription" "pubsub_subscription_python_events" {
  name = "${var.project_id}-subscription-python-events"
  project = "${var.project_id}"
  topic = "${google_pubsub_topic.pubsub_topic_python_events.name}"
  ack_deadline_seconds = 20
}