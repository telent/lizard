# Lizard

*Lizard is being completely rewritten in a test-driven style now that
I actually know what I want it to do.  This README is from the
previously implemented spike (available in the old-master branch) and
may not correspond to either current or future reality in every
respect*

**Lizard** is a process/service monitor designed for starting,
stopping, restarting, and tracking the state of services on Unixoid
systems. It is primarily designed for "application" services (web
apps, queue runners, RPC services, etc) and is not intended as a
general-purpose init replacement.
 
* It uses a Ruby DSL for describing the services and processes to
start and how to monitor them.

* You can test services by polling them periodically. Your polling
code has the full power of Ruby available to it (as long as it doesn't
block on IO) and is called with an array argument that stores
historical values - so you can tolerate glitches in availability, or
implement hysteresis or weighted averages on continous variables. For
example, load averages, temperatures, service response times.

* Standard output and error streams from monitored processes is captured
and sent to syslog (with per-process configurable facility and priority)
to make diagnosis easier when processes fail to start

* It is implemented using EventMachine

* Service alert notifications by email are currently implemented. The
notification structure is extensible, so if you have an API to e.g. a
pager or an SMS service or a chatroom you can easily tell Lizard to
talk to it

