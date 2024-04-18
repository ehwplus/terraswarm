locals {
  name      = coalesce(var.name, "loki")
  namespace = coalesce(var.namespace, "logs")
  image     = coalesce(var.custom_image, "grafana/loki")
  image_tag = coalesce(var.image_tag, "2.9.2")

  # FIXME loki default http port; conflicts with config changes
  loki_internal_port    = 3100
  this_config_file_name = "/etc/loki/loki.yml"
  volume_mount_path     = "/loki"

  configs = var.loki_config == null ? [] : [
    {
      config_data = var.loki_config
      file_name   = local.this_config_file_name
      file_mode   = 0444
    }
  ]

  # healthcheck = coalesce(
  #   var.healthcheck, {
  #     test         = ["wget --no-verbose --tries=1 --spider http://${local.name}:${local.loki_internal_port}/ready || exit 1"]
  #     interval     = "10s"
  #     timeout      = "15s"
  #     retries      = 10
  #     start_period = "40s"
  #   }
  # )
  healthcheck = merge({ test = ["wget --no-verbose --tries=1 --spider http://${local.name}:${local.loki_internal_port}/ready"] }, var.healthcheck)

  mounts = [
    {
      target         = local.volume_mount_path
      source         = module.loki_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = {}
      volume_options = {}
    }
  ]

  ports = [
    {
      name           = "http"
      protocol       = "tcp"
      target_port    = var.loki_service_port
      published_port = local.loki_internal_port
    }
  ]

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/grafana/loki/blob/main/cmd/loki/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command = compact(concat(
    [
      "/usr/bin/loki",
      var.loki_config == null ? "" : "-config.file=${local.this_config_file_name}"
    ],
    var.args
  ))

}

module "loki_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "loki_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  command         = local.command
  configs         = local.configs
  mounts          = local.mounts
  ports           = local.ports
  healthcheck     = local.healthcheck
  auth            = var.auth # container registry auth for private prometheus images
  constraints     = var.constraints
  env             = var.env
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map
  secrets         = var.secrets

  depends_on = [module.loki_docker_volume]
}
