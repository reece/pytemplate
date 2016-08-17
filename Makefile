# Makefile for Python project

.DELETE_ON_ERROR:
.PHONY: FORCE
.SUFFIXES:

SHELL:=/bin/bash -o pipefail
SELF:=$(firstword $(MAKEFILE_LIST))


############################################################################
#= BASIC USAGE
default: help

#=> help -- display this help message
help:
	@sbin/makefile-extract-documentation "${SELF}"

############################################################################
#= SETUP, INSTALLATION, PACKAGING

#=> develop: install package in develop mode
.PHONY: develop
develop: %:
	[ -f requirements.txt ] && pip install --upgrade -r requirements.txt || true
	python setup.py $*

#=> install: install package
#=> bdist bdist_egg bdist_wheel build build_sphinx install sdist
.PHONY: bdist bdist_egg bdist_wheel build build_sphinx install sdist
bdist bdist_egg bdist_wheel build build_sphinx install sdist: %:
	python setup.py $@

#=> docs -- make sphinx docs
.PHONY: docs
docs: setup changelog
	# RTD makes json. Build here to ensure that it works.
	make -C doc html json

# N.B. Although code is stored in github, I use hg and hg-git on the command line
#=> reformat: reformat code with yapf and commit
.PHONY: reformat
reformat:
	@if hg sum | grep -qL '^commit:.*modified'; then echo "Repository not clean" 1>&2; exit 1; fi
	@if hg sum | grep -qL ' applied'; then echo "Repository has applied patches" 1>&2; exit 1; fi
	yapf -i -r seqrepo tests
	hg commit -m "reformatted with yapf"

#=> test: execute tests
.PHONY: test
test:
	py.test tests

#=> tox: execute tests via tox
.PHONY: tox
tox:
	tox

#=> upload: upload to pypi
#=> upload_*: upload to named pypi service (requires config in ~/.pypirc)
.PHONY: upload upload_%
upload: upload_pypi
upload_%:
	python setup.py bdist_egg bdist_wheel sdist upload -r $*


#=> clean: remove temporary and backup files
.PHONY: clean
clean:
	find . \( -name \*~ -o -name \*.bak \) -print0 | xargs -0r rm

#=> cleaner: remove files and directories that are easily rebuilt
.PHONY: cleaner
cleaner: clean
	rm -fr *.egg-info build dist
	find . \( -name \*.pyc -o -name \*.orig \) -print0 | xargs -0r rm
	find . -name __pycache__ -print0 | xargs -0r rm -fr

#=> cleaner: remove files and directories that require more time/network fetches to rebuild
.PHONY: cleanest distclean
cleanest distclean: cleaner
	rm -fr .eggs .tox
