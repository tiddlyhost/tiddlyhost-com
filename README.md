Tiddlyhost
==========

About
-----

Tiddlyhost is the new new Tiddlyspot, a hosting service for TiddlyWiki.

Unlike Tiddlyspot, Tiddlyhost features:

* Secure SSL
* Password recovery
* TiddlyWiki5 support
* Open source code

For more information please see
[FAQ](https://github.com/simonbaird/tiddlyhost/wiki/FAQ).


Current Status (Feb 2021)
-------------------------

It's still in the early stages of development, but it is now functional.

Currently [tiddlyhost.com](https://tiddlyhost.com/) is in "development
mode", which means it might be unstable, and you shouldn't use it for anything
important.

For more status updates see the
[Journal](https://github.com/simonbaird/tiddlyhost/wiki/Journal).


Getting Started (for developers)
--------------------------------

You need to have docker and docker-compose installed on your system.

Build the container image:

    make build-base

Install all ruby gems, node modules, and initialize the databases:
(Say no to overwriting /opt/app/config/webpack/environment.js.)

    make rails-init

Fetch an empty TW file:

    make empty

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

Note that the development environment is using a self-signed SSL certificate,
so you will need to accept the warnings about insecure connections.

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
