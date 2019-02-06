# Ansible training

A basic explanation about concepts and how to create your first Ansible automation.

<!-- mdtocstart -->

## Table of Contents

- [Ansible introduction](#ansible-concepts)
- [Ansible goals](#ansible-goals)
- [Ansible concepts](#ansible-concepts)
 - [Task & modules](#task-&-modules)
 - [Role](#role)
 - [Playbook](#playbook)
 - [Workflow](#workflow)
- [Requirements](#requirements)
- [Getting started](#getting-started)

<!-- mdtocend -->


## Ansible introduction

- Tool created for control and provisioning of software and machines.

- Opensource.

- Purchased by RedHat in October 2015.

- The name `Ansible` has origin from a science fiction novel *Rocannon's world* as a *"Technology with the ability to communicate faster than light"*

## Ansible goals

- Minimal dependencies (python & ssh)

- Consistent (multiples environments)

- Secure (ssh)

- Highly reliable (idempotent)

- Minimal learning required (yml)

## Ansible concepts

### Task & modules

Task is nothing more than a call to an ansible modules.

```yml
- name: Create directories
  file:
    path: /tmp/foo/bar
    owner: root
    state: directory
```

The Modules can control system resources, like services, packages, or files (anything really), or handle executing system commands.

All the modules can be listated with `ansible-doc`

```bash
$ ansible-doc {module-name}
```

Or the web page documentation [docs.ansible.com](https://docs.ansible.com)

### Role

Role is a set of tasks, for some specific objective.

The example bellow install the docker.

```yml
---
- name: Add Docker repository key
  apt_key:
    url: "{{ docker_install_apt_key_url }}"
    state: present

- name: Add Docker repository and update apt cache
  apt_repository:
    repo: "{{ docker_install_apt_repository }}"
    update_cache: yes
    state: present

- name: Install docker package
  apt:
    name: "{{ docker_install_docker_version }}"
    state: present
    update_cache: yes
    cache_valid_time: 3600

- name: Ensure docker service
  systemd:
    name: docker
    enabled: yes
    state: started
```

The community have a repository to create and share your roles, that can be listated with `ansible-galaxy`

```bash
$ ansible-galaxy search {term}
```

Or the web page [galaxy.ansible.com](https://galaxy.ansible.com)


### Playbook

The file where Ansible *"get things done"*. Here you define your hosts, the roles you want run on that hosts, and variables to use on the roles.

```yml
---
- name: Main playbook
  become: yes
  gather_facts: no
  hosts: vm_tester

  roles:
    - { role: docker-install, tags: docker }
    - { role: nginx-unit, tags: nginx-unit }
```

### Workflow

This gif ilustrate a basic workflow

![alt text](https://media.giphy.com/media/9D5gzWJUcrIYGYsxUm/giphy.gif)

The file `ansible.cfg` is where you can set a bunch of parameters to ansible while running

```
[defaults]
host_key_checking = False

[ssh_connection]
scp_if_ssh = True
```


`hosts` where you set your environment.

```
[vm_tester]
10.10.0.1
```
Ansible accept a option to discover your inventory dynamically, but each cloud provider has your method to allow this feature.

















## Requirements

* [Docker](https://docs.docker.com/engine/installation/)

## Getting started

### Export your credentials as environment variables

[Create Azure Service Principal](https://www.terraform.io/docs/providers/azurerm/authenticating_via_service_principal.html) then export the credentials.

```bash
$ export AZURE_CLIENT_ID=YOUR_AZURE_CLIENT_ID
$ export AZURE_CLIENT_SECRET=YOUR_AZURE_CLIENT_SECRET
$ export AZURE_SERVICE_PRINCIPAL=YOUR_AZURE_SERVICE_PRINCIPAL
$ export AZURE_SUBSCRIPTION_ID=YOUR_AZURE_SUBSCRIPTION_ID
$ export AZURE_TENANT_ID=YOUR_AZURE_TENANT_ID
```

### Setup

Setup the docker image with [Ansible](https://www.ansible.com/) and [Terraform](https://www.terraform.io/) to get things done.

```bash
$ make setup
```
