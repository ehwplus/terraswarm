locals {
  name      = coalesce(var.name, "minio")
  namespace = coalesce(var.namespace, "storage")
  image     = coalesce(var.custom_image, "minio/minio") # https://hub.docker.com/r/minio/minio
  image_tag = coalesce(var.image_tag, "RELEASE.2023-12-06T09-09-22Z-cpuv1")

  minio_credential_secrets = tolist([
    {
      file_name   = "MINIO_ACCESS_KEY"
      secret_data = nonsensitive(resource.random_string.minio_access_key.result)
      }, {
      file_name   = "MINIO_SECRET_KEY"
      secret_data = nonsensitive(resource.random_password.minio_secret_key.result)
    }
  ])
  secrets = length(var.secrets) == 0 ? local.minio_credential_secrets : concat(local.minio_credential_secrets, tolist(var.secrets))

  secret_map = {
    for secret in local.secrets :
    secret.file_name => {
      file_name : secret.file_name,
      secret_data : secret.secret_data,
    }
  }

  minio_api_port = 9000
  minio_ui_port  = 9001
  minio_data_dir = "/data"

  minio_ports = [
    {
      name        = "api"
      target_port = local.minio_api_port
      protocol    = "tcp"
    },
    {
      name        = "ui-console"
      target_port = local.minio_ui_port,
      protocol    = "tcp"
    }
  ]

  minio_env = merge(
    {
      "MINIO_ROOT_USER_FILE"     = "/run/secrets/MINIO_ACCESS_KEY"
      "MINIO_ROOT_PASSWORD_FILE" = "/run/secrets/MINIO_SECRET_KEY"
    },
    var.env
  )

  minio_data_mount = [
    {
      target         = local.minio_data_dir
      source         = module.minio_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = {}
      volume_options = {}
    }
  ]
  minio_mounts = length(var.mounts) == 0 ? local.minio_data_mount : concat(tolist(local.minio_data_mount), tolist(var.mounts))

  minio_healthcheck = coalesce(var.healthcheck,
    {
      test         = ["CMD", "curl", "-f", "http://${local.name}:${local.minio_api_port}/minio/health/live"]
      interval     = "30s"
      timeout      = "30s"
      retries      = 3
      start_period = "5s"
    }
  )

  init_healthcheck = {
    test     = ["CMD", "mc", "ls", "minioInst${local.minio_data_dir}"]
    interval = "30s"
    timeout  = "10s"
    retries  = 3
  }
}

resource "random_string" "minio_access_key" {
  length    = 24
  min_upper = 16
  special   = false
}
resource "random_password" "minio_secret_key" {
  length           = 64
  special          = true
  override_special = "!#$%&*()-_=+:?"
}

# FIXME secrets for init task outside of command
module "create_bucket" {
  source    = "../base_docker_service"
  name      = "create_bucket"
  namespace = local.namespace
  image     = "minio/mc"
  image_tag = "latest"
  networks  = var.networks
  command = [
    "/bin/sh", "-c",
    "until(/usr/bin/mc config host add minioInst http://${local.name}:${local.minio_api_port} '${resource.random_string.minio_access_key.result}' '${resource.random_password.minio_secret_key.result}') do echo '...waiting...' && sleep 1; done; /usr/bin/mc rm -r --force minioInst${local.minio_data_dir}; /usr/bin/mc mb minioInst${local.minio_data_dir} && /usr/bin/mc policy download minioInst${local.minio_data_dir} && exit 0;"
  ]
  healthcheck    = local.init_healthcheck
  restart_policy = { condition = "on-failure" }

  depends_on = [random_string.minio_access_key, random_password.minio_secret_key, module.minio_docker_service]
}

module "minio_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "minio_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  env             = local.minio_env
  ports           = local.minio_ports
  mounts          = local.minio_mounts
  healthcheck     = local.minio_healthcheck
  secret_map      = local.secret_map
  args            = concat(["server", "--address", ":${local.minio_api_port}", "--console-address", ":${local.minio_ui_port}", local.minio_data_dir], var.args)
  auth            = var.auth # container registry auth for private minio images
  constraints     = var.constraints
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy

  depends_on = [random_string.minio_access_key, random_password.minio_secret_key, module.minio_docker_volume]
}
