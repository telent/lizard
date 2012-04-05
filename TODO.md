# continuity

If we die for some reason (e.g. OOM killer), so do all the processes
we started.  This is not ideal.  Maybe create a separate process in C
that spawns stuff for us on command and talks to us on a named pipe or
similar.  We will need to arrange stdout/err in some way so that it
all continues to go through syslog (linux-specific solution:
SCM_RIGHTS; can we do something more portable with /dev/fd/n ?)

# documentation

As the interface stabilises, we should write it down.  Somewhere in the
world there must be a cross between Rocco and YARD, but I don't know
what exactly

# customisation

Perhaps there is a better way to generate emails than by embedding
text in the source code files.  ERB is the obvious go-to tool

# monitor/filesystem

Implement this to the extent that it actually knows how to check 
filesystem free space (shell out to df: calling statvfs() from Ruby is 
too much like pain)

# monitor/process

setuid!

# monitor/process/died

Make the respawn-on-exit behaviour configurable, e.g.
poll :event=>:exit, count: 5 do |r| 
  # called each time a child dies
  r << Time.now  
  if r[0]< Time.now-5 then restart 
  else notify "disabled due to too many respawns", r
  end
end

# poll

some useful and terse functionality for e.g. checking uptime of web
services would be very useful in writing poll blocks

# remote

figure out how to manage Lizards across a network
