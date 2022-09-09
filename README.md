# Ansible role: New Relic

![.github/workflows/molecule.yml](https://github.com/AcroMedia/ansible-role-new-relic/workflows/.github/workflows/molecule.yml/badge.svg)

Install and configure New Relic PHP and/or Infrastructure agents.

This role is just a pretty wrapper for a couple of bash scripts we were already using, which worked well enough that we didn't need to reinvent the wheel.

See https://docs.newrelic.com/docs/agents/php-agent/installation/php-agent-installation-overview
and https://docs.newrelic.com/docs/infrastructure/install-configure-manage-infrastructure/linux-installation/install-infrastructure-linux-using-package-manager


## Requirements

* Red Hat 6+, or Ubuntu 16+. Also known to work with Amazon Linux and CentOS.


## Role Variables

* **newrelic_extra_params** (string): Required. Can be either `--php` (to install PHP APM), `--infra` (to install Infrastructure agent), or both. This variable is just forwarded to the scripts, and instructs the script which agent(s) to install.

* **newrelic_app_name** (string): Required. This is what name your servers show up as in New Relic APM. All servers that have the same name are grouped together into the same application in New Relic.

* **newrelic_license_key** (string): Required. Avoid committing this to your repository unless you've encrypted it with ansible vault first. You can pass it in on the command line as `--extra-vars='newrelic_license_key=XXXXXX'`.

* **newrelic_restart_services** (list): Optional, but recommended. A list of service names that need to be restarted in order for the new relic agent(s) to pick up on any modified ini file values. If this isn't provided, it'll be up to you to restart your services manually, or by some other method.

* **newrelic_state**: Default: `present`. Set to `absent` to remove *all* new relic packages from the server and have it stop sending data.

## Dependencies

None.


## Example Playbook

```yaml
- hosts: servers
  roles:
     - role: acromedia.newrelic
       newrelic_extra_params: '--php --infra'
       newrelic_restart_services:
        - php7.3-fpm
        - nginx
       when: newrelic_license_key is defined
         and newrelic_license_key|trim != ''
```

## License

GPLv3


## Author Information

Acro Media Inc.
https://www.acromedia.com/
