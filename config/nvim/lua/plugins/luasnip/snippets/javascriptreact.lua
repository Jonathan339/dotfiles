local ls = require('luasnip')
local s = ls.snippet
local i = ls.insert_node
local t = ls.text_node
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
  s('rfc', {
    t({"export default function "}),
    i(1, 'Component'),
    t({"({ "}),
    i(2),
    t({" }) {",
      "  return (",
      "    "}),
    i(3),
    t({"",
      "    </>",
      "  )",
      "}"}),
  }),
  s('rafc', {
    t({"const "}),
    i(1, 'Component'),
    t({" = ({ "}),
    i(2),
    t({" }) => {",
      "  return (",
      "    "}),
    i(3),
    t({"",
      "    </>",
      "  )",
      "}"}),
  }),
  s('onch', fmta([[
onChange={(<>) => <>}
]], { i(1, 'e'), i(2) })),
  s('oncl', fmta([[
onClick={(<>) => <>}
]], { i(1, 'e'), i(2) })),
}
