# Terraswarm

This repository contains a collection of terraform modules which use the [docker terraform provider](https://registry.terraform.io/providers/kreuzwerker/docker/latest) by [kreuzwerker](https://registry.terraform.io/namespaces/kreuzwerker).

The modules are designed to spawn swarm resources.

We use [asdf](https://github.com/asdf-vm/asdf) for version locking. See [.tool-versions](./.tool-versions) for the tools that are used within this repository.

Make sure to have `asdf` installed on your system.

## Install `asdf` tools and populate shims

Run

    asdf install

in your terminal and add prepend the binaries to your path

    export PATH="$HOME/.asdf/shims":"$PATH"

## Setup pre-commit

Run `asdf exec pre-commit install` to install the pre-commit or `asdf exec pre-commit run -a` to run the pre-commit hook manually.

## Contribution

Please feel free to contribute your own modules. Modules shall be based on top of the [base_docker_service](./modules/base_docker_service/) and [base_docker_volume](./modules/base_docker_volume/).
