local s = require('luasnip.nodes.snippet').S
local i = require('luasnip.nodes.insert').I
local fmta = require('luasnip.extras.fmt').fmta

return {
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
  s('onch', fmta([[
onChange={(<>) => <>}
]], { i(1, 'e'), i(2) })),
  s('oncl', fmta([[
onClick={(<>) => <>}
]], { i(1, 'e'), i(2) })),
}
