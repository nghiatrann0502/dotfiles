.PHONY: install update doctor repair unstow

install:
	./install.sh

update:
	./update.sh

doctor:
	./doctor.sh

repair:
	./repair-stow.sh

unstow:
	./uninstall.sh
