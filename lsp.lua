-- luacheck: globals vim
local util = require "util"
local keys = require"config.keys".lsp
local lsp = {
  -- lspconfig setup() arguments, as defined at
  -- https://github.com/neovim/nvim-lspconfig/blob/master/CONFIG.md
  cfg = {
    bashls = {},
    cssls = {},
    dockerls = {},
    efm = require "config.efm",
    gopls = require "config.gopls",
    html = {},
    jsonls = {},
    pyls = {},
    r_language_server = nil,
    solargraph = nil,
    sumneko_lua = require "config.sumneko",
    terraformls = require "config.tf",
    tsserver = require "config.tsserver",
    vimls = {},
    vuels = {},
    yamlls = {},
  },
}

local function set_keys()
  local ns = {noremap = true, silent = true}
  for c1, kx in pairs(keys) do
    for c2, key in pairs(kx) do
      local cmd = ("<Cmd>lua vim.lsp.%s.%s()<CR>"):format(c1, c2)
      vim.api.nvim_buf_set_keymap(0, "n", key, cmd, ns)
    end
  end
end

local function set_highlight()
  util.au {
    Highlight = {
      "CursorHold <buffer> lua vim.lsp.buf.document_highlight()",
      "CursorHoldI <buffer> lua vim.lsp.buf.document_highlight()",
      "CursorMoved <buffer> lua vim.lsp.buf.clear_references()",
    },
  }
end

local function can_format(opts)
  for _, v in ipairs(opts) do if v.formatCommand then return true end end
  return false
end

function lsp.on_attach(client, bufnr)
  local set_hook = function(hook, ok)
    util.save_hooks[bufnr] = util.save_hooks[bufnr] or {}
    util.save_hooks[bufnr][hook] = util.save_hooks[bufnr][hook] or ok or nil
  end

  local Format = function(ok)
    set_hook("Format", ok)
  end

  local OrgImports = function(ok)
    set_hook("OrgImports", ok)
  end

  local rc = client.resolved_capabilities
  local ca = rc.code_action

  set_keys()
  if rc.document_highlight then set_highlight() end

  if client.name == "efm" then
    local ft = vim.fn.getbufvar(bufnr, "&filetype")
    rc.document_formatting = can_format(lsp.cfg.efm.settings.languages[ft])
  end

  Format(rc.document_formatting)
  OrgImports(ca and (type(ca) == "boolean" or ca.codeActionKinds
                 and vim.tbl_contains(ca.codeActionKinds, "source.organizeImports")))
end

function lsp.setup(diagnostics)
  vim.cmd "aug LSP | au!"
  local lspc = require "lspconfig"
  for k, v in pairs(lsp.cfg) do
    lspc[k].setup(vim.tbl_extend("keep", v, {on_attach = lsp.on_attach}))
  end
  vim.cmd "aug END"

  local opd = vim.lsp.diagnostic.on_publish_diagnostics
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(opd, diagnostics)

  vim.cmd("aug Format | au! | aug END")
  vim.cmd("au Format BufWritePre * lua BufWritePre()")
end

return lsp
