local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local fmta = require('luasnip.extras.fmt').fmta

return {
  s('clg', fmta('console.log(<>)', { i(1) })),
  s('fn', fmta([[
function <>(<>) {
  <>
}
]], { i(1, 'name'), i(2), i(3) })),
  s('afn', fmta([[
const <> = (<>) =>> {
  <>
}
]], { i(1, 'name'), i(2), i(3) })),
  s('imp', fmta("import <> from '<>'", { i(1, 'default'), i(2, 'module') })),
  s('imd', fmta("import { <> } from '<>'", { i(1), i(2, 'module') })),
  s('imr', fmta("import <> as <> from '<>'", { i(1, 'default'), i(2, 'name'), i(3, 'module') })),
  s('expd', fmta('export default <>', { i(1) })),
  s('edf', fmta([[
export default function <>(<>) {
  <>
}
]], { i(1, 'name'), i(2), i(3) })),
  s('tryc', fmta([[
try {
  <>
} catch (<>) {
  <>
}
]], { i(1), i(2, 'err'), i(3) })),
  s('rtrn', fmta('return <>', { i(1) })),
}
