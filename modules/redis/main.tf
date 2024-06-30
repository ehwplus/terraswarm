locals {
  name      = coalesce(var.name, "redis")
  namespace = coalesce(var.namespace, "database")
  image     = coalesce(var.custom_image, "bitnami/redis")
  image_tag = coalesce(var.image_tag, "latest")

  redis_password = var.custom_redis_password == null ? nonsensitive(resource.random_password.redis_password.result) : var.custom_redis_password

  env = merge(
    {
      "REDIS_PASSWORD_FILE" = "/run/secrets/REDIS_PASSWORD"
    },
    var.env
  )

  healthcheck = coalesce(
    var.healthcheck, {
      test         = ["CMD", "redis-cli", "--raw", "incr", "ping"]
      interval     = "2s"
      timeout      = "5s"
      start_period = "5s"
      retries      = 5
    }
  )

  mounts = setunion(
    [{
      target         = "/bitnami/redis/data"
      source         = module.redis_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    }],
    var.mounts
  )

  ports = [
    {
      name           = "redis"
      target_port    = 6379,
      protocol       = "tcp"
      published_port = var.service_port
      publish_mode   = "ingress"
    }
  ]

  secrets = setunion(
    [
      {
        file_name   = "REDIS_PASSWORD"
        secret_data = local.redis_password
      }
    ],
    var.secrets
  )

  secret_map = merge(var.secret_map, {
    for secret in local.secrets :
    secret.file_name => {
      file_name   = secret.file_name,
      secret_data = secret.secret_data,
    }
  })
}

resource "random_password" "redis_password" {
  length           = 32
  special          = true
  override_special = "#!&+{}<>"
}

module "redis_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "redis_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  mounts          = local.mounts
  env             = local.env
  secret_map      = local.secret_map
  ports           = local.ports
  healthcheck     = local.healthcheck
  args            = var.args
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy

  depends_on = [random_password.redis_password, module.redis_docker_volume]
}