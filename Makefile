.PHONY: test lint docgen

test:
		nvim --headless --noplugin -u scripts/minimal_init.vim -c "PlenaryBustedDirectory tests/ { minimal_init = 'scripts/minimal_init.vim' }"

lint:
		luacheck lua/telescope

docgen:
		nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
