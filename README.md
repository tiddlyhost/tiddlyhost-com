Tiddlyhost
==========

About
-----

[Tiddlyhost](https://tiddlyhost.com/) is the new Tiddlyspot, a hosting
service for TiddlyWiki.

It aims to be the easiest and best way to use TiddlyWiki online.

Unlike the original Tiddlyspot, Tiddlyhost features:

* Secure SSL
* Password recovery
* TiddlyWiki5 support
* Open source code

For more information please see
[FAQ](https://github.com/simonbaird/tiddlyhost/wiki/FAQ).


Current Status
--------------

Tiddlyhost is in active development.

For status updates see the
[Journal](https://github.com/simonbaird/tiddlyhost/wiki/Journal).


Getting Started (for developers)
--------------------------------

Todo: Describe the other way to bring up a development system where you run
rails directly.

### Prepare environment

You need to have
[docker](https://docs.docker.com/get-docker/) and
[docker-compose](https://docs.docker.com/compose/install/)
installed on your system.

Check out the code:

    git clone git@github.com:simonbaird/tiddlyhost.git
    cd tiddlyhost

### Build the development container and set up rails

Build the container image used for development:

    make build-base

Install all ruby gems, node modules, and initialize the databases:

    make rails-init

Run the test suite. Hopefully it's all passing:

    make test

Tiddlyhost uses wildcard subdomains. To simulate this for local development,
add some entries to your /etc/hosts:

    127.0.0.1 tiddlyhost.local
    127.0.0.1 aaa.tiddlyhost.local
    127.0.0.1 bbb.tiddlyhost.local
    127.0.0.1 foo.tiddlyhost.local
    127.0.0.1 bar.tiddlyhost.local

You should now be able to start rails like this:

(It runs in the foreground, so I suggest you do this in a second terminal
window.)

    make start

Visit <https://tiddlyhost.local/> in your browser and you should see a working
web application.

Note that the development environment is using a self-signed SSL certificate,
so you will need to accept the warnings about insecure connections.

### Create an account and create a site

Click "Sign up" and enter some details. A fake email address is fine.

Emails won't be sent when running locally, but you can find the email
confirmation link by running this:

    make signup-link

Click that link and then you should be able to sign in.

Note: For the very first user created, the confirmation step will be skipped
and you'll be logged in immediately.

Click "Create Site" to create a site. Note that you need to use a site name
that matches something that you added to your /etc/hosts file, aaa or bbb for
example.

Click on the site to open it. Accept the certificate warnings again. Click the
save button and confirm your site was able to be saved.

Create other sites or other local accounts as required.

### Other useful commands

Note that the container mounts the rails directory, so the code can be edited
there outside the container while rails is running inside the container.

You can shell into the running container in another terminal like this:

    make join

From there you can access the rails console, run tests, etc, inside the
container.

You can hit Ctrl-C in the terminal where you ran `make start` to shut
it down.

You can also shut down and clean up like this:

    make cleanup

Note that the make tasks are mostly just wrappers for docker-compose so you
can use your own docker-compose commands directly if you prefer. See the
Makefile for details.

Run `make` by itself to see a full list of make commands. Read the Makefile to
learn more about what they do.


License
-------

Tiddlyhost is open source software. It uses a BSD license. See
[LICENSE.md](LICENSE.md).
