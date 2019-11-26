# Ansible role: New Relic

Install and configure New Relic PHP and/or Infrastructure agents.


## Requirements

* Red Hat 6 or Ubuntu 16+

## Role Variables

* `newrelic_extra_params`: These are the extra parameters to pass in to the scripts.

* `newrelic_app_name`: The default app name for the server.

* `newrelic_license_key`: Avoid committing this to your repository unless you've encrypted it with ansible vault first. You can pass it in on the command line as `--extra-vars='newrelic_license_key=XXXXXX'`.


## Dependencies

None.


## Example Playbook

    - hosts: servers
      include_vars: {{ playbook_dir }}/secrets/my-gitignored-variables-file.yml
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
