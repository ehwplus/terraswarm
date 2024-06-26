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

  labels {
    label = "controlled_by"
    value = "terraform"
  }

  labels {
    label = "io.terraform.provider.source"
    value = "kreuzwerker/docker"
  }

  labels {
    label = "io.terraform.provider.version"
    value = "3.0.2"
  }

  labels {
    label = "deployed_at"
    value = timestamp()
  }

  lifecycle {
    // FIXME we have to ignore all labels: https://github.com/hashicorp/terraform/issues/26359
    ignore_changes = [name, labels]
  }
}
