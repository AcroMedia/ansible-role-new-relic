newrelic
======

Installs and configures Acro's new relic account on servers.


Requirements
------------
* Redhat or Ubuntu
* The variables defined in defaults/main.yml to be placed in the inventory/host_vars/<YOUR HOST>.yml.
  For more info, read the defaults/main.yml

Role Variables
--------------

n/a

Dependencies
------------

None

Example Playbook
----------------

    - hosts: servers
      roles:
         - { role: acromedia.deploy-infra-scripts }

License
-------

BSD

Author Information
------------------

Acro Media Inc.
https://www.acromedia.com/
