resource "docker_secret" "this" {
  for_each = local.secret_map

  name = substr(coalesce(each.value.secret_name, join("_", compact([var.namespace, "sec", var.name, uuid()]))), 0, 63)
  data = base64encode(each.value.secret_data)

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
    ignore_changes = [name, labels]
    # create_before_destroy = false
  }
}
