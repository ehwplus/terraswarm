locals {
  name      = coalesce(var.name, "pgadmin")
  namespace = coalesce(var.namespace, "admin")
  image     = coalesce(var.custom_image, "dpage/pgadmin4") # https://hub.docker.com/r/dpage/pgadmin4
  image_tag = coalesce(var.image_tag, "8.3")

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
    #   target         = "/var/lib/postgresql/data"
    #   source         = module.postgresql_docker_volume.this.name
    #   type           = "volume"
    #   read_only      = false
    #   tmpfs_options  = null
    #   volume_options = var.postgres_volume_options
    # }],
    var.mounts
  )

  ports = [
    {
      name           = "pgadmin"
      target_port    = 80,
      protocol       = "tcp"
      published_port = var.service_port
      publish_mode   = "ingress"
    }
  ]

  secrets = setunion(
    [
      # {
      #   file_name   = "POSTGRES_USER"
      #   secret_data = nonsensitive(resource.random_string.postgres_user.result)
      # },
      # {
      #   file_name   = "POSTGRES_PASSWORD"
      #   secret_data = local.database_password
      # }
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

# module "postgresql_docker_volume" {
#   source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

#   name           = local.name
#   namespace      = local.namespace
#   driver         = var.postgres_volume_options.driver_name
#   driver_options = var.postgres_volume_options.driver_options
# }

module "pgadmin_docker_service" {
  # trunk-ignore(tflint/terraform_module_pinned_source)
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name        = local.name
  namespace   = local.namespace
  image       = local.image
  image_tag   = local.image_tag
  mounts      = local.mounts
  env         = local.env
  secret_map  = local.secret_map
  ports       = local.ports
  healthcheck = local.healthcheck
  args        = var.args
  auth        = var.auth # container registry auth for private traefik images
  # configs         = var.postgresql_config == null ? [] : [{ config_data = var.postgresql_config, file_name = local.this_postgresql_config_file, file_mode = 0400 }]
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
}
