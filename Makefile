# Makefile -- leanengineer notebook
# Governed by 00_COURSE/DEC-00_DECLARATION.txt, rule R-09.
#
#   make check    Format checks on every .txt file in the repository
#   make sources  Copy lecture transcripts into 99_LOCAL/ (local only)
#   make shot     Capture a video frame:  make shot V=<video id> T=<sec>
#   make deploy   check, then stage, commit, and push to GitHub
#
# "make deploy" is defined as exactly these four steps, in order:
#   1. make check       -- stop if any .txt file breaks the format rules
#   2. git add -A       -- stage everything not excluded by .gitignore
#   3. git commit       -- only if something is staged; message is MSG
#   4. git push -u origin main
# It never forces a push, rewrites history, or publishes 99_LOCAL/.

SHELL  := /bin/sh
REMOTE ?= origin
BRANCH ?= main
MSG    ?= notes: update $(shell date +%Y-%m-%d)
SRC    ?= $(HOME)/Downloads/SharedVM
LOCAL  := 99_LOCAL

.PHONY: help check sources shot deploy

help:
	@sed -n '2,15p' Makefile

check:
	@bad=$$(find . -name '*.txt' -not -path './.git/*' \
	    -not -path './$(LOCAL)/*' \
	    -exec awk 'length > 72 {print FILENAME": line "FNR}' {} +); \
	if [ -n "$$bad" ]; then \
	    echo "FAIL: lines longer than 72 columns:"; echo "$$bad"; exit 1; \
	fi
	@bad=$$(LC_ALL=C grep -rn '[^ -~]' --include='*.txt' \
	    --exclude-dir=.git --exclude-dir=$(LOCAL) . || true); \
	if [ -n "$$bad" ]; then \
	    echo "FAIL: non-ASCII characters or tabs:"; echo "$$bad"; exit 1; \
	fi
	@bad=$$(grep -rn ' $$' --include='*.txt' \
	    --exclude-dir=.git --exclude-dir=$(LOCAL) . || true); \
	if [ -n "$$bad" ]; then \
	    echo "FAIL: trailing spaces:"; echo "$$bad"; exit 1; \
	fi
	@echo "check: all .txt files are ASCII and within 72 columns."

sources:
	mkdir -p $(LOCAL)/transcripts
	cp -p "$(SRC)"/TylerJosephson-*.txt $(LOCAL)/transcripts/
	@ls $(LOCAL)/transcripts | sed 's/^/  /'

shot:
	@if [ -z "$(V)" ] || [ -z "$(T)" ]; then \
	    echo "usage: make shot V=<youtube video id> T=<seconds>"; exit 1; \
	fi
	@mkdir -p $(LOCAL)/frames
	@video=$$(ls "$(SRC)"/*_$(V).mp4 2>/dev/null | head -1); \
	if [ -z "$$video" ]; then \
	    echo "no video matching *_$(V).mp4 in $(SRC)"; exit 1; \
	fi; \
	out=$(LOCAL)/frames/$(V)_t$$(printf '%05d' $(T)).png; \
	ffmpeg -loglevel error -y -ss $(T) -i "$$video" -frames:v 1 "$$out" \
	    && echo "$$out   https://youtu.be/$(V)?t=$(T)"

deploy: check
	@echo "deploy: as $$(git config user.name) to $(REMOTE)/$(BRANCH)"
	git add -A
	@if git diff --cached --quiet; then \
	    echo "deploy: nothing new to commit."; \
	else \
	    git commit -q -m "$(MSG)" && git log --oneline -1; \
	fi
	git push -u $(REMOTE) $(BRANCH)
