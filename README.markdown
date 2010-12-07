A simple Sinatra App that mirrors Wikileak's Cablegate Database.

Deploying
---------

* Create an account on Heroku.
* git push heroku master
*	`heroku rake db:migrate`
* `heroku rake db:seed`
