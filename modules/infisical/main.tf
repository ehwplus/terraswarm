// https://raw.githubusercontent.com/Infisical/infisical/main/docker-compose.prod.yml
// https://raw.githubusercontent.com/Infisical/infisical/main/.env.example

locals {
  name                                = coalesce(var.name, "infisical")
  namespace                           = coalesce(var.namespace, "storage")
  image                               = coalesce(var.custom_image, "infisical/infisical")
  image_tag                           = coalesce(var.image_tag, "latest-postgres")
  infisical_database_migration_prefix = "postgres-migration"

  db_migration_command = compact([
    "npm",
    "run",
    "migration:latest"
  ])

  infisical_ports = concat([
    {
      name           = "infisical"
      target_port    = var.infisical_internal_port
      protocol       = "tcp"
      published_port = var.infisical_application_port
      publish_mode   = "ingress"
    }
  ], var.ports)

  database_name = join("_", compact(["postgres", var.name]))
  redis_name    = join("_", compact(["redis", var.name]))

}

resource "random_bytes" "jwt_auth_secret" {
  length = 64
}

resource "random_password" "encryption_key" {
  length           = 32
  special          = false
  override_special = "#!&+{}<>"
}

resource "random_password" "redis_password" {
  length  = 32
  special = false
}

resource "random_password" "postgresql_password" {
  length  = 32
  special = false
}

module "postgres_docker_service" {
  # trunk-ignore(tflint/terraform_module_pinned_source)
  source = "github.com/ehwplus/terraswarm//modules/postgresql?ref=main"

  name                       = local.database_name
  namespace                  = local.namespace
  networks                   = [docker_network.this.id]
  custom_postgresql_password = nonsensitive(resource.random_password.postgresql_password.result)
  postgres_database          = var.name
  custom_image               = var.postgresql.custom_image
  image_tag                  = var.postgresql.image_tag
  auth                       = var.postgresql.auth
  mounts                     = var.postgresql.mounts
  env                        = var.postgresql.env
  healthcheck                = var.postgresql.healthcheck
  args                       = var.postgresql.args
  labels                     = var.postgresql.labels
  constraints                = var.postgresql.constraints
  limit                      = var.postgresql.limit
  reservation                = var.postgresql.reservation
  restart_policy             = var.postgresql.restart_policy
  postgres_volume_options    = var.postgresql.postgres_volume_options
  service_port               = var.postgresql.postgres_service_port
  depends_on                 = [docker_network.this]
}

module "redis_docker_service" {
  # trunk-ignore(tflint/terraform_module_pinned_source)
  source = "github.com/ehwplus/terraswarm//modules/redis?ref=main"

  name                  = local.redis_name
  namespace             = local.namespace
  networks              = [docker_network.this.id]
  redis_custom_password = nonsensitive(resource.random_password.redis_password.result)
  custom_image          = var.redis.custom_image
  image_tag             = var.redis.image_tag
  args                  = var.redis.args
  env                   = var.redis.env
  secrets               = var.redis.secrets
  secret_map            = var.redis.secret_map
  mounts                = var.redis.mounts
  labels                = var.redis.labels
  constraints           = var.redis.constraints
  limit                 = var.redis.limit
  reservation           = var.redis.reservation
  restart_policy        = var.redis.restart_policy
  mode                  = var.redis.mode
  healthcheck           = var.redis.healthcheck
  redis_volume_options  = var.redis.redis_volume_options
  redis_service_port    = var.redis.redis_service_port

  depends_on = [docker_network.this]
}

module "infisical_db_migration_docker_service" {
  # trunk-ignore(tflint/terraform_module_pinned_source)
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name           = "${local.infisical_database_migration_prefix}-${local.name}"
  namespace      = local.namespace
  image          = local.image
  image_tag      = local.image_tag
  command        = local.db_migration_command
  restart_policy = { condition = "on-failure" }
  networks       = [docker_network.this.id]

  env = merge({
    DB_CONNECTION_URI = "postgres://${nonsensitive(module.postgres_docker_service.user)}:${nonsensitive(module.postgres_docker_service.password)}@${module.postgres_docker_service.host}:${module.postgres_docker_service.port}/${var.name}"
  }, var.env)

  depends_on = [docker_network.this, module.postgres_docker_service]
}

module "infisical_docker_service" {
  # trunk-ignore(tflint/terraform_module_pinned_source)
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  networks        = toset(concat([docker_network.this.id], tolist(var.networks)))
  ports           = local.infisical_ports
  secrets         = var.secrets
  args            = var.args
  constraints     = var.constraints
  healthcheck     = var.healthcheck
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  mounts          = var.mounts
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map

  env = merge({
    ENCRYPTION_KEY    = nonsensitive(resource.random_password.encryption_key.result)
    AUTH_SECRET       = nonsensitive(resource.random_bytes.jwt_auth_secret.base64)
    DB_CONNECTION_URI = "postgres://${nonsensitive(module.postgres_docker_service.user)}:${nonsensitive(module.postgres_docker_service.password)}@${module.postgres_docker_service.host}:${module.postgres_docker_service.port}/${var.name}"
    REDIS_URL         = "redis://:${nonsensitive(module.redis_docker_service.password)}@${module.redis_docker_service.host}:${module.redis_docker_service.port}",
    NODE_ENV          = "production"
    SITE_URL          = coalesce(var.infisical_site_url, "http://localhost:${var.infisical_application_port}")
    TELEMETRY_ENABLED = false
    PORT              = var.infisical_internal_port
  }, var.env)

  depends_on = [module.postgres_docker_service, module.redis_docker_service.password, module.infisical_db_migration_docker_service]
}
