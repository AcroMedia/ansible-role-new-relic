newrelic
======

Installs and configures new relic on servers.


Requirements
------------
* Redhat or Ubuntu

Role Variables
--------------
* newrelic_extras_params: These are the extra parameters to pass in to the scripts.

* newrelic_app_name: The default app name for the server.

* Host variables need to be made for each host this role will be applied to. The variables are defined in `example_host_vars/example_host.yml`

* newrelic_license_key: Do not ever commit secrets to the repository. The actual value for the license should be stored in `ansible/secrets/newrelic.yml` which is gitignored, and referenced from the host variable file. Check the `example_secrets/example_newrelic.yml` for an example.

Dependencies
------------

None

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: acromedia.newrelic }

License
-------

BSD

Author Information
------------------

Acro Media Inc.
https://www.acromedia.com/
