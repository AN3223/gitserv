build:
	docker build -t gitserv .

run:
	docker run -d --name gitserv --log-driver=syslog --restart=always \
		-v git:/git -v i2pd:/var/lib/i2pd \
		-v tor:/var/lib/tor -v ssh:/etc/ssh/ \
		--cpus=.25 --memory=300m \
		-p 8022:22 gitserv

sh:
	docker exec -ti gitserv /bin/sh

hostnames:
	@docker exec -ti gitserv cat /var/lib/tor/gitserv/hostname
	@docker exec -ti gitserv sh -c 'basename /var/lib/i2pd/destinations/*.0.dat | sed "s/\..*/.b32.i2p/"'

backup:
	docker run --rm --volumes-from gitserv \
		-v git:/data/git -v i2pd:/data/i2pd \
		-v tor:/data/tor -v ssh:/data/ssh \
		alpine \
		tar c -jhvf - /data/ > backup.tar.bz2

restore:
	docker run --rm --volumes-from gitserv \
		-v git:/data/git -v i2pd:/data/i2pd \
		-v tor:/data/tor -v ssh:/data/ssh \
		-v "$$PWD"/backup.tar.bz2:/backup.tar.bz2 \
		alpine \
		tar x --overwrite -vahf backup.tar.bz2

