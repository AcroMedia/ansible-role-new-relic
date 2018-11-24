#!/bin/bash -ue

function usage () {
  echo "Usage:"
  echo "  $(basename "$0") NEW_RELIC_LICENSE_KEY 'App Name' [options]"
  echo ""
  echo "Options:"
  echo "  --php      - Install PHP application monitoring"
  echo "  --infra    - Install 'Infrastructure' product"
  echo ""
  echo "Example (deploying to a server; pay close attention - this is not a mistake): "
  echo "  ssh SERVER \"sudo bash -s\" -- < ./install-new-relic.sh YOUR_LICENSE_KEY_HERE \"'App name requires quoted quotes if it contains spaces'\" --infra --php"
}

function main () {

  # If you're missing optional-parameter-exists, install it with
  # git clone git@git.acromedia.com:acro/infrastructure.git
  # cd infrastructure/scripts
  # ./deploy.sh SERVER_NAME
  require_script /usr/local/bin/optional-parameter-exists
  require_script /usr/local/bin/backdir

  grep -q 'DISTRIB_ID=Ubuntu' /etc/lsb-release || {
    err "This script is only for Ubuntu servers."
    exit 1
  }

  if [ $# -lt 3 ]; then
    usage
    exit 1
  fi

  require_root

  export NR_INSTALL_KEY="$1"
  echo "NR_INSTALL_KEY: $NR_INSTALL_KEY"
  if [ "${#NR_INSTALL_KEY}" -ne 40 ]; then
    err "License key must be 40 chars exactly."
    exit 1
  fi
  export APPLICATION_NAME="$2"
  echo "APPLICATION_NAME: $APPLICATION_NAME"


  # Before we start,
  /usr/local/bin/backdir /etc


  # Does this really do anything?
  export NR_INSTALL_SILENT=1


  # Repository for PHP Agent
  if test -e /etc/apt/sources.list.d/newrelic.list; then
    echo "Apt repo already exists"
  else
    # Configure apt repo
    echo 'deb http://apt.newrelic.com/debian/ newrelic non-free' | tee /etc/apt/sources.list.d/newrelic.list
    # Trust gpg key
    wget -O- https://download.newrelic.com/548C16BF.gpg | apt-key add -
  fi
  apt-get update

  # Infrastructure
  if optional-parameter-exists "--infra" "$@"; then

    if dpkg --list |grep newrelic-infra; then
      echo "New Relic 'Infrastructure' is already installed."
    else

      #GPG key
      curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -

      # Repository
      source /etc/lsb-release
      grep https://download.newrelic.com/infrastructure_agent/linux/apt /etc/apt/sources.list.d/newrelic-infra.list || printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt $DISTRIB_CODENAME main" | tee -a /etc/apt/sources.list.d/newrelic-infra.list

      apt-get update

      # Set license key
      test -f /etc/newrelic-infra.yml || touch /etc/newrelic-infra.yml
      grep -q "$NR_INSTALL_KEY" /etc/newrelic-infra.yml || echo "license_key: $NR_INSTALL_KEY" >> /etc/newrelic-infra.yml

      # Install
      apt-get install newrelic-infra -y
    fi
  else
    echo "Pass '--infra' to install New Relic Infrastructure."
  fi







  # PHP agent
  if test -e /etc/php || test -e /etc/php5; then
    if optional-parameter-exists "--php" "$@"; then
      if dpkg --list |grep newrelic-php5; then
        echo "NR PHP APM appears to already be installed."
      else
        DEBIAN_FRONTEND=noninteractive apt-get -y install newrelic-php5
        newrelic-install install
      fi
      if test -f /etc/php/5.6/mods-available/newrelic.ini; then
        sed -i "s/newrelic.license = \"/newrelic.license = \"$NR_INSTALL_KEY/" /etc/php/5.6/mods-available/newrelic.ini
        sed -i "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$APPLICATION_NAME\"/" /etc/php/5.6/mods-available/newrelic.ini
      fi

      if test -f /etc/php/7.0/mods-available/newrelic.ini; then
        sed -i "s/newrelic.license = \"/newrelic.license = \"$NR_INSTALL_KEY/" /etc/php/7.0/mods-available/newrelic.ini
        sed -i "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$APPLICATION_NAME\"/" /etc/php/7.0/mods-available/newrelic.ini
      fi

      if test -f /etc/php/7.1/mods-available/newrelic.ini; then
        sed -i "s/newrelic.license = \"/newrelic.license = \"$NR_INSTALL_KEY/" /etc/php/7.1/mods-available/newrelic.ini
        sed -i "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$APPLICATION_NAME\"/" /etc/php/7.1/mods-available/newrelic.ini
      fi

      # These aren't needed at all.
      find /etc/php -mindepth 4 -name newrelic.ini -path '*/conf.d/*' -delete

      # Restart service(s)
      test -f /etc/php5/fpm/php.ini && service php5-fpm restart
      test -f /etc/php/5.6/fpm/php.ini && service php5.6-fpm restart
      test -f /etc/php/7.0/fpm/php.ini && service php7.0-fpm restart
      test -f /etc/php/7.1/fpm/php.ini && service php7.1-fpm restart
      test -f /usr/sbin/nginx && service nginx restart
      test -f /usr/sbin/apache2 && service apache2 restart
    else
      echo "Pass '--php' to install PHP application monitoring."
    fi
  else
    echo "Ignoring PHP Application monitoring. PHP is not installed."
  fi

  echo "All finished."

}

function require_root() {
  if [ $EUID -ne 0 ]; then
    err "This script must be run as root."
    exit 1
  fi
}

function require_script () {
  type "$1" > /dev/null  2>&1 || {
    err "The following is not installed or not in path: $1"
    exit 1
  }
}

function fatal () {
  bold_feedback "Fatal" "$@"
}

function err () {
  bold_feedback "Err" "$@"
}

function warn () {
  bold_feedback "Warn" "$@"
}

function bold () {
  echo "${BOLD}${*}${UNBOLD}"
}

# Requires Two arguments
function bold_feedback () {
  local PREFIX="${1:-"bold_feedback received no arguments"}"
  shift || true
  local MESSAGE="$*"
  cerr "${BOLD}${PREFIX}:${UNBOLD} ${MESSAGE}"
}

function info () {
  cerr "$@"
}

function cerr () {
  >&2 echo "$@"
}


BOLD=$(tput bold 2>/dev/null) || BOLD='' # Dont make noise if tput isn't available.
UNBOLD=$(tput sgr0 2>/dev/null) || UNBOLD='' # Dont make noise if tput isn't available.


main "$@"
