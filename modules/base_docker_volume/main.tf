locals {
  common_deployment_labels = {
    controlled_by                   = "terraform"
    "io.terraform.provider.source"  = "kreuzwerker/docker"
    "io.terraform.provider.version" = "3.0.2"
    deployed_at                     = timestamp()
  }
}

resource "docker_volume" "this" {
  name        = substr(join("_", compact([var.namespace, "vol", var.name, uuid()])), 0, 63)
  driver      = var.driver
  driver_opts = var.driver_options

  dynamic "labels" {
    for_each = var.namespace == null ? [] : [1]
    content {
      label = "com.docker.stack.namespace"
      value = var.namespace
    }
  }

  dynamic "labels" {
    for_each = local.common_deployment_labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  lifecycle {
    ignore_changes = [name]
    # create_before_destroy = true
    # prevent_destroy = true
  }
}
