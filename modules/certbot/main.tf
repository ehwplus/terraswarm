
locals {
  mounts = [
    {
      target    = "/etc/letsencrypt"
      source    = module.certbot_docker_volume.this.name
      type      = "volume"
      read_only = false
    },
    {
      target    = "/var/lib/letsencrypt"
      source    = module.certbot_docker_volume.this.name
      type      = "volume"
      read_only = false
    }
  ]

  ports = flatten(concat(
    var.standalone ? [
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
    ] : [],
    var.ports
  ))

  name      = coalesce(var.name, "certbot")
  namespace = coalesce(var.namespace, "gateway")
  image_tag = coalesce(var.image_tag, "v2.10.0")

  image = "certbot/certbot"
}

module "certbot_docker_volume" {
  source    = "github.com/ehwplus/terraswarm//modules/base_docker_volume?ref=main"
  name      = local.name
  namespace = local.namespace
}

module "certbot_docker_service" {
  source    = "github.com/ehwplus/terraswarm//modules/base_docker_service?ref=main"
  name      = local.name
  namespace = local.namespace
  image     = local.image
  image_tag = local.image_tag
  mounts    = local.mounts
  ports     = local.ports

  args = coalesce(var.args, ["certonly"])

  networks    = var.networks
  env         = var.env
  constraints = var.constraints
  mode        = var.mode
  limit       = var.limit
  reservation = var.reservation
  labels      = var.labels
}
