# Neovim config

Requires `nightly`. The entry point is [init.fnl](plugin/init.fnl) (well, after a short stop at [init.vim](init.vim)).

Features:

- 100% ~~Lua~~ [Fennel](https://fennel-lang.org) based (well, technically, it's still Lua ;-)) using my own, "nano" [Fennel shim](https://github.com/alexaandru/fennel-nvim);
- **syntax highlighting** (as well as **code folding**, **incremental selection**, **text objects** & more)
  powered by latest [TreeSitter](https://github.com/nvim-treesitter/nvim-treesitter) (from `main` branch);
- **AI ready**: **Copilot** via LSP (`npm install --global @github/copilot-language-server`) + [inline completion](https://neovim.io/doc/user/lsp.html#lsp-inline_completion),
  [CodeCompanion](https://github.com/olimorris/codecompanion.nvim);
- builtin [LSP](https://neovim.io/doc/user/lsp.html) setup for a dozen languages, of which I mostly use **Go**,
  **JavaScript**, **Terraform** and **Fennel**; base configs copied from [nvim-lspconfig](https://github.com/neovim/nvim-lspconfig);
- multi **LSP** setup: always **Copilot** then (mostly) [EFM](https://github.com/mattn/efm-langserver)
  to cover for "gaps", where needed, i.e.: I use `tsserver` for **JS**, but prefer `prettier` for formatting;
  I use `gopls` for **Go**, but I also want warnings from `golangci-lint-ls`, etc.;
- **autoformat** wherever possible plus organize imports for **Go** and **JS**;
- builtin "fuzzy" searching (`set path=",**"` and just use `:find whatever<Tab>` for filenames or `:Grep *whatever*`
  (set to `git grep`) for content) but ALSO using [fzf-lua](https://github.com/ibhagwan/fzf-lua);
- **git** integration: only a custom visual diff, [gitsigns](https://github.com/lewis6991/gitsigns.nvim)
  and for the rest I just `:!git` away;
- terminal started via `:Term` or `<C-Enter>` will start in the folder of the current file;
- using the [builtin package manager](https://neovim.io/doc/user/pack.html#vim.pack);
- minimal UI (no statusbar/linenumber; git branch, filename and ~~function/method name~~ are in the titlebar),
  using [my own colorscheme](https://github.com/alexaandru/froggy) and my own input and select overrides;
- autocompletion via `Copilot` (inline) and `blink.cmp`.

![Nvim](nvim.png)

---

**KNOWN LIMITATIONS:** Currently it has an chicken-and-egg problem: in order to install the fennel-nvim
plugin, it must be able to parse the fennel code and in order to parse fennel code, fennel-nvim
must be installed... That plugin must be manually cloned somewhere on the `rtp` so that `init.vim` can
pick it up.
