#!/bin/bash
#
# Creates a self-signed cert and key so we can use SSL locally.
# (I referenced https://devcenter.heroku.com/articles/ssl-certificate-self
# but there are plenty of similar guides out there.)
#
#
set -e

TARGET_DIR=$1
mkdir -p "$TARGET_DIR"

echo Creating self-signed SSL cert...

# Create a private key
openssl genrsa -des3 -passout pass:xxxx -out server.pass.key 2048

# Remove the password from the key
openssl rsa -passin pass:xxxx -in server.pass.key -out server.key

# Create a signing request
openssl req -new -key server.key -out server.csr -subj \
  "/C=US/O=Tiddlyhost/OU=Devel/CN=*.tiddlyhost.local"

# Generate the certificate
openssl x509 -req -sha256 -days 365 -in server.csr -signkey server.key -out server.crt

# Clean up
rm server.pass.key
rm server.csr

# Put the certs where we need them
# Use the file names that match the certs created by letsencrypt in prod
mkdir -p $TARGET_DIR
mv server.key $TARGET_DIR/privkey.pem
mv server.crt $TARGET_DIR/fullchain.pem

echo Created $TARGET_DIR/privkey.pem and $TARGET_DIR/fullchain.pem
