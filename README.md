vrrb - show local train timetables in a nice format
===================================================

What?
-----

vrrb is a simple sinatra web application which shows real-time timetables for
local trains in Helsinki area from vr.fi, formatted nicely for a station of
your choice. Especially suitable for mobile phone use.

Note that the application currently renders Finnish only.

Why?
----

You can configure the application for your station and it will show all
available real-time timetable information from vr.fi in one view, so you can
check when does the next train leave and if it seems to be delayed. VR does not
provide such a view, only an UI which requires clicks after clicks if you want
to see anything remotely useful.

How?
----

Setup ruby with required gems (see vr.rb) and run with ruby. Will bind to port
4567 and start serving the nice little view.

Screenshot of my home station with iPhone:

![screenshot!](https://github.com/akisaarinen/vrrb/raw/master/screenshot.png)

Licensing
---------

See LICENSE.

Required rubygems
-----------------

For running vrrb:
* gem install nokogiri sinatra


And for running tests:
* gem install rspec mocha
