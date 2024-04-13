<p align="center">
  <img src="docs/assets/terraswarm.png" alt="Terraswarm" width="200px"/>
  <br>
  <i>terraswarm provides advanced Terraform modules<br/>for deploying Docker resources in a Docker Swarm cluster.</i>
  <br>
</p>

<p align="center">
  <a href="CONTRIBUTING.md">Contributing Guidelines</a>
  ·
  <a href="CODE_OF_CONDUCT.md">Code of Conduct</a>
  ·
  <a href="https://github.com/ehwplus/terraswarm/issues">Submit an Issue</a>
  <br/>
  <br/>
</p>

# Overview

Terraswarm is an open-source project aimed at simplifying the deployment of Docker resources using Terraform. Whether you're managing a single-node setup or a large-scale Swarm, Terraswarm equips you with the modules you need to get your infrastructure up and running quickly and efficiently with a high grade of consistency across your resources.
This repository makes use of the [docker terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest) by [kreuzwerker](https://registry.terraform.io/namespaces/kreuzwerker).

<!-- The modules are designed to spawn swarm resources. -->

## Features

- **Consistent Quality**: Ensure a uniform quality standard across all deployments with our Docker resource modules.

- **Stateful Infrastructure Management**: Leverage Terraform's planned and stateful management to eliminate manual infrastructure changes.

- **Integrated Deployment**: Co-locate your Docker resource creation and service provisioning within your repository for streamlined operations.

## Getting started

We use [asdf](https://github.com/asdf-vm/asdf) for version locking. See [.tool-versions](./.tool-versions) for the tools that are used within this repository.

Make sure to have `asdf` installed on your system.

### Install `asdf` tools and populate shims

Run

    asdf install

in your terminal and add prepend the binaries to your path

    export PATH="$HOME/.asdf/shims":"$PATH"

### Setup pre-commit

Run `asdf exec pre-commit install` to install the pre-commit or `asdf exec pre-commit run -a` to run the pre-commit hook manually.

---

For more information on Docker Swarm and Terraform, visit their respective official documentation:

- [Docker Swarm](https://docs.docker.com/engine/swarm/)
- [Terraform](https://www.terraform.io/docs/)


## Contributing

Please feel free to contribute your own modules. Modules shall be based on top of the [base_docker_service](./modules/base_docker_service/) and [base_docker_volume](./modules/base_docker_volume/).

We :heart: contributions! If you'd like to help improve `Terraswarm`, please open up a PR.
