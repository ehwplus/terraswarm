// https://raw.githubusercontent.com/Infisical/infisical/main/docker-compose.prod.yml
// https://raw.githubusercontent.com/Infisical/infisical/main/.env.example

locals {
  name      = coalesce(var.name, "infiscal")
  namespace = coalesce(var.namespace, "storage")
  image     = coalesce(var.custom_image, "infisical/infisical")
  image_tag = coalesce(var.image_tag, "latest-postgres")

  redis_port                         = var.infiscal_redis_port
  database_port                      = var.infiscal_database_port
  infiscal_database_migration_prefix = "db-migration"

  db_migration_command = compact([
    "npm",
    "run",
    "migration:latest"
  ])

  infiscal_port = var.infiscal_application_port
  infiscal_ports = concat([
    {
      name           = "zitadel"
      target_port    = 8080
      protocol       = "tcp"
      published_port = local.infiscal_port
      publish_mode   = "ingress"
    }
  ], var.ports)

  database_name = join("_", compact(["postgres", var.name]))
  redis_name    = join("_", compact(["redis", var.name]))

  networks = toset(concat([docker_network.this.name], tolist(var.networks)))
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
  source = "github.com/ehwplus/terraswarm//modules/postgresql?ref=postgresql"

  name         = local.database_name
  namespace    = local.namespace
  service_port = local.database_port

  custom_postgresql_password = nonsensitive(resource.random_password.postgresql_password.result)

  postgres_database = var.name
  constraints       = var.constraints
  limit             = var.limit
  reservation       = var.reservation

  networks = [docker_network.this.name]

  depends_on = [docker_network.this]
}

module "redis_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/redis?ref=redis"

  name         = local.redis_name
  namespace    = local.namespace
  service_port = local.redis_port

  constraints = var.constraints
  limit       = var.limit
  reservation = var.reservation

  custom_redis_password = nonsensitive(resource.random_password.redis_password.result)

  networks = [docker_network.this.name]

  depends_on = [docker_network.this]
}

module "infiscal_db_migration_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name        = "${local.infiscal_database_migration_prefix}-${local.name}"
  namespace   = local.namespace
  image       = local.image
  image_tag   = local.image_tag
  args        = var.args
  constraints = var.constraints
  command     = local.db_migration_command
  env = merge({
    DB_CONNECTION_URI = "postgres://${nonsensitive(module.postgres_docker_service.user)}:${nonsensitive(module.postgres_docker_service.password)}@${module.postgres_docker_service.host}:${module.postgres_docker_service.port}/${var.name}"
  }, var.env)
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  network_aliases = var.network_aliases
  reservation     = var.reservation
  secret_map      = var.secret_map
  restart_policy  = { condition = "on-failure" }

  networks = [docker_network.this.name]

  depends_on = [docker_network.this, module.postgres_docker_service]
}

module "infiscal_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name        = local.name
  namespace   = local.namespace
  image       = local.image
  image_tag   = local.image_tag
  networks    = local.networks
  ports       = local.infiscal_ports
  secrets     = var.secrets
  args        = var.args
  constraints = var.constraints
  env = merge({
    ENCRYPTION_KEY    = nonsensitive(resource.random_password.encryption_key.result)
    AUTH_SECRET       = nonsensitive(resource.random_bytes.jwt_auth_secret.base64)
    DB_CONNECTION_URI = "postgres://${nonsensitive(module.postgres_docker_service.user)}:${nonsensitive(module.postgres_docker_service.password)}@${module.postgres_docker_service.host}:${module.postgres_docker_service.port}/${var.name}"
    REDIS_URL         = "redis://:${nonsensitive(module.redis_docker_service.password)}@${module.redis_docker_service.host}:${module.redis_docker_service.port}",
    NODE_ENV          = "production"
    SITE_URL          = var.infiscal_site_url
  }, var.env)
  healthcheck     = var.healthcheck
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  mounts          = var.mounts
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map

  depends_on = [module.postgres_docker_service, module.redis_docker_service.password, module.infiscal_db_migration_docker_service]
}