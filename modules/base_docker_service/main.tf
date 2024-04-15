locals {
  # Create a map with statically defined keys
  # According to https://jeffbrown.tech/terraform-for-each-index/#Solutions_to_Terraform_for_each_Index_Issues
  config_map = { for idx, config in tolist(var.configs) : coalesce(config.config_name, idx) => config }
  secret_map = merge(var.secret_map, { for _, secret in tolist(var.secrets) : secret.file_name => secret if secret.secret_id == null })
  # TODO enable secret_id for secret_map at some point and merge maps of preexisting secrets
  preexisting_secrets_map = { for _, secret in tolist(var.secrets) : secret.file_name => secret if secret.secret_id != null }

  #
  # local mounts
  #
  default_mounts = [
    {
      target         = "/etc/localtime"
      source         = "/etc/localtime"
      type           = "bind"
      read_only      = true
      tmpfs_options  = null
      volume_options = null
    }
  ]
  all_mounts = concat(tolist(local.default_mounts), tolist(var.mounts))

  #
  # local labels
  #
  common_deployment_labels = {
    controlled_by                   = "terraform"
    "io.terraform.provider.source"  = "kreuzwerker/docker"
    "io.terraform.provider.version" = "3.0.2"
    deployed_at                     = timestamp()
  }
  common_svc_labels = {
    "com.docker.stack.image" = "${var.image}:${var.image_tag}"
  }
  all_labels = merge(
    var.labels,
    local.common_deployment_labels,
    local.common_svc_labels,
  )

  #
  # local network aliases
  #
  all_network_aliases = concat(
    var.network_aliases,
    [var.name]
  )
}


resource "docker_service" "this" {
  name = substr(join("_", compact([var.namespace, "svc", var.name, uuid()])), 0, 63)

  dynamic "labels" {
    for_each = var.namespace == null ? [] : [1]
    content {
      label = "com.docker.stack.namespace"
      value = var.namespace
    }
  }
  dynamic "labels" {
    for_each = local.all_labels
    content {
      label = labels.key
      value = labels.value
    }
  }

  dynamic "auth" {
    for_each = nonsensitive(var.auth) == null ? [] : [1]
    content {
      server_address = var.auth.server_address
      username       = var.auth.username
      password       = var.auth.password
    }

  }

  task_spec {
    container_spec {
      image    = "${var.image}:${var.image_tag}"
      command  = var.command
      args     = var.args
      hostname = substr(var.name, 0, 63)
      env      = var.env

      dynamic "labels" {
        for_each = var.namespace == null ? [] : [1]

        content {
          label = "com.docker.stack.namespace"
          value = var.namespace
        }
      }

      dynamic "configs" {
        for_each = local.config_map

        content {
          config_id   = docker_config.this[configs.key].id
          config_name = coalesce(configs.value.config_name, docker_config.this[configs.key].name, null)
          file_name   = configs.value.file_name
          file_uid    = configs.value.file_uid
          file_gid    = configs.value.file_gid
          file_mode   = configs.value.file_mode
        }
      }

      dynamic "secrets" {
        for_each = merge(local.secret_map, local.preexisting_secrets_map)
        content {
          secret_id   = coalesce(lookup(secrets.value, "secret_id", null), docker_secret.this[secrets.key].id)
          secret_name = coalesce(secrets.value.secret_name, docker_secret.this[secrets.key].name)
          file_name   = secrets.value.file_name
          file_uid    = secrets.value.file_uid
          file_gid    = secrets.value.file_gid
          file_mode   = secrets.value.file_mode
        }
      }

      dynamic "mounts" {
        for_each = local.all_mounts
        content {
          target = mounts.value.target
          type   = mounts.value.type
          # bind_options {
          #   propagation = try(mounts.value.bind_options.propagation, null)
          # }
          read_only = mounts.value.read_only
          source    = mounts.value.source
          dynamic "tmpfs_options" {
            for_each = try(compact(mounts.value.tmpfs_options), null) == null ? [] : [1]
            content {
              mode       = try(mounts.value.tmpfs_options.mode, null)
              size_bytes = try(mounts.value.tmpfs_options.size_bytes, null)
            }
          }
          dynamic "volume_options" {
            for_each = try(compact(mounts.value.volume_options), null) == null ? [] : [1]
            content {
              driver_name    = try(mounts.value.volume_options.driver_name, null)
              driver_options = try(mounts.value.volume_options.driver_options, null)
              dynamic "labels" {
                for_each = toset(try(mounts.value.volume_options.labels != null ? mounts.value.volume_options.labels : [], []))
                content {
                  label = each.key
                  value = each.value
                }
              }
              no_copy = try(mounts.value.volume_options.no_copy, null)
            }
          }
        }
      }

      stop_signal       = "SIGTERM"
      stop_grace_period = "10s"

      dynamic "healthcheck" {
        for_each = var.healthcheck == null ? [] : [1]
        content {
          test         = var.healthcheck.test
          interval     = var.healthcheck.internal
          timeout      = var.healthcheck.timeout
          retries      = var.healthcheck.retries
          start_period = var.healthcheck.start_period
        }
      }

    } # end: container_spec

    dynamic "networks_advanced" {
      for_each = var.networks

      content {
        name    = networks_advanced.value
        aliases = local.all_network_aliases
      }
    }

    dynamic "resources" {
      for_each = var.limit == null || var.reservation == null ? [] : [1]
      content {
        dynamic "limits" {
          for_each = var.limit == null ? [] : [var.limit]
          content {
            nano_cpus    = limits.value.cores == null ? null : limits.value.cores * 1e9
            memory_bytes = limits.value.memory == null ? null : limits.value.memory * 1e6
          }
        }

        dynamic "reservation" {
          for_each = var.reservation == null ? [] : [var.reservation]
          content {
            nano_cpus    = reservation.value.cores == null ? null : reservation.value.cores * 1e9
            memory_bytes = reservation.value.memory == null ? null : reservation.value.memory * 1e6
          }
        }
      }
    }

    dynamic "placement" {
      for_each = try(compact(var.constraints), null) == null ? [] : [1]
      content {
        constraints = var.constraints
      }
    }

    restart_policy {
      condition    = var.restart_policy.condition
      delay        = var.restart_policy.delay
      window       = var.restart_policy.window
      max_attempts = var.restart_policy.max_attempts
    }
  }

  mode {
    global = var.mode.global ? true : null
    dynamic "replicated" {
      for_each = var.mode.global ? [] : [1]
      content {
        replicas = try(var.mode.global ? null : var.mode.replicated.replicas, null)
      }
    }
  }

  dynamic "endpoint_spec" {
    for_each = length(var.ports) == 0 ? [] : [1]
    content {
      dynamic "ports" {
        for_each = var.ports
        content {
          target_port    = ports.value.target_port
          name           = ports.value.name
          protocol       = ports.value.protocol
          published_port = coalesce(ports.value.published_port, ports.value.target_port)
          publish_mode   = ports.value.publish_mode
        }
      }
    }
  }

  update_config {
    delay             = "30s"
    parallelism       = 1
    failure_action    = "pause"
    max_failure_ratio = "0.2"
    order             = length(var.ports) > 0 ? "stop-first" : "start-first"
  }

  rollback_config {
    delay          = "30s"
    parallelism    = 1
    failure_action = "pause"
    order          = length(var.ports) > 0 ? "stop-first" : "start-first"
  }

  lifecycle {
    ignore_changes        = [name]
    create_before_destroy = false
  }
  depends_on = [docker_config.this, docker_secret.this]
}
