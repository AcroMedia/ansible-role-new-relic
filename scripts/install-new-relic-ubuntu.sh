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
  backdir /etc


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
  if optional_parameter_exists "--infra" "$@"; then

    if dpkg --list |grep newrelic-infra; then
      echo "New Relic 'Infrastructure' is already installed."
    else

      #GPG key
      curl https://download.newrelic.com/infrastructure_agent/gpg/newrelic-infra.gpg | apt-key add -

      # Repository
      source /etc/lsb-release
      grep https://download.newrelic.com/infrastructure_agent/linux/apt /etc/apt/sources.list.d/newrelic-infra.list || printf "deb [arch=amd64] https://download.newrelic.com/infrastructure_agent/linux/apt %s main\n" "$DISTRIB_CODENAME"| tee -a /etc/apt/sources.list.d/newrelic-infra.list

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
    if optional_parameter_exists "--php" "$@"; then
      if dpkg --list |grep newrelic-php5; then
        echo "NR PHP APM appears to already be installed."
      else
        DEBIAN_FRONTEND=noninteractive apt-get -y install newrelic-php5
        newrelic-install install
      fi

      # These aren't needed at all.
      find /etc/php -mindepth 4 -name newrelic.ini -path '*/conf.d/*' -delete

      # Add license key + app name to config files
      local PHP_VERSIONS
      PHP_VERSIONS=$(mktemp)
      find /etc/php -mindepth 1 -maxdepth 1 -type d -name '?.?' \( ! -name "$(printf "*\n*")" \) -exec basename {} \; > "$PHP_VERSIONS"
      while IFS= read -r PHP_VER; do
        echo "PHP_VER=$PHP_VER"
        local INI="/etc/php/${PHP_VER}/mods-available/newrelic.ini"
        if [ -f "/etc/php/$PHP_VER/mods-available/newrelic.ini" ] ; then
          echo "Adding License and app name"
          sed -i "s/newrelic.license = \"\"/newrelic.license = \"$NR_INSTALL_KEY\"/" "/etc/php/$PHP_VER/mods-available/newrelic.ini"
          sed -i "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$APPLICATION_NAME\"/" "/etc/php/$PHP_VER/mods-available/newrelic.ini"
        else
          echo "File not found $INI"
        fi
        # Restart PHP
        [ -f "/etc/php/$PHP_VER/fpm/php.ini" ]  && service "php${PHP_VER}-fpm" restart
      done < "$PHP_VERSIONS"

      # Restart Web service
      [ -x /usr/sbin/nginx ] && service nginx restart
      [ -x /usr/sbin/apache2 ] && service apache2 restart
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


readonly NEEDLE_FOUND=0
readonly NEEDLE_NOT_FOUND=1
readonly MISSING_HAYSTACK=2

function optional_parameter_exists() {
  if [[ $# -lt 1 ]]; then
    fatal "Nevermind the haystack, I didn't even get the needle. Whoever called me did it the wrong way."
    exit $MISSING_HAYSTACK
  fi
  if [[ $# -lt 2 ]]; then
    warn "I received no haystack to look through."
  fi
  local PARAM_NAME_PATTERN=${1}; shift
  while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
      "${PARAM_NAME_PATTERN}")
        return $NEEDLE_FOUND;
        ;;
      *)
        # unknown / ignored option
        true
        ;;
    esac
    shift || break
  done
  return $NEEDLE_NOT_FOUND
}

function backdir () {
  local DIR_TO_BACK_UP=$1
  local DIR_WITHOUT_LEADING_SLASH
  DIR_WITHOUT_LEADING_SLASH=$(echo "$DIR_TO_BACK_UP"| sed -e 's/^\///')
  local ARCHIVEDIR=/var/backups
  local DATESTAMP
  DATESTAMP="$(date +%Y-%m-%d.%H%M%S.%3N)" || DATESTAMP="$(date +%Y-%m-%d.%H%M%S)"
  local TARFILE
  TARFILE="$ARCHIVEDIR/$(basename "$DIR_TO_BACK_UP").${DATESTAMP}.tgz"
  umask 077 # Backups can contain sensitive info. Any files/folders we create should be private
  tar --create --file "$TARFILE" --gzip --directory / "$DIR_WITHOUT_LEADING_SLASH"
}

main "$@"
