install:
	mkdir -p $HOME/bin $HOME/.etc
	install -m 750 build.sh $HOME/bin
	[ ! -f $HOME/.etc/build.conf ] && \
		install -m 600 build.conf $HOME/.etc/ || /bin/true
	[ ! -f $HOME/.etc/smtp.conf ] && \
		install -m 600 smtp.conf $HOME/.etc/ || /bin/true
