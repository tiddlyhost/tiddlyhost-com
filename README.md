Tiddlyhost
==========

About
-----

Tiddlyhost is the new new Tiddlyspot, a hosting service for TiddlyWiki.

Rough plan (Jan 2021):
* Should be 100% containerized from the start
* Should use SSL from the start
* Will use Rails, for better or for worse
* Should have a serious deploy process (somehow)
* Should support subscription billing for users (somehow)
* Use S3 for saving Tiddlywiki files (probably)

Tiddlyhost will be somewhat based on an unfinished 2015-ish rewrite of
tiddlyspot-rails which used devise for account management.

I do want to opensource it, but will figure out how to to that later, probably
after it's functional.

Current Status
--------------

Embryonic. Very very early stages of development. May never work.

Getting Started
---------------

You need to have docker and docker-compose installed on your system.

Build the container image and start a bash shell inside it:

    make build-base
    make shell

Now run the following inside the container to install all the ruby gems and
node modules, and create the databases. Once that's all done you can exit the
container.

    bundle install
    rails webpacker:install
    rails db:create
    exit

Note that the container mounts the rails directory so you can
edit code outside the container in ./rails.

You should now be able to start rails like this:

    make start

Visit <http://0.0.0.0:3000/> in your browser and you should see a working
application.

You can shell into the running container in another terminal like this:

    make join

From there you can run the rails console, rake tasks, tests, etc, inside the
container.

When you're all done you can shut down like this:

    make cleanup

Note that the make tasks are mostly just wrappers for docker-compose so you
can use docker-compose commands if you prefer. See the Makefile for details.
