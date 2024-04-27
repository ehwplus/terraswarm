locals {
  name      = coalesce(var.name, "zitadel")
  namespace = coalesce(var.namespace, "authN")
  image     = coalesce(var.custom_image, "ghcr.io/zitadel/zitadel")
  image_tag = coalesce(var.image_tag, "stable")

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/grafana/tempo/blob/main/cmd/tempo/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command = compact([
    "start-from-init",
    var.zitadel_default_config == "" ? "" : "--config", local.this_default_config_file_name,
    var.zitadel_step_config == "" ? "" : "--config", local.this_step_config_file_name,
    "--masterkey", resource.random_password.masterkey.result,
    "--tlsMode", "disabled"
  ])

  this_default_config_file_name = "/default.yaml"

  this_step_config_file_name = "/step.yaml"

  configs = toset(concat(
    [
      var.zitadel_default_config == "" ? null : {
        config_data = var.zitadel_default_config
        file_name   = local.this_default_config_file_name
        file_mode   = 0400
      },
      var.zitadel_step_config == "" ? null : {
        config_data = var.zitadel_step_config
        file_name   = local.this_step_config_file_name
        file_mode   = 0400
      }
    ],
    tolist(var.configs)
  ))

  # zitadel_secrets = [
  #   for _, secret in module.postgres_docker_service.postgresql_secret :
  #   {
  #     secret_id = secret.id
  #   }
  # ]
  # secrets = length(var.secrets) == 0 ? local.zitadel_secrets : concat(local.zitadel_secrets, tolist(var.secrets))

  networks = toset(concat(tolist(var.networks), [docker_network.this.name]))

  zitadel_port = var.zitadel_service_port # TODO: potentially causes issues when Port is changed in config
  zitadel_ports = concat([
    {
      name           = "zitadel"
      target_port    = local.zitadel_port
      protocol       = "tcp"
      published_port = local.zitadel_port
      publish_mode   = "ingress"
    }
  ], var.ports)

  database_name = join("_", compact(["postgres", var.name]))
  database_port = 5432 # TODO potentially paramterize this input if it leaves the module-internal network
}

resource "random_password" "masterkey" {
  length           = 64
  special          = true
  override_special = "#!&+{}<>"
}

module "postgres_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/postgresql?ref=main"

  name         = local.database_name
  namespace    = local.namespace
  service_port = local.database_port
  networks     = [docker_network.this.name]

  postgres_database = var.name
  constraints       = var.constraints
  limit             = var.limit
  reservation       = var.reservation

  depends_on = [docker_network.this]
}

module "zitadel_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name        = local.name
  namespace   = local.namespace
  image       = local.image
  image_tag   = local.image_tag
  command     = local.command
  networks    = local.networks
  ports       = local.zitadel_ports
  configs     = local.configs
  secrets     = var.secrets # local.secrets
  args        = var.args
  auth        = var.auth # container registry auth for private zitadel images
  constraints = var.constraints
  env = merge(var.env, {
    # FIXME https://github.com/zitadel/zitadel/issues/6860
    ZITADEL_DATABASE_POSTGRES_HOST          = module.postgres_docker_service.host
    ZITADEL_DATABASE_POSTGRES_PORT          = module.postgres_docker_service.port
    ZITADEL_DATABASE_POSTGRES_DATABASE      = module.postgres_docker_service.database
    ZITADEL_DATABASE_POSTGRES_USER_USERNAME = nonsensitive(module.postgres_docker_service.user)
    ZITADEL_DATABASE_POSTGRES_USER_PASSWORD = nonsensitive(module.postgres_docker_service.password)
  })
  healthcheck     = var.healthcheck
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  mounts          = var.mounts
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map

  depends_on = [docker_network.this, random_password.masterkey, module.postgres_docker_service]
}
