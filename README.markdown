A simple Sinatra App that mirrors Wikileak's Cablegate Database.

Fork Me
-------

* Please fork this project if you have room and pull updates regularly.

Deploying
---------

* Create an account on http://heroku.com and follow the instructions for adding your project and giving it a new name, then
** git push heroku master
** heroku rake db:seed

Plans
-----

* The site will announce itself on startup to other listening mirrors
* The site will Listen for the announcement of new mirrors
* The site will publish a list of the top 50 (by uptime) mirrors via JSoN
