# tr, not sed 's#/##' — make reads the # as a comment and truncates the line.
SKILLS := $(shell ls -d */ 2>/dev/null | tr -d '/' | grep -vxE 'scripts|dist|server')
REPO := $(shell pwd)

.PHONY: check test dist clean link help

help:
	@echo "check  validate every SKILL.md against the strictest surface's rules"
	@echo "test   run the validator's own tests"
	@echo "dist   build dist/<skill>.zip for upload to claude.ai and ChatGPT"
	@echo "link   per-skill symlinks, only if a directory symlink is not followed"
	@echo "clean  remove dist/"

check:
	@python3 scripts/validate.py

test:
	@cd scripts && python3 -m unittest discover -p 'test_*.py'

dist: check
	@rm -rf dist && mkdir -p dist
	@for s in $(SKILLS); do \
		zip -qr "dist/$$s.zip" "$$s" -x '*.DS_Store' '*/__pycache__/*'; \
		echo "dist/$$s.zip"; \
	done

# Fallback for an agent that reads ~/.agents/skills or ~/.claude/skills but does
# not follow a symlinked directory. Point the variable at whichever one broke.
link:
	@test -n "$(DEST)" || { echo "usage: make link DEST=~/.claude/skills"; exit 1; }
	@mkdir -p $(DEST)
	@for s in $(SKILLS); do ln -sfn "$(REPO)/$$s" "$(DEST)/$$s"; done
	@ls -la $(DEST)

clean:
	@rm -rf dist
