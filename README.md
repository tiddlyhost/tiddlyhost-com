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


Current Status (Feb 2021)
-------------------------

Very early stages of development.

It's mostly functional on my local development environment. The next steps are
to figure out how to host it somewhere and how to set up a wildcard SSL cert.


Getting Started (for developers)
--------------------------------

You need to have docker and docker-compose installed on your system.

Build the container image:

    make build-base

Install all ruby gems, node modules, and initialize the databases:
(Say no to overwriting /opt/app/config/webpack/environment.js.)

    make rails-init

Add a TW empty file to rails/empties/tw5.html. (For best results it needs to
be slightly modified. Todo: Explain how to get the modifications.)

Run the test suite:

    make tests

Note that the container mounts the rails directory so you can
edit code outside the container in ./rails.

Tiddlyhost uses wildcard subdomains. To simulate this for local development,
add some entries to your /etc/hosts:

    127.0.0.1 tiddlyhost.local
    127.0.0.1 www.tiddlyhost.local
    127.0.0.1 foo.tiddlyhost.local
    127.0.0.1 bar.tiddlyhost.local
    127.0.0.1 baz.tiddlyhost.local
    127.0.0.1 quux.tiddlyhost.local
    127.0.0.1 aaa.tiddlyhost.local
    127.0.0.1 bbb.tiddlyhost.local
    127.0.0.1 foo-bar.tiddlyhost.local
    127.0.0.1 simon.tiddlyhost.local

You should now be able to start rails like this:

    make start

Visit <http://tiddlyhost.local:3000/> in your browser and you should see a working
application.

You can shell into the running container in another terminal like this:

    make join

From there you can run the rails console, rake tasks, tests, etc, inside the
container.

When you're all done you can shut down like this:

    make cleanup

Note that the make tasks are mostly just wrappers for docker-compose so you
can use docker-compose commands if you prefer. See the Makefile for details.


License
-------

Tiddlyhost is open source software. It uses a BSD license. See
[LICENSE.md](LICENSE.md).
