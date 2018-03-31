#!/bin/bash
# Monitoring sensor for checking a Grafana datasource against data becoming stale
#
# Copyright (c) 2018 Andreas Motl <andreas@getkotori.org>
# Licensed under the AGPL v3 License
#
# Homepage: https://github.com/daq-tools/monitoring-check-grafana
# Icinga Exchange: TODO
# Reporting Bugs: https://github.com/daq-tools/monitoring-check-grafana/issues/new
#
# Blueprints from Elan Ruusamäe, Christian Stankowic and Felix Geyer, thanks!
# https://github.com/glensc/monitoring-plugin-check_domain
# https://github.com/stdevel/check_katello_sync
# https://github.com/debfx/check_dane


# Fail on first error
set -e

PROGRAM=${0##*/}
VERSION=0.1.0

version() {
    echo "$PROGRAM $VERSION"
}

usage() {
    echo "Usage: $PROGRAM --help | --uri <uri-to-grafana-datasource> --database <database-name> --table <table-name>"
}

fullusage() {
    cat <<EOF
$PROGRAM $VERSION

Copyright (c) 2018 Andreas Motl <andreas@getkotori.org>
Licensed under the AGPL v3 License

Monitoring sensor for checking a Grafana datasource against data becoming stale.

Usage: $PROGRAM --help | --uri <uri-to-grafana-datasource> --database <database-name> --table <table-name>


-------
Options
-------
-u, --uri           Grafana API datasource proxy URI
-d, --database      Database name

-t, --table         Table name
-w, --warning       Maximum age threshold of data to result in warning status
-c, --critical      Maximum age threshold of data to result in critical status

-h, --help          Print detailed help
-V, --version       Print version information
-v, --verbose       Turn on verbose output


-------
Example
-------

    $PROGRAM \\
        --uri https://datahub.example.org/grafana/api/datasources/proxy/42/query \\
        --database testdrive \\
        --table temperature \\
        --warning 12h \\
        --critical 3d

Example output:

    INFO:  Checking Grafana datasource testdrive:temperature for data more recent than 3d
    INFO:  Checking Grafana datasource testdrive:temperature for data more recent than 12h
    WARNING - Data in testdrive:temperature is stale for 12h or longer

EOF
}

# Default values
set_defaults() {
    warning=1h
    critical=12h
}

# Command line argument parser
parse_arguments() {

    local args
    args=$(getopt -o hvVu:d:m:w:c:q: --long help,verbose,version,uri:,database:,table:,warning:,critical: -u -n "$PROGRAM" -- "$@")

    while :; do
        if [ -z $1 ]; then
            break
        fi

        case "$1" in
        -u|--uri)
            shift
            uri=$1
        ;;
        -d|--database)
            shift
            database=$1
        ;;
        -m|--table)
            shift
            table=$1
        ;;
        -w|--warning)
            shift
            warning=$1
        ;;
        -c|--critical)
            shift
            critical=$1
        ;;

        -v|--verbose)
            verbose="true"
        ;;
        -h|--help)
            fullusage
            exit
        ;;
        --)
            shift
            break
        ;;
        *)
            exitus $STATE_UNKNOWN "$PROGRAM failed parsing its commandline arguments"
        ;;
        esac
        shift
    done

    if [ -z "$uri" ]; then
        exitus $STATE_UNKNOWN "The --uri parameter is missing"
    fi

    if [ -z "$database" ]; then
        exitus $STATE_UNKNOWN "The --database parameter is missing"
    fi

    if [ -z "$table" ]; then
        exitus $STATE_UNKNOWN "The --table parameter is missing"
    fi

    if [ -z "$warning" ]; then
        exitus $STATE_UNKNOWN "The --warning parameter has an empty value"
    fi
    if [ -z "$critical" ]; then
        exitus $STATE_UNKNOWN "The --critical parameter has an empty value"
    fi

}


# Reporting
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3

exitus() {
    state=$1
    message=$2

    label="UNKNOWN"
    case "$state" in
        0) label="OK";;
        1) label="WARNING";;
        2) label="CRITICAL";;
        3) label="UNKNOWN";;
    esac

    echo "$label - $message"
    exit $state
}



# ------
# Sensor
# ------

# Write to STDERR
minfo()  { >&2 echo "INFO:  $@"; }
mdebug() { if [[ $verbose ]]; then >&2 echo "DEBUG: $@"; fi; }

data_is_stale() {

    # Address of Grafana API endpoint
    datasource=$1

    # Database and table names
    database=$2
    table=$3

    # Age threshold
    age=$4

    # Debugging
    minfo "Checking Grafana datasource $database:$table for data more recent than $age"

    # InfluxDB query, can be adapted to other databases
    query="SELECT * FROM $table WHERE time > now() - $age LIMIT 1"

    # Is there any data for the given query?
    mdebug "Running command: http \"$datasource\" db==\"$database\" q==\"$query\""
    is_stale=$(http "$datasource" db=="$database" q=="$query" | jq '.results[0].series == null')

    # TODO: Honor error message from Grafana when given database does not exist:
    # { "message": "Datasource is not configured to allow this database" }

    # Debugging
    mdebug "HTTP response 'is_stale': $is_stale"

    # Compute the result.
    # A positive outcome means we *have* recent data, so we should respond
    # with a *negative signal* to satisfy the answer for "data_is_stale".
    # In abundance to this, consider Bash-style return values
    # where zero (0) is usually used to signal success.

    # If data is stale, signal success.
    if $is_stale == "true"; then
        return 0

    # If data is recent, signal failure.
    else
        return 1
    fi

}


# ----
# Main
# ----
set_defaults
parse_arguments "$@"

if data_is_stale "$uri" "$database" "$table" "$critical"; then
    exitus $STATE_CRITICAL "Data in $database:$table is stale for $critical or longer"

elif data_is_stale "$uri" "$database" "$table" "$warning"; then
    exitus $STATE_WARNING "Data in $database:$table is stale for $warning or longer"

else
    exitus $STATE_OK "Data in $database:$table is more recent than $warning"

fi
