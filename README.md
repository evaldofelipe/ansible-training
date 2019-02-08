# Ansible training

## Table of Contents

- [Ansible introduction](#ansible-introduction)
- [Ansible goals](#ansible-goals)
- [Ansible concepts](#ansible-concepts)
 - [Task & modules](#task-modules)
 - [Role](#role)
 - [Playbook](#playbook)
 - [Workflow](#workflow)
- [Requirements](#requirements)
- [Getting started](#getting-started)
- [Create Ansible files](#create-ansible-files)

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

All the modules have your documentation listed with `ansible-doc`

```bash
$ ansible-doc {module-name}
```

To list all the available modules, use the flag `-l`

```bash
$ ansible-doc -l
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

The Ansible define some particularites to create a role folder.

```
roles/
   example-role/
     tasks/
     handlers/
     defaults/
     vars/
     files/
     templates/
     meta/
```

- `tasks` - contains the main list of tasks to be executed by the role.
- `handlers` - contains handlers, which may be used by this role or even anywhere outside this role.
- `defaults` - default variables for the role.
- `vars` - other variables for the role.
- `files` - contains files which can be deployed via this role.
- `templates` - contains templates which can be deployed via this role.
- `meta` - defines some meta data for this role. See below for more details.

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
Ansible accept an option to discover your inventory dynamically, but each cloud provider has your method to allow this feature.


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

### Create a virtual machine

Use terraform to deploy a temporary VM to configure with Ansible.

```bash
$ make terraform-init
$ make terraform-apply
```

## Create Ansible files

### hosts
Check the temporary IP generated from terraform output and create the `hosts` file on path `ansible/environments/dev/hosts`

```
[vm_tester]
your.vm.ip.here
```
TIP: if your first `terraform-apply` don't output the ip address, run the command again to receive the information.

### ansible.cfg

Create a `ansible.cfg` file on path `ansible/ansible.cfg` to define basics parameters for Ansible.

```
[defaults]
host_key_checking = False

[ssh_connection]
scp_if_ssh = True
```

### Create a playbook

To execute the example role on the project, you need create a playbook file `main-playbook.yml` on path `ansible/main-playbook.yml`

```yml
---
- name: Main playbook
  become: yes
  gather_facts: no
  hosts: vm_tester

  roles:
    - { role: docker-install, tags: docker }
```
This role ensure the docker was instaled and running on VM.

### Execute the playbook

The file `Makefile` have a target to execute the Ansible inside the container

```bash
$ make ansible-playbook playbook=main-playbook env=dev tags=docker user=tmp
```

### Check the VM

Connect via ssh on the machine and verify the docker status

### Create a role

As a demo for this project, you'll create a role to run a container with nginx, using a unit. Exists a previous role created to install the docker on VM.

Create a role paths.

```bash
mkdir -p ansible/roles/nginx-unit/{tasks,templates}
```

### tasks

Your tasks file will copy the unit to specific unit folder and ensure the execution of the new unit.

Create the file `main.yml` on path `ansible/roles/nginx-unit/tasks/main.yml`

```yml
---
- name: Copy systemd services
  template:
    src: "etc/systemd/system/{{ item }}.j2"
    dest: "/etc/systemd/system/{{ item }}"
    owner: root
  register: systemd
  with_items:
    - nginx-tmp.service

- name: Ensure systemd service
  systemd:
    name: "{{ item.item }}"
    daemon_reload: yes
    enabled: yes
    state: "{{ (item.changed) | ternary('restarted', 'started') }}"
  with_items: "{{ systemd.results }}"

```
### Unit file

For best manage of the resource, this project use a unit file to deploy the service.

Create the unit file called `nginx-tmp.service.j2` on path `ansible/roles/nginx-unit/templates/etc/systemd/system/nginx-tmp.service.j2`

```
[Unit]
Description=nginx-test container
After=docker.service

[Service]
TimeoutStartSec=0
Restart=always
ExecStartPre=-/usr/bin/docker kill nginx
ExecStartPre=-/usr/bin/docker rm nginx
ExecStartPre=-/usr/bin/docker pull "nginx"
ExecStart=/usr/bin/docker run --rm --name nginx-test -p 80:80 nginx
ExecStop=/usr/bin/docker stop nginx-test

[Install]
WantedBy=multi-user.target
```

### Add new role

After create the role, add them to your `main-playbook.yml`

```yml
- { role: nginx-unit, tags: nginx-unit }
```

### Execute new role

Run the ansible-playbook target again, with the tag for a new role

```bash
$ make ansible-playbook playbook=main-playbook tags=nginx user=tmp
```

Check your service status

```bash
$ curl [your_output_ip]
```
### Protect your sensitive information with vault

Vault is a extension of Ansible to encrypt and decrypt passwords, keys, or whathaver you want protect on your project.

On this example you'll protect a simple command as a variable.

On role template file `ansible/roles/nginx-unit/templates/etc/systemd/system/nginx-tmp.service.j2` edit the lines where are the `ExecStart` and `ExecStop` commands

```bash
ExecStart={{ nginx_start_command }}
ExecStop={{ nginx_stop_command }}
```
Create the `default` folder for store this variables, on path `ansible/roles/nginx-unit/defaults`

```bash
$ mkdir -p ansible/roles/nginx-unit/default
```


Create the file `main.yml` on path `ansible/roles/nginx-unit/defaults/main.yml`

```yml
---
nginx_start_command: "/usr/bin/docker run --rm --name nginx-test -p 80:80 nginx"
nginx_stop_command:  "/usr/bin/docker stop nginx-test"

```
Generate a password to use on encrypt proccess

```bash
$ openssl rand -base64 10
```
Encrypt the variable file that you created

```bash
ansible-vault encrypt ansible/roles/nginx-unit/defaults/main.yml
```

Save the password on a file for Ansible use

```bash
$ echo [your.password.here] > ansible/vault_password_file
```

Add to your file `ansible/ansible.cfg` the path to your vault file

```bash
[defaults]
host_key_checking = False
vault_password_file = ./vault_password_file
```

Now, to test all the process, execute all the roles together and the return need to be `changed=0    unreachable=0    failed=0`

```bash
$ make ansible-playbook playbook=main-playbook env=dev tags=all user=tmp
```

### Destroy your test infrastructure

After all the tests, destroy all resources with terraform

```bash
$ terraform destroy
```
