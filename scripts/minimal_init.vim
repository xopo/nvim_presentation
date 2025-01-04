set rtp+=.
set rtp+=../plenary.nvim/
function! PluginLoaded()
  echo "Minimal init is loaded"
endfunction
autocmd VimEnter * call PluginLoaded()
runtime! plugin/plenary.vim
runtime! plugin/load_present.lua
