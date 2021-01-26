#!/bin/bash

export CONFIG=~/.config/nvim
git clone https://gist.github.com/alexaandru/9449a9d838c8632fad91ef35d4f6fd43 $CONFIG
cd $CONFIG

mkdir lua && ln config.lua lua/
mkdir -p pack/{colors,plugins,syntax}/{opt,start}; cd pack && git init

declare -A plugins=(
  ["plugins/opt/completion-nvim"]="https://github.com/nvim-lua/completion-nvim.git"
  ["plugins/opt/nvim-colorizer.lua"]="https://github.com/norcalli/nvim-colorizer.lua.git"
  ["plugins/opt/nvim-lspconfig"]="https://github.com/neovim/nvim-lspconfig.git"
  ["plugins/opt/nvim-treesitter"]="https://github.com/nvim-treesitter/nvim-treesitter.git"
  ["plugins/opt/vim-terraform"]="https://github.com/hashivim/vim-terraform.git"
  ["colors/opt/srcery-vim"]="https://github.com/srcery-colors/srcery-vim.git"
)

for path in "${!plugins[@]}"; do
  export url="${plugins[$path]}"
  git submodule add $url $path
done
