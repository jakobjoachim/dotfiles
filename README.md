# Dotfiles

Heavily influenced by Nick Nisis [dotfiles](https://github.com/nicknisi/dotfiles)

## Installation

download / clone and run `./install.sh`
it will tell you all the options you have.

## Java

I manage Java / Maven using [sdkman](https://sdkman.io/)
To install a temurin jdk run:
`sdk install java x.y.z-tem`

## Nodejs

Node is managed by [fast node manager](https://github.com/Schniz/fnm)
There is no configuration needed. If you change into a dir fnm automatically pulls the correct version

## Kubectl

Kubectl is automatically installed using brew and is configuered to read all kubeconfigs in `~/.kube/configs/`
