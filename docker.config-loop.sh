#!/usr/bin/env bash

[[ "$TRACE" ]] && set -x

set -eo pipefail

_config_submodules() {
	printf "variables\nprint\nremove\nok"
}

_config_variable_add() {
	export CONFIG_VARIABLES="$1\\n$(config_variables)"
}

_config_variable_list() {
	echo -e "$CONFIG_VARIABLES" \
	| grep -v -E "^\s*$"
}

_config_get_severity() {
	local var="${1}_severity"
	printf "${!var}"
}

_config_export_severity() {
	local value="${!1}"
	value="${value:-$2}"
	export "$1=${value:-optional}"
}

_config_export_value() {
	export "$1=${2:-$3}"
}

_config_completed() {
	config_variables \
	| while read config_variable; do
		value="${!config_variable}"
		[[ "$value" ]] && continue
		required="${config_variable}_severity"
		severity="${!required}"
		echo "$config_variable is unconfigured" >&2
		[[ "$severity" = "required" ]] && return 1
	done
	return 0
}

_config_prepend_prefix() {
	local name="$1"
	local prefix="$2"
	[[ "$prefix" ]] || return 0
	export "$name=$prefix${!name}"
}

_config_append_suffix() {
	local name="$1"
	local suffix="$2"
	[[ "$suffix" ]] || return 0
	export "$name=${!name}$suffix"
}

_config_value_quote_string() {
	sed -e '1s/^/'\''/' -e '$s/$/'\''/'
}

_config_value_unquote_string() {
	sed -e '1s/^'\''//' -e '$s/'\''$//'
}

_config_value_inline() {
	sed -e ':a;N;$!ba;s/\n/\\n/g'
}

_config_value_breakline() {
	sed -e ':a;N;$!ba;s/\\n/\n/g'
}

_config_value_normalize() {
	local value="$1"
	echo -e "$value" \
	| _config_value_unquote_string \
	| _config_value_breakline
}

_config_value_escape() {
	local value="$1"
	echo -e "$value" \
	| _config_value_quote_string \
	| _config_value_inline
}

_config_default_add() {
	local name="$1"
	local default="$2"
	export "${name}_default=$(_config_value_normalize "$2")"
}

_config_default_get() {
	local name="$1"
	local default_var="${name}_default"
	printf "${!default_var}"
}

config_register() {
	local name="$1"
	local default_value="$2"
	local severity="$3"
	local prefix="$4"
	local suffix="$5"
	_config_variable_add "$1"
	_config_export_severity "${1}_severity" "$severity"
	_config_export_value "$1" "$(_config_value_normalize "${!1}")" "$2"
	_config_prepend_prefix "$1" "$4"
	_config_append_suffix "$1" "$5"
	_config_default_add "$1" "$2"
}

config_variables() {
	echo -e "$CONFIG_VARIABLES" \
	| grep -v -E "^\s*$" \
	| sort
}

config_print() {
  echo "# Begin of config"
  config_variables \
  | while read config_variable; do
    local severity="${config_variable}_severity"
    printf "# ${!severity}\n"
    printf "${config_variable}="
    _config_value_escape "${!config_variable}"
  done
  echo "# End of config"
}

config_remove() {
	local name="$1"
	export "$name=$(_config_default_get "$name")"
	config_print
}

config_ok() {
	_config_completed \
	&& echo "OK" \
	|| echo "FAIL"
}

config_help() {
	echo "Usage: DOCKER_CMD config (variables|print|remove|ok)"
}

config() {
	cmd="config_$1"
	echo "$1" \
	| grep "$(_config_submodules)" \
	  >/dev/null \
	|| exit 1
	shift 1
	$cmd $@
	exit $?
}