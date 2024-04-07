
locals {
  # certificate = {
  #   source = var.certificate.driver == null ? var.certificate.source : null
  #   type   = var.certificate.driver == null ? (var.certificate.source == null ? "volume" : var.certificate.type) : "volume"
  # }

  mounts = toset(concat([
    {
      target         = "/var/run/docker.sock"
      source         = "/var/run/docker.sock"
      type           = "bind"
      read_only      = true
      tmpfs_options  = null
      volume_options = null
    },
    {
      target         = "/etc/certs"
      source         = module.traefik_docker_volume.this.name
      type           = "volume"
      read_only      = false
      tmpfs_options  = null
      volume_options = null
    }
    # {
    #   target = "/etc/certificates"
    #   source = local.certificate.source
    #   type   = local.certificate.type
    #   volume_options = {
    #     driver_options = var.certificate.driver
    #   }
    # }
    ],
    tolist(var.mounts)
  ))

  ports = flatten(concat(
    [
      {
        target_port  = 80,
        name         = "http",
        protocol     = "tcp",
        publish_mode = "ingress"
      },
      {
        target_port  = 443,
        name         = "https",
        protocol     = "tcp",
        publish_mode = "ingress"
      },
    ],
    var.ports
  ))

  healthcheck = merge(var.healthcheck, { test = coalesce(var.healthcheck.test, ["traefik", "healthcheck", "--ping"]) })

  name      = coalesce(var.name, "traefik")
  namespace = coalesce(var.namespace, "gateway")
  image     = coalesce(var.custom_image, "traefik")
  image_tag = coalesce(var.image_tag, "v3.0")
}

module "traefik_docker_volume" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"

  name      = local.name
  namespace = local.namespace
}

module "traefik_docker_service" {
  source = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"

  name            = local.name
  namespace       = local.namespace
  image           = local.image
  image_tag       = local.image_tag
  mounts          = local.mounts
  ports           = local.ports
  healthcheck     = local.healthcheck
  args            = var.args
  auth            = var.auth # container registry auth for private traefik images
  configs         = [{ config_data = var.traefik_config, file_name = "/etc/traefik/traefik.yaml", file_mode = 0740 }]
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
}
