#! /bin/bash
#
# Copyright © 2020 Atomist, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

declare Pkg=yamllint
declare Version=0.1.0

set -o pipefail

# print message to stdout prefixed by package name.
# usage: msg MESSAGE
function msg () {
    echo "$Pkg: $*"
}

# print message to stderr prefixed by package name.
# usage: err MESSAGE
function err () {
    msg "$*" 1>&2
}

function main () {
    # Extract some skill configuration from the incoming event payload
    local config branch
    config=$( < "$ATOMIST_PAYLOAD" \
                  jq -r '.skill.configuration.instances[0].parameters[] | select( .name == "config" ) | .value' )
    if [[ $? -ne 0 ]]; then
        err "Failed to extract config parameter"
        return 1
    fi

    local outdir=${ATOMIST_OUTPUT_DIR:-/atm/output}

    # Make the problem matcher available to the runtime
    local matcher_outdir=$outdir/matchers
    if ! mkdir -p "$matcher_outdir"; then
        err "Failed to create matcher output directory: $matcher_outdir"
        return 1
    fi
    if ! cp /app/yamllint.matcher.json "$matcher_outdir"; then
        err "Failed to copy yamllint.matcher.json to $matcher_outdir"
        return 1
    fi

    # Prepare command arguments
    local homedir=${ATOMIST_HOME:-/atm/home}
    local inputdir=${ATOMIST_INPUT_DIR:-/atm/input}
    local config_option=
    if [[ $config && ! -f "$homedir/.yamllint*" ]]; then
        local config_file=$inputdir/yamllint.config.yaml
        if ! echo "$config" > "$config_file"; then
            err "Failed to create yamllint configuration file $config_file"
            return 1
        fi
        config_option="-c $config_file"
    fi

    exec yamllint $config_option -f parsable .
}

main "$@"
