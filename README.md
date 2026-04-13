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

Node is managed by [Volta](https://volta.sh/)
Use `volta install node@lts` to set your default Node version and `volta pin node@x.y.z` per project when needed.

## Kubectl

Kubectl is automatically installed using brew and is configuered to read all kubeconfigs in `~/.kube/configs/`
