-- lua/plugins/lualine/init.lua
---@diagnostic disable: undefined-global
local colors = {
  bg = '#202328',
  fg = '#bbc2cf',
  yellow = '#ECBE7B',
  cyan = '#008080',
  darkblue = '#081633',
  green = '#98be65',
  orange = '#FF8800',
  violet = '#a9a1e1',
  magenta = '#c678dd',
  blue = '#51afef',
  red = '#ec5f67',
}

local conditions = {
  buffer_not_empty = function()
    return vim.fn.empty(vim.fn.expand('%:t')) ~= 1
  end,
  hide_in_width = function()
    return vim.fn.winwidth(0) > 80
  end,
}

-- helpers
local function lsp_status()
  if not vim.lsp or not vim.lsp.get_clients then
    return ''
  end
  local clients = vim.lsp.get_clients({ bufnr = 0 })
  if not clients or vim.tbl_isempty(clients) then
    return ''
  end
  local names = {}
  for _, c in ipairs(clients) do
    table.insert(names, c.name)
  end
  return '  ' .. table.concat(names, ',')
end

local function recording_status()
  local reg = vim.fn.reg_recording()
  if reg == '' then
    return ''
  end
  return ' ' .. reg
end

local noice_api = nil
local function noice_mode()
  if noice_api == nil then
    local ok, api = pcall(require, 'noice')
    noice_api = ok and api or false
  end
  if not noice_api or not noice_api.status.mode.has() then
    return ''
  end
  return noice_api.status.mode.get()
end

local config = {
  options = {
    icons_enabled = true,
    globalstatus = true,
    component_separators = '',
    section_separators = '',
    theme = {
      normal = { c = { fg = colors.fg, bg = colors.bg } },
      inactive = { c = { fg = colors.fg, bg = colors.bg } },
    },
  },
  sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
  inactive_sections = {
    lualine_a = {},
    lualine_b = {},
    lualine_c = {},
    lualine_x = {},
    lualine_y = {},
    lualine_z = {},
  },
}

local function ins_left(component)
  table.insert(config.sections.lualine_c, component)
end
local function ins_right(component)
  table.insert(config.sections.lualine_x, component)
end

-- left
ins_left({
  function()
    return '▊'
  end,
  color = { fg = colors.blue },
  padding = { left = 0, right = 1 },
})

ins_left({
  function()
    return ''
  end,
  color = function()
    local mode_color = {
      n = colors.red,
      i = colors.green,
      v = colors.blue,
      [''] = colors.blue,
      V = colors.blue,
      c = colors.magenta,
      no = colors.red,
      s = colors.orange,
      S = colors.orange,
      [''] = colors.orange,
      ic = colors.yellow,
      R = colors.violet,
      Rv = colors.violet,
      cv = colors.red,
      ce = colors.red,
      r = colors.cyan,
      rm = colors.cyan,
      ['r?'] = colors.cyan,
      ['!'] = colors.red,
      t = colors.red,
    }
    return { fg = mode_color[vim.fn.mode()] or colors.cyan }
  end,
  padding = { right = 1 },
})

ins_left({ 'filesize', cond = conditions.buffer_not_empty })
ins_left({ 'filename', cond = conditions.buffer_not_empty, color = { fg = colors.magenta, gui = 'bold' } })
ins_left({ 'location' })
ins_left({ 'progress', color = { fg = colors.fg, gui = 'bold' } })

ins_left({
  'diagnostics',
  sources = { 'nvim_diagnostic' },
  symbols = { error = ' ', warn = ' ', info = ' ', hint = ' ' },
  diagnostics_color = {
    color_error = { fg = colors.red },
    color_warn = { fg = colors.yellow },
    color_info = { fg = colors.cyan },
    color_hint = { fg = colors.green },
  },
})

ins_left({
  function()
    return '%='
  end,
}) -- center separator

-- right
ins_right({
  function()
    return vim.bo.filetype
  end,
  icon = '',
  cond = conditions.buffer_not_empty,
  color = { fg = colors.violet, gui = 'bold' },
})

ins_right({
  function()
    return (vim.o.fileencoding or ''):upper()
  end,
  cond = function()
    return (vim.o.fileencoding or 'utf-8'):lower() ~= 'utf-8' and conditions.hide_in_width()
  end,
  color = { fg = colors.green, gui = 'bold' },
})

ins_right({
  function()
    return (vim.o.fileformat or ''):upper()
  end,
  cond = function()
    return (vim.o.fileformat or 'unix'):lower() ~= 'unix' and conditions.hide_in_width()
  end,
  color = { fg = colors.green, gui = 'bold' },
})

ins_right({ 'branch', icon = '', color = { fg = colors.violet, gui = 'bold' } })

ins_right({
  'diff',
  symbols = { added = ' ', modified = '󰝤 ', removed = ' ' },
  diff_color = {
    added = { fg = colors.green },
    modified = { fg = colors.orange },
    removed = { fg = colors.red },
  },
  cond = conditions.hide_in_width,
})

ins_right({ lsp_status, cond = conditions.hide_in_width, color = { fg = colors.cyan } })
ins_right({
  noice_mode,
  cond = function()
    return noice_api and noice_api.status.mode.has() or false
  end,
  color = { fg = colors.yellow },
})
ins_right({
  recording_status,
  cond = function()
    return vim.fn.reg_recording() ~= ''
  end,
  color = { fg = colors.orange },
})
ins_right({
  function()
    return '▊'
  end,
  color = { fg = colors.blue },
  padding = { left = 1 },
})

return {
  'nvim-lualine/lualine.nvim',
  lazy = false, -- ← cargar siempre
  dependencies = { 'nvim-tree/nvim-web-devicons' },
  config = function()
    -- fuerza globalstatus por si tu Neovim/tema no lo setea solo
    pcall(function()
      vim.o.laststatus = 3
    end)
    pcall(function()
      vim.o.showmode = false
    end)
    require('lualine').setup(config)
  end,
}
