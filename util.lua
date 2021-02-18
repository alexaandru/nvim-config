local util = {}

local function nno(key, cmd)
  cmd = ("<Cmd>lua vim.lsp.%s()<CR>"):format(cmd)
  vim.api.nvim_buf_set_keymap(0, "n", key, cmd, {noremap = true, silent = true})
end

local function each(cmd, ...)
  local args = vim.tbl_flatten({...})
  for _, v in ipairs(args) do vim.cmd(cmd .. " " .. v) end
end

-- Synchronously organise imports, courtesy of
-- https://github.com/neovim/nvim-lspconfig/issues/115#issuecomment-656372575 and
-- https://github.com/lucax88x/configs/blob/master/dotfiles/.config/nvim/lua/lt/lsp/functions.lua
function util.OrgImports(ms)
  local params = vim.lsp.util.make_range_params()
  params.context = {source = {organizeImports = true}}
  local result = vim.lsp.buf_request_sync(0, "textDocument/codeAction", params, ms or 1000)
  for _, res in pairs(result or {}) do
    for _, r in pairs(res.result or {}) do
      if r.edit then
        vim.lsp.util.apply_workspace_edit(r.edit)
      else
        vim.lsp.buf.execute_command(r.command)
      end
    end
  end
end

-- inspired by https://vim.fandom.com/wiki/Smart_mapping_for_tab_completion
function util.SmartTabComplete()
  local T = function(str)
    return vim.api.nvim_replace_termcodes(str, true, true, true)
  end
  local s = vim.fn.getline("."):sub(1, vim.fn.col(".") - 1):gsub("%s+", "")

  if s == "" then return T "<Tab>" end
  if s:sub(s:len(), s:len()) == "/" then return T "<C-x><C-f>" end

  return T "<C-x><C-o>"
end

function util.GitStatus()
  local branch = vim.trim(vim.fn.system("git rev-parse --abbrev-ref HEAD 2> /dev/null"))
  if branch == "" then return end
  local dirty = vim.fn.system("git diff --quiet || echo -n \\*")
                    .. vim.fn.system("git diff --cached --quiet || echo -n \\+")
  vim.w.git_status = branch .. dirty
end

function util.ProjRelativePath()
  return string.sub(vim.fn.expand("%:p"), #vim.w.proj_root + 1)
end

function util.LspCapabilities()
  local cap = {}
  for _, c in pairs(vim.lsp.buf_get_clients()) do cap[c.name] = c.resolved_capabilities end
  print(vim.inspect(cap))
end

function util.unpack(...)
  local arg = vim.tbl_flatten {...}
  local what = {}
  for _, v in ipairs(arg) do table.insert(what, util[v]) end
  return unpack(what)
end

function util.on_attacher(async)
  local keys = require"config.keys".lsp
  local fmt_cmd = "vim.lsp.buf.formatting" .. (async and "" or "_sync") .. "()"

  return function(client, bufnr)
    for c1, kx in pairs(keys) do --
      for c2, k in pairs(kx) do nno(k, c1 .. "." .. c2) end
    end

    local okFmt = client.name ~= "efm"
                      or (vim.fn.getbufvar(bufnr, "&filetype") ~= "go"
                          and vim.fn.getbufvar(bufnr, "&filetype") ~= "tf")
    local orgImp = client.resolved_capabilities.code_action
                       and (type(client.resolved_capabilities.code_action) == "boolean"
                           or client.resolved_capabilities.code_action.codeActionKinds
                           and vim.tbl_contains(client.resolved_capabilities.code_action
                                                    .codeActionKinds, "source.organizeImports"))
    local au = {
      ["require'util'.OrgImports()"] = orgImp or nil,
      [fmt_cmd] = okFmt and client.resolved_capabilities.document_formatting or nil,
    }

    if vim.tbl_isempty(au) then return end

    vim.cmd(("au Setup BufWritePre <buffer> lua %s"):format(table.concat(vim.tbl_keys(au), "; ")))
  end
end

function util.lsp_setup(cfg)
  local lsp = require "lspconfig"
  for k, v in pairs(cfg.lsp) do
    v = type(v) == "table" and v or require(v)
    lsp[k].setup(vim.tbl_extend("keep", v, {on_attach = util.on_attacher()}))
  end

  local opd = vim.lsp.diagnostic.on_publish_diagnostics
  vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(opd, cfg.diagnostics)
end

function util.configs(pat)
  pat = pat or "*.lua"
  local c = vim.fn.stdpath("config")
  local x = function(v)
    return string.sub(v, #c + 2)
  end

  return vim.tbl_map(x, vim.fn.glob(c .. "/" .. pat, 0, 1))
end

function util.pa(...)
  each("pa", ...)
end

function util.set(...)
  each("set", ...)
end

-- TODO: watch https://github.com/neovim/neovim/issues/9876
function util.hi(...)
  each("hi!", ...)
end

-- TODO: watch hi ^^^
function util.sig(...)
  each("sig define", ...)
end

function util.so(s)
  vim.cmd(("so %s/%s"):format(vim.fn.stdpath("config"), s))
end

function util.colo(c)
  vim.cmd("colo " .. c)
end

-- TODO: watch https://github.com/neovim/neovim/pull/11613
function util.com(...)
  each("com!", ...)
end

-- TODO: watch https://github.com/neovim/neovim/pull/12378
function util.au(...)
  for name, au in pairs(...) do
    vim.cmd(("aug %s | au! | END"):format(name))
    each(("au %s "):format(name), unpack(au))
  end
end

function util.kmap(mappings)
  for mode, mx in pairs(mappings) do
    for _, m in ipairs(mx) do
      local lhs, rhs, opts = unpack(m)
      opts = opts or {}
      opts.noremap = true
      vim.api.nvim_set_keymap(mode, lhs, rhs, opts)
    end
  end
end

function util.disable_provider(p)
  vim.g["loaded_" .. p .. "_provider"] = 0
end

function util.exec(cmd, ret)
  ret = ret ~= nil and ret
  vim.api.nvim_exec(cmd, ret)
end

return util
