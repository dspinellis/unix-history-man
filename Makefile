TREEMAN_FILES=386BSD-0.0 386BSD-0.1 386BSD-0.1-patchkit \
  BSD-4_3_Net_2 BSD-4_3_Reno BSD-4_4 BSD-4_4_Lite1 BSD-4_4_Lite2 FreeBSD-1.0 \
  FreeBSD-1.1 FreeBSD-1.1.5 FreeBSD-10.0.0 FreeBSD-10.1.0 FreeBSD-10.2.0 \
  FreeBSD-10.3.0 FreeBSD-11.0.0 FreeBSD-2.0 FreeBSD-2.0.5 FreeBSD-2.1.0 \
  FreeBSD-2.1.5 FreeBSD-2.1.6.1 FreeBSD-2.1.7 FreeBSD-2.2.0 FreeBSD-2.2.1 \
  FreeBSD-2.2.2 FreeBSD-2.2.5 FreeBSD-2.2.6 FreeBSD-2.2.7 FreeBSD-2.2.8 \
  FreeBSD-3.0.0 FreeBSD-3.1.0 FreeBSD-3.2.0 FreeBSD-3.3.0 FreeBSD-3.4.0 \
  FreeBSD-3.5.0 FreeBSD-4.0.0 FreeBSD-4.1.0 FreeBSD-4.1.1 FreeBSD-4.10.0 \
  FreeBSD-4.11.0 FreeBSD-4.2.0 FreeBSD-4.3.0 FreeBSD-4.4.0 FreeBSD-4.5.0 \
  FreeBSD-4.6.0 FreeBSD-4.6.1 FreeBSD-4.7.0 FreeBSD-4.8.0 FreeBSD-4.9.0 \
  FreeBSD-5.0.0 FreeBSD-5.1.0 FreeBSD-5.2.0 FreeBSD-5.3.0 FreeBSD-5.4.0 \
  FreeBSD-5.5.0 FreeBSD-6.0.0 FreeBSD-6.1.0 FreeBSD-6.2.0 FreeBSD-6.3.0 \
  FreeBSD-6.4.0 FreeBSD-7.0.0 FreeBSD-7.1.0 FreeBSD-7.2.0 FreeBSD-7.3.0 \
  FreeBSD-7.4.0 FreeBSD-8.0.0 FreeBSD-8.1.0 FreeBSD-8.2.0 FreeBSD-8.3.0 \
  FreeBSD-8.4.0 FreeBSD-9.0.0 FreeBSD-9.1.0 FreeBSD-9.2.0 FreeBSD-9.3.0

export SITEDIR=docs

all: $(SITEDIR)/index.html $(SITEDIR)/SlickGrid

$(SITEDIR)/index.html: $(TREEMAN_FILES) timeline timeline.pl
	mkdir -p $(SITEDIR)
	perl timeline.pl

$(TREEMAN_FILES): treeman.sh unix-history-repo
	./treeman.sh

unix-history-repo:
	git clone https://github.com/dspinellis/unix-history-repo
	cd $@ && git branch -r | grep -v '\->' | while read remote; do git branch --track "$${remote#origin/}" "$$remote"; done

timeline: timeline.sh unix-history-repo
	./timeline.sh

$(SITEDIR)/SlickGrid:
	mkdir -p $(SITEDIR)
	cd $(SITEDIR) && git clone -b 2.0-frozenRowsAndColumns \
		--depth=1 https://github.com/dspinellis/SlickGrid.git
