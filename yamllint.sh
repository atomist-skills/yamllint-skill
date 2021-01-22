#! /bin/bash
#
# Copyright © 2021 Atomist, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#	  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare Pkg=yamllint
declare Version=0.2.0

set -o pipefail

# write status to output location.
# usage: status CODE MESSAGE
function status () {
	local statusFile=${ATOMIST_STATUS:-/atm/output/status.json}
	printf '{"code":%d,"reason":"%s"}' "$1" "$2" > "$statusFile"
}

# print message to stdout prefixed by package name.
# usage: msg MESSAGE
function msg () {
	echo "$Pkg: $*"
}

# print message to stderr prefixed by package name.
# usage: err MESSAGE
function err () {
	msg "$*" 1>&2
	status 1 "$*"
}

function main () {
	# Extract some skill configuration from the incoming event payload
	local payload=${ATOMIST_PAYLOAD:-/atm/payload.json}
	local config
	config=$( < "$payload" \
		  jq -r '.skill.configuration.parameters[] | select( .name == "config" ) | .value' )
	if [[ $? -ne 0 ]]; then
		err "Failed to extract parameters from payload in $payload"
		return 1
	fi

	# Bail if no YAML files exists in current project
	if [[ -z $(find . \( -name '*.yaml' -or -name '*.yml' \) -print -quit) ]]; then
		exit 0
	fi

	local outdir=${ATOMIST_OUTPUT_DIR:-/atm/output}

	# Make the problem matcher available to the runtime
	local matchers_dir=${ATOMIST_MATCHERS_DIR:-$outdir/matchers}
	if ! mkdir -p "$matchers_dir"; then
		err "Failed to create matcher output directory: $matchers_dir"
		return 1
	fi
	if ! cp /app/yamllint.matcher.json "$matchers_dir"; then
		err "Failed to copy yamllint.matcher.json to $matchers_dir"
		return 1
	fi

	# Prepare command arguments
	local homedir=${ATOMIST_HOME:-/atm/home}
	local inputdir=${ATOMIST_INPUT_DIR:-/atm/input}
	local config_option=
	if [[ $config ]]; then
		# safely make sure a yamllint configuration does not already exist
		if ! ls "$homedir"/.yamllint* > /dev/null 2>&1; then
			local config_file=$inputdir/yamllint.config.yaml
			if ! echo "$config" > "$config_file"; then
				err "Failed to create yamllint configuration file $config_file"
				return 1
			fi
			config_option="-c $config_file"
		fi
	fi

	yamllint $config_option -f parsable .
	local rv=$?
	if [[ $rv -eq 0 ]]; then
		status 0 "No errors or warnings found"
		return 0
	elif [[ $rv -eq 1 ]]; then
		status 0 "One or more errors found"
		return 0
	elif [[ $rv -eq 2 ]]; then
		status 0 "No errors, but one or more warnings found"
		return 0
	else
		status 1 "Unknown yamllint exit code"
		return $rv
	fi
}

main "$@"
