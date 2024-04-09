locals {
  name      = coalesce(var.name, "tempo")
  namespace = coalesce(var.namespace, "tracing")
  image     = coalesce(var.custom_image, "grafana/tempo")
  image_tag = coalesce(var.image_tag, "2.3.1")

  configs = var.tempo_config == null ? [] : [
    { config_data = var.tempo_config
      file_name   = local.this_config_file_name
      file_mode   = 0400
    }
  ]

  ports = [
    {
      name           = "http"
      protocol       = "tcp"
      target_port    = var.tempo_service_port
      published_port = 3200 # FIXME tempo default http port; conflicts with config changes
    }
  ]

  # From the docs (https://registry.terraform.io/providers/kreuzwerker/docker/latest/docs/resources/service#command):
  #   The command/entrypoint to be run in the image. According to the docker cli the override of the entrypoint is also
  #   passed to the command property and there is no entrypoint attribute in the ContainerSpec of the service.
  #
  # So in accordance with https://github.com/grafana/tempo/blob/main/cmd/tempo/Dockerfile
  # we have to include the entrypoint from the Dockerfile in the service command array.
  command = flatten(["/tempo", var.tempo_config == null ? null : "-config.file=${local.this_config_file_name}"])

  this_config_file_name = "/etc/tempo.yml"
}

module "tempo_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name      = local.name
  namespace = local.namespace
  image     = local.image
  image_tag = local.image_tag
  command   = local.command
  configs   = local.configs
  ports     = local.ports

  args            = var.args
  auth            = var.auth # container registry auth for private traefik images
  constraints     = var.constraints
  env             = var.env
  healthcheck     = var.healthcheck
  labels          = var.labels
  limit           = var.limit
  mode            = var.mode
  networks        = var.networks
  network_aliases = var.network_aliases
  reservation     = var.reservation
  restart_policy  = var.restart_policy
  secret_map      = var.secret_map
  secrets         = var.secrets
}
