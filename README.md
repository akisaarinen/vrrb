vrrb - show local train timetables in a nice format
===================================================

![screenshot!](https://github.com/akisaarinen/vrrb/raw/master/screenshot.png)

vrrb is a simple web application, showing real-time timetables for local trains
in Helsinki area, formatted nicely for a station of your choice. Especially
suitable for mobile phone use. Train timestables are fetched from vr.fi (as
ugly HTML), parsed and then displayed.

Note that the application currently renders <b>Finnish only</b>.

Why?
----

In one word: convenience. You'll see all available real-time timetable
information for your station from vr.fi in one view, so you can check when does
the next train leave and if it seems to be delayed. VR does not provide such a
view, only an UI which requires clicks after clicks if you want to see anything
remotely useful.

How?
----
Setup ruby with required gems (see vr.rb) and run with ruby. Will bind to port
4567 and start serving the nice little view.

Required rubygems for running vr.rb:
    gem install nokogiri sinatra

If you want to develop vrrb further, you will most probably like to run
the automatic tests too. Required rubygems for tests are:

    gem install rspec mocha

Licensing
---------

See LICENSE.

Known issues / future development:
----------------------------------
* Refresh-button missing (useful if using fullscreen with iphone)
* Ajaxified refresh for single train would be useful
* Notifications from vr.fi are not displayed (e.g. reason for delay)
* When train has already left, current the UI shows "-5 minutes until departure".
* Vr.fi sometimes displays very old trains (~5 hours) if they have been cancelled
  and never left. These should be dropped from the UI, because those hanging on top
  of the list is not very useful.
