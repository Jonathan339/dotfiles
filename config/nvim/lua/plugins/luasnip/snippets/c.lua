local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local f = ls.function_node
local t = ls.text_node
local fmta = require('luasnip.extras.fmt').fmta

local function guard_name(_, snip)
  local fname = snip.env.TM_FILENAME or vim.fn.bufname()
  local base = vim.fn.fnamemodify(fname, ':t:r')
  return base:upper() .. '_H'
end

return {
  s('#ifn', fmta([[
#ifndef <>
#define <>

<>
#endif
]], { f(guard_name, {}), f(guard_name, {}), i(1) })),
  s('#pragma', {
    t('#pragma once'),
  }),
}