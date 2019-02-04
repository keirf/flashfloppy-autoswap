SUBDIRS := atlantis bass monkey1 monkey2

.PHONY: all write clean $(SUBDIRS)
all: $(SUBDIRS)

$(SUBDIRS):
	$(MAKE) -C $@ all

write:
	@set -e; for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir write; \
	done

clean:
	@set -e; for subdir in $(SUBDIRS); do \
		$(MAKE) -C $$subdir clean; \
	done

dist:
	$(MAKE) clean
	$(MAKE) all
	rm -rf AutoSwap*
	mkdir -p AutoSwap
	@set -e; for subdir in $(SUBDIRS); do \
		cp $$subdir/*FFAS*zip AutoSwap/.; \
	done
	zip -r AutoSwap.zip AutoSwap
