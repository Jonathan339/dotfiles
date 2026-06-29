local s = require('luasnip.nodes.snippet').S
local i = require('luasnip.nodes.insert').I
local fmta = require('luasnip.extras.fmt').fmta

return {
  s('log', fmta('console.log(<>)', { i(1) })),
  s('fn', fmta([[
function(<>) {
  <>
}
]], { i(1), i(2) })),
}
