set rtp=$XDG_CONFIG_HOME/nvim,$XDG_DATA_HOME/nvim/site,$VIMRUNTIME
set plf=$XDG_CONFIG_HOME/nvim/pack.json " must be set before vim.pack is 1st used

lua vim.loader.enable()

packadd fennel-nvim
packadd cfilter
packadd nvim.difftool
packadd nvim.undotree
