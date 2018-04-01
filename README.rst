########################
monitoring-check-grafana
########################


*****
About
*****
A monitoring sensor for checking a Grafana datasource against data becoming stale.


*****
Goals
*****
Tired of operations or engineering messing with your datasources in Grafana?
Let them monitor their own dogfood!

We are currently using this for monitoring the data flow
of community-based particulate matter measurements
from `luftdaten.info`_ into our data acquisition system
at `Lufdaten in Grafana`_. Aou might also enjoy reading
`about Lufdaten in Grafana`_.

.. _luftdaten.info: https://luftdaten.info/
.. _Lufdaten in Grafana: https://luftdaten.getkotori.org/
.. _about Lufdaten in Grafana: https://getkotori.org/docs/applications/luftdaten.info/


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



*******************
Setup Icinga plugin
*******************

Plugin environment
==================
::

    mkdir -p /usr/local/lib/icinga2/plugins

Edit ``/etc/icinga2/constants.conf``::

    const PluginContribDir = "/usr/local/lib/icinga2/plugins"

Installation
============
::

    git clone https://github.com/daq-tools/monitoring-check-grafana /opt/monitoring-check-grafana
    ln -s /opt/monitoring-check-grafana/check-grafana-datasource-stale.sh /usr/local/lib/icinga2/plugins/check-grafana-datasource-stale
    ln -s /opt/monitoring-check-grafana/icinga-command-check-grafana.conf /etc/icinga2/conf.d/command-check-grafana.conf


Configuration
=============
A blueprint for a usual configuration object::

    object Service "Grafana datasource freshness for testdrive:temperature" {
      import "generic-service"
      check_command         = "check-grafana-datasource-stale"

      host_name             = "datahub.example.org"
      vars.sla              = "24x7"

      vars.grafana_uri      = "https://datahub.example.org/grafana/api/datasources/proxy/42/query"
      vars.grafana_database = "testdrive"
      vars.grafana_table    = "temperature"
      vars.grafana_warning  = "1h"
      vars.grafana_critical = "12h"
    }


See also `icinga-service-check-grafana.example.conf`_.

.. _icinga-service-check-grafana.example.conf: https://github.com/daq-tools/monitoring-check-grafana/blob/master/icinga-service-check-grafana.example.conf
