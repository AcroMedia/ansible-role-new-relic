newrelic
======

Installs and configures new relic on servers.


Requirements
------------
* Redhat or Ubuntu

Role Variables
--------------

* Host variables need to be made for each host this role will be applied to. The variables are defined in `example_host_vars/example_host.yml`

* Do not ever commit secrets to the repository. The actual licenses should be stored in `ansible/secrets/newrelic.yml` which is gitignored, and referenced from the host variable file. Check the `example_secrets/example_newrelic.yml` for an example.

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