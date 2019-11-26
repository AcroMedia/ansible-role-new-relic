#!/bin/bash -ue

function usage () {
  echo "Usage:"
  echo "  $(basename "$0") LICENSE_KEY 'App Name' [options]"
  echo ""
  echo "Options:"
  echo "  --php      - Install PHP application monitoring"
  echo "  --infra    - Install 'Infrastructure' product (for Acro servers)"
  echo ""
  echo "Example (deploying to a server; pay close attention - this is not a mistake): "
  echo "  ssh SERVER \"sudo bash -s\" -- < ./install-new-relic.sh YOUR_LICENSE_KEY_HERE \"'App name requires quoted quotes if it contains spaces'\" --infra --php"
}

function main () {

  # If you're missing optional_parameter_exists, install it with
  # git clone git@git.acromedia.com:acro/infrastructure.git
  # cd infrastructure/scripts
  # ./deploy.sh SERVER_NAME
  require_script /usr/local/bin/optional_parameter_exists
  require_script /usr/local/bin/backdir

  test -e /etc/redhat-release || {
    err "This script is only for RHEL/CentOS servers."
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
  if test -e /etc/yum.repos.d/newrelic.repo; then
    echo "New relic repo already exists"
  else
    # Configure repo
    rpm -Uvh https://yum.newrelic.com/pub/newrelic/el5/x86_64/newrelic-repo-5-3.noarch.rpm
  fi


  # Infrastructure
  if optional_parameter_exists "--infra" "$@"; then

    if rpm -qa |grep newrelic-infra; then
      echo "New Relic 'Infrastructure' is already installed."
    else

      # Set license key
      test -f /etc/newrelic-infra.yml || touch /etc/newrelic-infra.yml
      grep -q "$NR_INSTALL_KEY" /etc/newrelic-infra.yml || echo "license_key: $NR_INSTALL_KEY" >> /etc/newrelic-infra.yml

      # Repository
      if grep -q -i "release 6" /etc/redhat-release; then
        curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/6/x86_64/newrelic-infra.repo
      elif grep -q -i "release 7" /etc/redhat-release; then
        curl -o /etc/yum.repos.d/newrelic-infra.repo https://download.newrelic.com/infrastructure_agent/linux/yum/el/7/x86_64/newrelic-infra.repo
      else
        err "Unrecognized / unsupported OS version -- can't install NR infrastructure agent"
        exit 1
      fi

      # Update cache
      yum -q makecache -y --disablerepo='*' --enablerepo='newrelic-infra'

      # Install
      yum install newrelic-infra -y

    fi
  else
    echo "Pass '--infra' to install New Relic Infrastructure."
  fi


  # PHP agent
  if test -e /etc/php.d; then
    if optional_parameter_exists "--php" "$@"; then
      if rpm -qa |grep newrelic-php5; then
        echo "NR PHP APM appears to already be installed."
      else
        yum install -y newrelic-php5
        newrelic-install install
        sed -i "s/newrelic.license = \"\"/newrelic.license = \"$NR_INSTALL_KEY\"/" /etc/php.d/newrelic.ini
        sed -i "s/newrelic.appname = \"PHP Application\"/newrelic.appname = \"$APPLICATION_NAME\"/" /etc/php.d/newrelic.ini

        test -x /usr/sbin/php-fpm && /sbin/service php-fpm restart
        test -x /usr/sbin/httpd && /sbin/service httpd restart
        test -x /usr/sbin/nginx && /sbin/service nginx restart
      fi
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
