.. image:: https://img.shields.io/github/tag/daq-tools/monitoring-check-grafana.svg
    :target: https://github.com/daq-tools/monitoring-check-grafana
.. image:: https://img.shields.io/badge/monitoring%20platform-Icinga2-green.svg
    :target: https://www.icinga.com/
.. image:: https://img.shields.io/badge/os%20platform-Linux%20%7C%20OS%20X-blue.svg
    :target: #

|

########################
monitoring-check-grafana
########################


*****
About
*****
A monitoring sensor for checking a Grafana datasource
against data becoming stale. This will let you detect
data loss or other dropout conditions of feeds into
your datasources.


*****
Goals
*****
Tired of operations or engineering messing with the datasources
or the sensors under the hood you are just watching in Grafana?

This plugin is an attempt to have a basic end-to-end monitoring
probe covering the whole track of data flowing from arbitrary
sensors into a (timeseries) database and then being displayed
in Grafana. So, this probe basically checks for success in:

- Acquisition: Data is received by the DAQ system.
- Storage: Measurements are stored into the database.
- Retrieval: Measurements are retrieved from the database.
- Display: Data is displayed in Grafana (almost).

This is nearly to-the-glass monitoring as it probes the very
same Grafana API endpoints as the frontend uses for fetching
metric data from, just before rendering it to the display.


**********
References
**********
We are currently using this plugin for monitoring freshness of
data flows from different sources into InfluxDB:

- Particulate matter measurements from the grassroots project `luftdaten.info`_
  are imported into the data acquisition system running at `Lufdaten in Grafana`_.
  You might also enjoy reading `about Lufdaten in Grafana`_.

- Weather data measurements from the `DWD CDC FTP server`_ are imported into the
  data acquisition system running at `weather.hiveeyes.org`_, see also
  `Datenerfassungssystem für Wetterdaten`_.

- Measurements from the `Open Hive Teststand`_ are received from the
  data acquisition system running at `swarm.hiveeyes.org`_, see also
  the `Hiveeyes project`_  and the `Hiveeyes data collection platform`_.

Kudos to all the people working behind the scenes for
providing these great open data resources to the community!

.. _luftdaten.info: https://luftdaten.info/
.. _Lufdaten in Grafana: https://luftdaten.getkotori.org/
.. _about Lufdaten in Grafana: https://getkotori.org/docs/applications/luftdaten.info/

.. _DWD CDC FTP server: ftp://ftp-cdc.dwd.de/
.. _weather.hiveeyes.org: https://weather.hiveeyes.org/
.. _Datenerfassungssystem für Wetterdaten: https://community.hiveeyes.org/t/open-weather-data/113/22

.. _Open Hive Teststand: https://community.hiveeyes.org/t/temperaturkompensation-fur-waage-notig-datensammlung/245/2
.. _swarm.hiveeyes.org: https://swarm.hiveeyes.org/
.. _Hiveeyes project: https://hiveeyes.org/
.. _Hiveeyes data collection platform: https://getkotori.org/docs/applications/hiveeyes.html


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

    ./check-grafana-datasource-stale.sh \
        --uri https://datahub.example.org/grafana/api/datasources/proxy/42/query \
        --database testdrive \
        --table temperature \
        --warning 12h \
        --critical 3d \
        --verbose

Sensor output::

    INFO:  Checking testdrive:temperature for data not older than 3d
    INFO:  Checking testdrive:temperature for data not older than 12h
    WARNING - Data in testdrive:temperature is stale for 12h or longer


**********
Screenshot
**********
Data acquisition from luftdaten.info triggered a data loss warning

.. image:: https://raw.githubusercontent.com/daq-tools/monitoring-check-grafana/main/screenshot-datasource-stale.jpg

when the people operating the platform had to perform some maintenance work on the database

.. raw:: html

    <blockquote class="twitter-tweet" data-lang="en">
        <p lang="en" dir="ltr">
            If someone is wondering: The API is down for maintenance. Today we received
            value no. ‘2^31+1’ . But the database was defined with a maximum of 2^31 values.
            We are currently changing this to 2^63. But this may need some time.
        </p>
        &mdash; OK Lab Stuttgart (@codeforS)
        <a href="https://twitter.com/codeforS/status/980017103976763392">March 31, 2018</a>
    </blockquote>
    <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>


*********************
Install prerequisites
*********************
This sensor uses the fine programs HTTPie_ and jq_,
please install them on your system.


Debian
======
::

    apt install httpie jq

    # Optionally
    pip install httpie


macOS
=====
::

    brew install httpie jq


.. _HTTPie: https://httpie.org/
.. _jq: https://stedolan.github.io/jq/



*******************
Setup Icinga plugin
*******************

Plugin environment
==================
::

    mkdir -p /usr/local/lib/icinga2/plugins

Edit ``/etc/icinga2/constants.conf``::

    const CustomPluginDir = "/opt/monitoring/plugins"

Installation
============
::

    git clone https://github.com/daq-tools/monitoring-check-grafana /opt/monitoring-check-grafana
    ln -s /opt/monitoring-check-grafana/check-grafana-datasource-stale.sh /opt/monitoring/plugins/check-grafana-datasource-stale
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

      # Optionally assign this service exclusively to these notification recipients only
      #vars.notification.mail.users  = [ "bruce-lee", "chuck-norris" ]
      #vars.notification.mail.groups = [ "null" ]
    }


See also `icinga-service-check-grafana.example.conf`_.

.. _icinga-service-check-grafana.example.conf: https://github.com/daq-tools/monitoring-check-grafana/blob/main/icinga-service-check-grafana.example.conf


*******************
Project information
*******************

About
=====
The "monitoring-check-grafana" sensor program is released under the GNU AGPL license.
Its source code lives on `GitHub <https://github.com/daq-tools/monitoring-check-grafana>`_.

If you'd like to contribute you're most welcome!
Spend some time taking a look around, locate a bug, design issue or
spelling mistake and then send us a pull request or create an issue.

Thanks in advance for your efforts, we really appreciate any help or feedback.

License
=======
Licensed under the GNU AGPL license. See LICENSE_ file for details.

.. _LICENSE: https://github.com/daq-tools/monitoring-check-grafana/blob/main/LICENSE
