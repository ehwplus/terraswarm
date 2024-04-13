locals {
  name      = coalesce(var.name, "prometheus")
  namespace = coalesce(var.namespace, "metrics")
  image     = coalesce(var.custom_image, "prom/prometheus")
  image_tag = coalesce(var.image_tag, "v2.48.1")

  this_config_file_name    = "/etc/prometheus/prometheus.yml"
  volume_mount_path        = "/prometheus"
  prometheus_internal_port = 9090 # can be changed in the config and can lead to issues

  configs = var.prometheus_config == null ? [] : [
    {
      config_data = var.prometheus_config
      file_name   = local.this_config_file_name
      file_mode   = 0400
    }
  ]

  healthcheck = coalesce(
    var.healthcheck, {
      test         = ["CMD", "wget", "http://localhost:${local.prometheus_internal_port}/-/healthy"]
      interval     = "10s"
      timeout      = "15s"
      retries      = 10
      start_period = "40s"
    }
  )

  mounts = [
    {
      target         = local.volume_mount_path
      source         = module.prometheus_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    }
  ]

  ports = [
    {
      target_port    = var.prometheus_service_port,
      name           = "api",
      protocol       = "tcp",
      publish_mode   = "ingress"
      published_port = local.prometheus_internal_port
    }
  ]

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/prometheus/prometheus/blob/main/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command = compact(flatten([
    "/bin/prometheus",
    var.prometheus_config == null ? null : "--config.file", local.this_config_file_name,
    "--storage.tsdb.path", local.volume_mount_path,
    "--web.console.libraries=/usr/share/prometheus/console_libraries",
    "--web.console.templates=/usr/share/prometheus/consoles",
    var.args
  ]))
}

module "prometheus_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "prometheus_service" {
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

  depends_on = [module.prometheus_docker_volume]
}
