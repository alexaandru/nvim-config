set rtp=~/.lua,~/.config/nvim,~/.local/share/nvim/site,$VIMRUNTIME

lua vim.loader.enable()

packadd fennel-nvim
packadd cfilter
packadd nvim.difftool
packadd nvim.undotree
