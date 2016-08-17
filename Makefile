.DELETE_ON_ERROR:
.PHONY: FORCE
.SUFFIXES:

SHELL:=/bin/bash -o pipefail


#=> develop: install package in develop mode
#=> install: install package
.PHONY: develop install
develop install:
	python setup.py $@

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
