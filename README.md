# Ansible role: New Relic

Install and configure New Relic PHP and/or Infrastructure agents.

This role is just a pretty wrapper for a couple of bash scripts we were already using, which worked well enough that we didn't need to reinvent the wheel.

See https://docs.newrelic.com/docs/agents/php-agent/installation/php-agent-installation-overview
and https://docs.newrelic.com/docs/infrastructure/install-configure-manage-infrastructure/linux-installation/install-infrastructure-linux-using-package-manager


## Requirements

* Red Hat 6 or Ubuntu 16+


## Role Variables

* **newrelic_extra_params**: Required. Can be either `--php` (to install PHP APM), `--infra` (to install Infrastructure agent), or both. This variable is just forwarded to the scripts, and instructs the script which agents to install.

* **newrelic_app_name**: Required. This is what name your servers show up as in New Relic APM. All servers that have the same name are grouped together into the same application in New Relic.

* **newrelic_license_key**: Required. Avoid committing this to your repository unless you've encrypted it with ansible vault first. You can pass it in on the command line as `--extra-vars='newrelic_license_key=XXXXXX'`.


## Dependencies

None.


## Example Playbook

    - hosts: servers
      roles:
         - role: acromedia.newrelic
           newrelic_extra_params: '--php --infra'
           when: newrelic_license_key is defined
             and newrelic_license_key|trim != ''


## License

GPLv3


## Author Information

Acro Media Inc.
https://www.acromedia.com/
