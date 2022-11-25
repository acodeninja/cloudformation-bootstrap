# Cloudformation Bootstrap

## Quick Start

### Requirements

* Make
* Bash shell
* Docker
* Git

Other requirements will be automatically installed as they are required.

* AWS CLI
* CFN Lint
* [AWS-Vault](https://github.com/99designs/aws-vault)

#### MacOS Specific

* [brew package manager](https://brew.sh/)

#### Windows Specific

* [chocolatey package manager](https://chocolatey.org/install)

### `Makefile`

```text
    ____             _                         ____        __           
   / __ )__  _______(_)___  ___  __________   / __ \____ _/ /____  _____
  / __  / / / / ___/ / __ \/ _ \/ ___/ ___/  / /_/ / __ `/ __/ _ \/ ___/
 / /_/ / /_/ (__  ) / / / /  __(__  |__  )  / _, _/ /_/ / /_/  __(__  ) 
/_____/\__,_/____/_/_/ /_/\___/____/____/  /_/ |_|\__,_/\__/\___/____/  

Usage: make <action> PROFILE=<aws-vault profile>

clean              Return the local project back to it's initial state
deploy-dev         Deploy to a locally running development environment
help               Display this help message
install            Install deployment and development dependencies
lint               Check cloudformation templates for syntax and config errors
localstack-start   Start the localstack service for testing aws deployments locally
localstack-stop    Stop the localstack service if it is running.
```
