resource "docker_volume" "this" {
  name        = trim(substr(join("_", compact([var.namespace, "vol", var.name, replace(uuid(), "-", "")])), 0, 63), "-_ ")
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

  lifecycle {
    // FIXME we have to ignore all labels: https://github.com/hashicorp/terraform/issues/26359
    ignore_changes = [name, labels]
  }
}
