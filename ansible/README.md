# Ansible

The ansible playbook configures a VM instance to run the Datomic transactor. It
does so by installing podman, generating a Datomic transactor configuration file
with the right PostgreSQL connection details, and running the transactor in a
Docker container.

## Running Ansible

First install the Ansible tooling:

```sh
brew install ansible
```
