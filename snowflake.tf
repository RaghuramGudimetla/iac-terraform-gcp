locals {
  snowflake_integrations = {
    snowflake_export = {
      project_id = var.project_id
      region     = var.region
      zone       = var.zone
    }
  }
  storage_int_sa      = "yngjpmjfqr@sfc-au-1-nla.iam.gserviceaccount.com"
  notification_int_sa = "smgwtyzpfn@sfc-au-1-nla.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "snowflake_subscription_viewer_permission" {
  project = var.project_id
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${local.notification_int_sa}"
}

module "snowflake" {
  source              = "./snowflake"
  for_each            = local.snowflake_integrations
  project_id          = each.value.project_id
  region              = each.value.region
  zone                = each.value.zone
  name                = each.key
  storage_int_sa      = local.storage_int_sa
  notification_int_sa = local.notification_int_sa
}
