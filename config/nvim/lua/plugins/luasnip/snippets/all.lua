return {
  s('log', fmta('console.log(<>)', { i(1) })),
  s('fn', fmta([[
function(<>) {
  <>
}
]], { i(1), i(2) })),
}
