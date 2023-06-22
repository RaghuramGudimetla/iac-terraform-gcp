variable "project_id" {
  type    = string
  default = "raghuram-exec"
}

variable "region" {
  type    = string
  default = "australia-southeast1"
}

variable "zone" {
    type = string
    default = "australia-southeast1-a"
}

variable "active_services" {
    description = "Services that are active"
    type = list(string)
    default = [
        "iam.googleapis.com",
        "pubsub.googleapis.com",
        "cloudfunctions.googleapis.com",
        "cloudscheduler.googleapis.com",
        "cloudbuild.googleapis.com"
    ]
}