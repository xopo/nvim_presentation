.PHONY: test lint docgen

test:
	nvim --headless --noplugin -u scripts/minimal_init.vim -c "<cmd>PlenaryBustedDirectory tests/ { minimal_init = '' }<CR>"

lint:
		luacheck lua/telescope

docgen:
		nvim --headless --noplugin -u scripts/minimal_init.vim -c "luafile ./scripts/gendocs.lua" -c 'qa'
