resource "docker_config" "this" {
  for_each = local.config_map

  name = substr(coalesce(each.value.config_name, join("_", compact([var.namespace, "cfg", var.name, uuid()]))), 0, 63)
  data = base64encode(each.value.config_data)

  lifecycle {
    ignore_changes = [name]
    # create_before_destroy = false
  }
}
