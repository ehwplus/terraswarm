resource "docker_network" "this" {
  name     = substr(join("_", compact([var.namespace, "net-${var.name}-${uuid()}"])), 0, 63)
  driver   = "overlay"
  internal = false

  dynamic "labels" {
    for_each = var.namespace == null ? [] : [1]

    content {
      label = "com.docker.stack.namespace"
      value = var.namespace
    }
  }

  lifecycle {
    ignore_changes = [name]
    # create_before_destroy = true
  }
}
