#############################
monitoring-check-grafana TODO
#############################


*****
Tasks
*****
- [o] Add "check-grafana-datasource-generic" program expecting
      --query-warning and --query-critical parameters
      to be able to monitor using arbitrary expressions.
- [o] Add Grafana authentication capabilities


************************
Sensor announcement text
************************

::

    <one blank line at the top>

    Sensor announcement
    -------------------

    The "check-grafana-datasource-stale" sensor [1] just started checking
    for data loss or dropout conditions on the data acquisition channel
    displayed at [2]. It will send warnings 1h after data got stale and
    critical notifications after 2d.

    Enjoy the silence [3].

    [1] https://github.com/daq-tools/monitoring-check-grafana
    [2] https://swarm.hiveeyes.org/grafana/d/000000217/open-hive-teststand
    [3] https://www.youtube.com/watch?v=aGSKrC7dGcY

