locals {
  name      = coalesce(var.name, "pgadmin")
  namespace = coalesce(var.namespace, "admin")
  image     = coalesce(var.custom_image, "dpage/pgadmin4") # https://hub.docker.com/r/dpage/pgadmin4
  image_tag = coalesce(var.image_tag, "8.13")

  env = merge(
    {
      "PGADMIN_DEFAULT_EMAIL"                = var.pgadmin_default_email
      "PGADMIN_DEFAULT_PASSWORD"             = nonsensitive(var.pgadmin_default_password)
      "PGADMIN_CONFIG_SERVER_MODE"           = "True"
      "PGADMIN_CONFIG_CONSOLE_LOG_LEVEL"     = "50"
      "PGADMIN_CONFIG_FILE_LOG_LEVEL"        = "20"
      "PGADMIN_CONFIG_MAX_SESSION_IDLE_TIME" = "3600"
    },
    var.env
  )

  healthcheck = coalesce(
    var.healthcheck, {
      test         = ["CMD", "wget", "-O", "-", "http://localhost:80/misc/ping"]
      interval     = "10s"
      timeout      = "10s"
      start_period = "160s"
      retries      = 3
    }
  )

  mounts = setunion(
    # [{
    #   target         = "/var/lib/pgadmin"
    #   source         = module.postgresql_docker_volume.this.name
    #   type           = "volume"
    #   read_only      = false
    #   tmpfs_options  = null
    #   volume_options = var.postgres_volume_options
    # }],
    var.mounts
  )

  configs = toset([
    for config in [
      {
        config_data = var.pgadmin_config_local
        file_name   = "/pgadmin4/config_local.py"
        file_mode   = 0444
      },
      {
        config_data = var.pgadmin_config_servers
        file_name   = "/pgadmin4/servers.json"
        file_mode   = 0444
      },
      {
        config_data = var.pgadmin_config_tls_cert
        file_name   = "/pgadmin4/server.cert"
        file_mode   = 0444
      },
      {
        config_data = var.pgadmin_config_tls_key
        file_name   = "/pgadmin4/server.key"
        file_mode   = 0444
      }
    ] : config if config.config_data != null
  ])

  ports = var.service_port == null ? [] : [
    {
      name           = "pgadmin"
      target_port    = 80,
      protocol       = "tcp"
      published_port = var.service_port
      publish_mode   = "ingress"
    }
  ]

  secrets = setunion(var.secrets)

  secret_map = merge(var.secret_map, {
    for secret in local.secrets :
    secret.file_name => {
      file_name   = secret.file_name,
      secret_data = secret.secret_data,
    }
  })
}

module "pgadmin_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?depth=1&ref=base_docker_service%2Fv0.1.0"

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
  auth            = var.auth
  configs         = local.configs
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
}
