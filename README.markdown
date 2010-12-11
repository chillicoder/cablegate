**Cablegate** is a simple Sinatra App that mirrors Wikileaks' Cablegate Database.

Background
----------

In the wake of a number of highly acclaimed, coordinated releases of leaked evidence of war crimes and other horrors in Afghanistan and Iraq, in late November 2010 Wikileaks commenced releasing 251,000 + leaked US diplomatic documents in collaboration with many major newspapers around the world. The US Government and many allied countries initially freaked out and a series of reprisal actions was undertaken including

* forcing wikileaks to change servers and DNS providers, banks, post office box addresses and more in a ham-fisted attempt to push wikileaks off the Internet and out of business.
* manoeuvring to have Wikileaks' founder, an Australian citizen, arrested (he was, for sex-crimes supposedly committed in Sweden, after Interpol issued a 'red' notice, despite him not having been charged formally with any crime).
* The Australian PM described Wikileaks as being 'illegal', implied that Assange would be considered a criminal, set her Attourney General the task of finding something to charge him with (The AG promptly declared he could take away Assange's passport but later retreated from that.) to the abject dismay of about 80% of the Australian public, and many members of her own and opposing parties. 
* various spokespeople in a number of countries declared their own personal fatwas on Assange, offering bounties for his head on national television (something as yet un-denounced by the Australian Government alas).

These brute force attacks on Wikileaks stirred up a lot of interest in the cables and pretty soon hundreds, then over a thousand mirrors jumped up — Wikileaks went viral.

In retaliation against the Govt / Corporate shutdown attempt an anonymous group of people, calling themselves Anonymous in fact, who made a name for themselves as a massive anonymous volunteer botnet, powered by a toy called LOIC, brought down PayPal, Visa, MasterCard, the Swedish Criminal Prosecutors office, a range of Government websites, and more; basically anyone who'd come out in opposition to Wikileaks. The attacks generated a whirlwind of publicity, well out of proportion to any actual damage done, with cries of it being an 'infowar'. But just as their antics were starting to generate bad-press for Wikileaks themselves (the media began to conflate Wikileaks with Anon), and the arrest of a 16 year old supporter in Holland, Anonymous changed their tactics to use their fan-base to [analyse the leaks themselves](http://www.boingboing.net/2010/12/09/anonymous-stops-drop.html).  I'm not a 16 year old script-kiddie, and I'm not about to join in any sort of DDoS attack, but I do enjoy programming and I've always admired Assange's intellect and weird, hard-core approach.  I realise he'd piss plenty of people off, but I know so many people like him and they are some of the smartest, most motivated people I know. I'd hide him in my basement if he needed it, and if I had a basement.

I recommend [this fabulous documentary](http://svtplay.se/v/2264028/wikirebels___the_documentary?cb,a1364145,1,f,-1/pb,a1364142,1,f,-1/pl,v,,2264028/sb,p118750,1,f,-1) (It's one hour long) if you have any doubts about what Assange and Wikileaks are trying to achieve.

The problem with the archives
-----------------------------

* they are growing in size day in day out and quickly.
* they are hard to search
* the mirrors are up and down as forces unfriendly to Wikileaks work hard to take down the mirrors so [the master mirror list](http://wikileaks.ch/mirrors.html) may not be reliable.

The Simple Idea
---------------

We need a cablegate mirror that can self-announce to other mirrors, can check each other for veracity, match against known build numbers and maintain live lists of active mirrors.  Such a system could easily be build in Sinatra and Hosted on Heroku (which has a certain irony in that Amazon kicked the Cablegate archive off its servers, but Heroku runs on Amazon so now it's back #lol)

But we also need a 'raw data' version of the Cabelgate cables in a way we can index, add favourites, etc and use as a research tool.  When the number of cables released gets to a certain level it won't fit in Heroku's slug size or in a free GitHub account any more.

Current Features
----------------

* A static copy of the latest (or close to it) Cablegate pages as archived by wikileaks and distributed by bittorrent
* Awareness of this codebase, and the build numbers as provided by wikileaks, via a simple announce mechanism
* Automatic Mirror announcements to other mirrors
* JSoN formatted export of known active and expired mirrors. (As in mirrors of this codebase, not all the known wikileaks mirrors but that's not a bad idea either.)

Fork Me
-------

Please fork this project if you have room and pull updates regularly. (see Keeping Up to Date below)

* Suggestions for improvements to the mirror announce and listen code are welcomed, it's probably buggy and its not properly tested. File an issue if you have ideas or suggestions.
* Suggestions for parsing the cables into a database are also welcome.

Deploying
---------

Create an account on [Heroku](http://www.heroku.com) and follow the instructions for adding your project and giving it a new name, then

	git push heroku master
	heroku rake db:seed

Keeping Up to Date
------------------

	git pull
	git push heroku master
	heroku open

Plans
-----

* The site tries to authorise on each request. It's a bug. I'll fix it.
* I've not made a start on parsing the archive into a db format yet. I'm hoping that the archive is already in someone else's database and I can just copy or read from that. Hello wikileaks, I'm talking to you here.
