
locals {
  # certificate = {
  #   source = var.certificate.driver == null ? var.certificate.source : null
  #   type   = var.certificate.driver == null ? (var.certificate.source == null ? "volume" : var.certificate.type) : "volume"
  # }

  mounts = [
    {
      target    = "/var/run/docker.sock"
      source    = "/var/run/docker.sock"
      type      = "bind"
      read_only = true
    },
    {
      target    = "/certificates"
      source    = module.docker_volume.this.name
      type      = "volume"
      read_only = false
    }
    # {
    #   target = "/etc/certificates"
    #   source = local.certificate.source
    #   type   = local.certificate.type
    #   volume_options = {
    #     driver_options = var.certificate.driver
    #   }
    # }
  ]

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

  name      = coalesce(var.name, "traefik")
  namespace = coalesce(var.namespace, "gateway")
  image_tag = coalesce(var.image_tag, "v3.0")

  image = "traefik"
}

module "traefik_docker_volume" {
  source    = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"
  name      = local.name
  namespace = local.namespace
}

module "traefik_docker_service" {
  source    = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"
  name      = local.name
  namespace = local.namespace
  image     = local.image
  image_tag = local.image_tag
  mounts    = local.mounts
  ports     = local.ports

  args        = var.args
  networks    = var.networks
  env         = var.env
  constraints = var.constraints
  mode        = var.mode

  limit       = var.limit
  reservation = var.reservation
  labels      = var.labels
  configs     = [{ config_data = var.traefik_config, file_name = "/etc/traefik/traefik.yaml" }]
}
