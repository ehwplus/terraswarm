locals {
  name      = coalesce(var.name, "postgres")
  namespace = coalesce(var.namespace, "database")
  image     = coalesce(var.custom_image, "postgres") # https://hub.docker.com/_/postgres
  image_tag = coalesce(var.image_tag, "16.2-alpine")

  database_password = var.custom_postgresql_password == null ? nonsensitive(random_password.postgres_password.result) : var.custom_postgresql_password

  this_postgresql_config_file = "/etc/postgresql/postgresql.conf"

  env = merge(
    {
      "POSTGRES_USER_FILE"     = "/run/secrets/POSTGRES_USER"
      "POSTGRES_PASSWORD_FILE" = "/run/secrets/POSTGRES_PASSWORD"
      "POSTGRES_DB"            = var.postgres_database
      "PGUSER_FILE"            = "/run/secrets/POSTGRES_USER"
      "PGDATA"                 = "/var/lib/postgresql/data/pdata"
    },
    var.env
  )

  healthcheck = coalesce(
    var.healthcheck, {
      test         = ["CMD-SHELL", "pg_isready", "-d", var.postgres_database, "-U", nonsensitive(random_string.postgres_user.result)]
      interval     = "2s"
      timeout      = "5s"
      start_period = "5s"
      retries      = 5
    }
  )

  mounts = setunion(
    [{
      target         = "/var/lib/postgresql/data"
      source         = module.postgresql_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    }],
    var.mounts
  )

  ports = [
    {
      name           = "postgresql"
      target_port    = 5432, # TODO: causes issues when pgport is changed in var.postgresql_config
      protocol       = "tcp"
      published_port = var.service_port
      publish_mode   = "ingress"
    }
  ]

  secrets = setunion(
    [
      {
        file_name   = "POSTGRES_USER"
        secret_data = nonsensitive(resource.random_string.postgres_user.result)
      },
      {
        file_name   = "POSTGRES_PASSWORD"
        secret_data = local.database_password
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

resource "random_string" "postgres_user" {
  length    = 24
  min_upper = 16
  special   = false
}

resource "random_password" "postgres_password" {
  length           = 64
  special          = true
  override_special = "#!&+{}<>"
}

module "postgresql_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "postgresql_docker_service" {
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
  auth            = var.auth # container registry auth for private traefik images
  command         = var.postgresql_config == null ? null : ["postgres", "-c", "'config_file=${local.this_postgresql_config_file}'"]
  configs         = var.postgresql_config == null ? [] : [{ config_data = var.postgresql_config, file_name = local.this_postgresql_config_file, file_mode = 0400 }]
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy

  depends_on = [random_string.postgres_user, random_password.postgres_password, module.postgresql_docker_volume]
}
