#!/bin/sh -e

if [ ! -d /var/www/.blog ]; then
	git clone --depth 1 file:///git/blog.git /var/www/.blog
else
	cd /var/www/.blog/
	git pull
fi

