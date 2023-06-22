variable "project_id" {
  type    = string
}

variable "region" {
  type    = string
}

variable "zone" {
  type    = string
}

output "topic_id" {
  value       = google_pubsub_topic.pubsub_topic_trigger.id
  description = "Topic id to be used in other modules"
}