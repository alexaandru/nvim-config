set rtp=~/.lua,~/.config/nvim,~/.local/share/nvim/site,$VIMRUNTIME

"TODO: Disabled until https://github.com/neovim/neovim/issues/31165 is resolved
"lua vim.loader.enable()

packadd fennel-nvim
packadd cfilter
packadd nvim.difftool
packadd nvim.undotree
