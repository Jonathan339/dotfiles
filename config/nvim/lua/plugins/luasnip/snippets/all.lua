local s = require('luasnip.nodes.snippet').S
local i = require('luasnip.nodes.insert').I
local fmta = require('luasnip.extras.fmt').fmta

return {
  -- JS/TS general
  s('clg', fmta('console.log(<>)', { i(1) })),
  s('fn', fmta([[
function <>(<>) {
  <>
}
]], { i(1, 'name'), i(2), i(3) })),
  s('afn', fmta([[
const <> = (<>) => {
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

  -- React hooks
  s('usest', fmta("const [<>, set<>] = useState(<>)", { i(1, 'state'), i(2, 'State'), i(3) })),
  s('useef', fmta([[
useEffect(() => {
  <>
}, [<>])
]], { i(1), i(2) })),
  s('usecb', fmta([[
const <> = useCallback((<>) => {
  <>
}, [<>])
]], { i(1, 'cb'), i(2), i(3), i(4) })),
  s('usem', fmta([[
const <> = useMemo(() => <>, [<>])
]], { i(1, 'val'), i(2), i(3) })),
  s('userf', fmta('const <> = useRef(<>)', { i(1, 'ref'), i(2) })),
  s('usecx', fmta('const <> = useContext(<>)', { i(1, 'value'), i(2, 'Context') })),

  -- React components
  s('rfc', fmta([[
export default function <>({ <> }) {
  return (
    <>
    </>
  )
}
]], { i(1, 'Component'), i(2), i(3) })),
  s('rafc', fmta([[
const <> = ({ <> }) => {
  return (
    <>
    </>
  )
}
]], { i(1, 'Component'), i(2), i(3) })),

  -- React event handlers
  s('onch', fmta([[
onChange={(<>) => <>}
]], { i(1, 'e'), i(2) })),
  s('oncl', fmta([[
onClick={(<>) => <>}
]], { i(1, 'e'), i(2) })),
}
