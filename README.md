# Ansible role: New Relic

*** For internal use only. *** Install and configure New Relic PHP and/or Infrastructure agents.

## Requirements

* Redhat or Ubuntu
* For internal use only.

## Role Variables

* `newrelic_extras_params`: These are the extra parameters to pass in to the scripts.

* `newrelic_app_name`: The default app name for the server.

* Host variables need to be made for each host this role will be applied to. The variables are defined in `example_host_vars/example_host.yml`

* `newrelic_license_key`: This is considered sensitive data, so avoid committing the value for this to your repository. Pass it in on the command line as `--extra-vars='newrelic_license_key=XXXXXX'`, or bring it into your playbook from a gitignore'd file with `include_vars` before you invoke the role. See `example_host_vars/example_host.yml` and `example_secrets/example_newrelic.yml`.

## Dependencies

This role isn't pure ansible. It's just a wrapper for the installer scripts that were already being employed. Those scripts depend on a few tools from the Acro Infrastructure repository's `deployables`, which keeps this role from being published on GitHub.


## Example Playbook

    - hosts: servers
      include_vars: {{ playbook_dir }}/secrets/my-gitignored-variables-file.yml
      roles:
         - role: acromedia.newrelic
           newrelic_extra_params: '--php --infra'
           when: newrelic_license_key is defined
             and newrelic_license_key|trim != ''

## License

For internal use only.

## Author Information

Acro Media Inc.
https://www.acromedia.com/
