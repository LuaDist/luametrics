-------------------------------------------------------------------------------
-- CommentParser - parser of Luadoc comments
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local lpeg = require 'lpeg'
local grammar = require 'leg.grammar'
local scanner = require 'leg.scanner'

module ('metrics.luadoc.commentParser', package.seeall)

-------------------------------------------------
-- Rules for LuaDoc comment parsing
-- @class table
-- @name luadoc_rules
luadoc_rules = {
	[1] = (1 - lpeg.P'---')^0 * lpeg.P'---' * (lpeg.P( 1- lpeg.V'Item')^0 * lpeg.C(lpeg.V'Item'))^0,
	Item = lpeg.P'-'^2 * lpeg.S' '^1 * lpeg.P'@' * lpeg.C(lpeg.V'ID') * lpeg.S' '^1 * lpeg.C((1 - lpeg.S'\n\r\t ')^1),
	ID = scanner.IDENTIFIER,
}

-------------------------------------------------
-- Captures for lpeg LuaDoc comment parsing
-- @class table
-- @name luadoc_captures
luadoc_captures = {
	Item = function(item, text)
		return {tag='item', item=item, text=text}
	end,
}

local pattern = lpeg.P(grammar.apply(luadoc_rules, nil, luadoc_captures)) / function (...) return {...} end

-------------------------------------------------
-- Function for LuaDoc comment parsing.
-- @class function
-- @name parse
function parse(text)
	local result = pattern:match(text)
	return result
end
