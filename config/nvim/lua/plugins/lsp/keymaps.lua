-- lua/plugins/lsp/keymaps.lua
-- Keymaps LSP por buffer, inspirados en craftzdog/nvim pero adaptados a
-- Telescope/Trouble (esta config no usa Snacks). Se registran en LspAttach
-- para no ensuciar buffers sin servidor.
local M = {}

local function map(bufnr, mode, lhs, rhs, desc)
  vim.keymap.set(mode, lhs, rhs, {
    buffer = bufnr,
    silent = true,
    noremap = true,
    desc = desc,
  })
end

-- Picker de Telescope con fallback a la función nativa de LSP. Así los
-- keymaps siguen funcionando aunque Telescope todavía no se haya cargado.
local function telescope(picker, fallback)
  return function()
    local ok, builtin = pcall(require, 'telescope.builtin')
    if ok then
      builtin[picker]()
    else
      fallback()
    end
  end
end

-- vtsls: ir a la definición real del source en vez de al .d.ts.
-- Si el buffer no lo atiende vtsls, cae a implementación.
local function source_definition(bufnr)
  local clients = vim.lsp.get_clients({ bufnr = bufnr, name = 'vtsls' })
  if #clients == 0 then
    vim.lsp.buf.implementation()
    return
  end

  local params = vim.lsp.util.make_position_params(0, 'utf-16')
  clients[1]:request('workspace/executeCommand', {
    command = 'typescript.goToSourceDefinition',
    arguments = { params.textDocument.uri, params.position },
  }, function(err, result)
    if err then
      vim.notify('goToSourceDefinition: ' .. err.message, vim.log.levels.ERROR)
      return
    end
    if result and #result > 0 then
      vim.lsp.util.show_document(result[1], 'utf-16', { focus = true })
    else
      vim.notify('Sin source definition', vim.log.levels.INFO)
    end
  end, bufnr)
end

function M.attach(_, bufnr)
  -- Navegación con pickers
  map(bufnr, 'n', 'gd', telescope('lsp_definitions', vim.lsp.buf.definition), 'LSP: definición')
  map(bufnr, 'n', 'gD', telescope('lsp_declarations', vim.lsp.buf.declaration), 'LSP: declaración')
  map(bufnr, 'n', 'gy', telescope('lsp_type_definitions', vim.lsp.buf.type_definition), 'LSP: tipo')
  map(bufnr, 'n', 'gri', telescope('lsp_implementations', vim.lsp.buf.implementation), 'LSP: implementaciones')
  map(bufnr, 'n', 'grr', telescope('lsp_references', vim.lsp.buf.references), 'LSP: referencias')

  -- Acciones
  map(bufnr, { 'n', 'x' }, 'gra', vim.lsp.buf.code_action, 'LSP: code action')
  map(bufnr, 'n', 'grn', vim.lsp.buf.rename, 'LSP: renombrar símbolo')
  map(bufnr, 'n', 'K', vim.lsp.buf.hover, 'LSP: hover')
  map(bufnr, 'n', 'gK', vim.lsp.buf.signature_help, 'LSP: firma')
  -- En insert mode Neovim 0.12 ya mapea <C-s> a signature_help. No tocamos
  -- <C-k>/<C-j> porque LuaSnip los usa para saltar snippets.
  map(bufnr, 'n', 'gI', function()
    source_definition(bufnr)
  end, 'LSP: source definition / implementación')

  -- Diagnósticos
  map(bufnr, 'n', ']d', function()
    vim.diagnostic.jump({ count = 1, float = true })
  end, 'Diagnóstico siguiente')
  map(bufnr, 'n', '[d', function()
    vim.diagnostic.jump({ count = -1, float = true })
  end, 'Diagnóstico anterior')
end

function M.setup()
  vim.api.nvim_create_autocmd('LspAttach', {
    group = vim.api.nvim_create_augroup('lsp_keymaps', { clear = true }),
    callback = M.attach,
  })
end

return M
