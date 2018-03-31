###############################
monitoring-check-grafana README
###############################


*****
About
*****
This is a monitoring sensor for checking a
Grafana datasource against data becoming stale.


*****
Setup
*****

Plugin environment
==================
::

    mkdir -p /usr/local/lib/nagios/plugins

/etc/icinga2/constants.conf::

    const PluginContribDir = "/usr/local/lib/nagios/plugins"

Install plugin
==============
::

    git clone https://github.com/daq-tools/monitoring-check-grafana /opt/monitoring-check-grafana
    ln -sr /opt/monitoring-check-grafana/check-grafana-datasource-stale.sh /usr/local/lib/nagios/plugins/check-grafana-datasource-stale
    ln -sr /opt/monitoring-check-grafana/icinga-command-check-grafana.conf /etc/icinga2/conf.d/command-check-grafana.conf


*************
Configuration
*************
Please have look at the configuration blueprint `icinga-service-check-grafana.example.conf`__.

.. _icinga-service-check-grafana.example.conf:


*****
Usage
*****
::

    $ ./check-grafana-datasource-stale.sh --help

    Options:
    -u, --uri           Grafana API datasource proxy URI
    -d, --database      Database name

    -t, --table         Table name
    -w, --warning       Maximum age threshold of data to result in warning status
    -c, --critical      Maximum age threshold of data to result in critical status

    -h, --help          Print detailed help
    -V, --version       Print version information
    -v, --verbose       Turn on verbose output


*******
Example
*******
Sensor invocation::

    ./check-grafana-datasource-stale.sh \\
        --uri https://datahub.example.org/grafana/api/datasources/proxy/42/query \\
        --database testdrive \\
        --table temperature \\
        --warning 12h \\
        --critical 3d

Sensor output::

    INFO:  Checking Grafana datasource testdrive:temperature for data more recent than 3d
    INFO:  Checking Grafana datasource testdrive:temperature for data more recent than 12h
    WARNING - Data in testdrive:temperature is stale for 12h or longer

.. note:: No worries, the first two lines will go to STDERR.
