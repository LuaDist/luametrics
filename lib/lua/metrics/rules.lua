-------------------------------------------------------------------------------
-- Metrics grammar rules - Rules for Lua language parser
-- @release 2010/05/04 02:45:00, Gabriel Duchon in LuaDocumentator
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------


local lpeg = require 'lpeg'
local scanner = require 'leg.scanner'
local parser = require 'leg.parser'

module('metrics.rules')

-- catch matched string's position, text and all nested captures values
local function Cp(...)
	return lpeg.Cp() * lpeg.C(...)
end

-------------------
-- Table containing slightly adjusted rules for source code parsing
-- @class table
-- @name rules
rules = {
	  IGNORED = Cp((lpeg.V('SPACE') + lpeg.V('NEWLINE') + lpeg.V('COMMENT'))^0 ) -- for easier calculation of lines for code
	, EPSILON = Cp(parser.rules.EPSILON)
	, EOF = Cp(parser.rules.EOF)
	, BOF = Cp(parser.rules.BOF)
	, NUMBER = Cp(parser.rules.NUMBER)
	, ID = Cp(parser.rules.ID)
	, STRING = Cp(parser.rules.STRING)
	, Name = Cp(parser.rules.Name)

-- CHUNKS
	, [1] = Cp(lpeg.V("CHUNK"))
	, CHUNK= Cp(parser.rules.CHUNK)
	, Chunk= Cp(parser.rules.Chunk)
	, Block= Cp(parser.rules.Block)

-- STATEMENTS
	, Stat = Cp(parser.rules.Stat)
	, Assign = Cp(parser.rules.Assign) 
	, Do = Cp(parser.rules.Do)
	, While = Cp(parser.rules.While)
	, Repeat = Cp(parser.rules.Repeat)
	, If = Cp(parser.rules.If)
	, NumericFor = Cp(parser.rules.NumericFor)
	, GenericFor = Cp(parser.rules.GenericFor)
	, GlobalFunction = Cp(parser.rules.GlobalFunction)
	, LocalFunction = Cp(parser.rules.LocalFunction)
	, LocalAssign = Cp(parser.rules.LocalAssign) 
	, LastStat = Cp(parser.rules.LastStat)
  
-- LISTS
	, VarList = Cp(parser.rules.VarList)
	, NameList = Cp(parser.rules.NameList)
	, ExpList = Cp(parser.rules.ExpList)
  
-- EXPRESSIONS
	, Exp = Cp(parser.rules.Exp)
	, _SimpleExp = Cp(parser.rules._SimpleExp)
	, _PrefixExp = Cp(parser.rules._PrefixExp)
	, _PrefixExpParens = Cp(parser.rules._PrefixExpParens)
	, _PrefixExpSquare = Cp(parser.rules._PrefixExpSquare)
	, _PrefixExpDot = Cp(parser.rules._PrefixExpDot)
	, _PrefixExpArgs = Cp(parser.rules._PrefixExpArgs)
	, _PrefixExpColon = Cp(parser.rules._PrefixExpColon)

-- solving the left recursion problem
	, Var = Cp(parser.rules.Var)
	, FunctionCall = Cp(parser.rules.FunctionCall)

-- FUNCTIONS
	, Function = Cp(parser.rules.Function)
	, FuncBody = Cp(parser.rules.FuncBody)
	, FuncName = Cp(parser.rules.FuncName)
	, Args = Cp(parser.rules.Args)
	, ParList = Cp(parser.rules.ParList)

-- TABLES
	, TableConstructor = Cp(parser.rules.TableConstructor)
	, FieldList = Cp(parser.rules.FieldList)
	, Field = Cp(parser.rules.Field)
	, _FieldSquare = Cp(parser.rules._FieldSquare)
	, _FieldID = Cp(parser.rules._FieldID)
	, _FieldExp = Cp(parser.rules._FieldExp)
	, FieldSep = Cp(parser.rules.FieldSep)

-- OPERATORS
	-- Leg bug --> matches '>' before '>=' ... this reverses the order
	, BinOp    = Cp(lpeg.V'+'   + lpeg.V'-'  + lpeg.V'*' + lpeg.V'/'  + lpeg.V'^'  + lpeg.V'%'  
             + lpeg.V'..'  + lpeg.V'~=' + lpeg.V'>=' + lpeg.V'==' + lpeg.V'<=' + lpeg.V'<'  +  lpeg.V'>' 
             + lpeg.V'AND' + lpeg.V'OR')
	, UnOp = Cp(parser.rules.UnOp)
  
-- KEYWORDS
	, FALSE = Cp(parser.rules.FALSE)
	, TRUE = Cp(parser.rules.TRUE)
	, NIL = Cp(parser.rules.NIL)

	, AND = Cp(parser.rules.AND)
	, NOT = Cp(parser.rules.NOT)
	, OR = Cp(parser.rules.OR)

	, DO = Cp(parser.rules.DO)
	, IF = Cp(parser.rules.IF)
	, THEN = Cp(parser.rules.THEN)
	, ELSE = Cp(parser.rules.ELSE)
	, ELSEIF = Cp(parser.rules.ELSEIF)
	, END = Cp(parser.rules.END)

	, FOR = Cp(parser.rules.FOR)
	, IN = Cp(parser.rules.IN)
	, UNTIL = Cp(parser.rules.UNTIL)
	, WHILE = Cp(parser.rules.WHILE)
	, REPEAT = Cp(parser.rules.REPEAT)
	, BREAK = Cp(parser.rules.BREAK)

	, LOCAL = Cp(parser.rules.LOCAL)
	, FUNCTION = Cp(parser.rules.FUNCTION)
	, RETURN = Cp(parser.rules.RETURN)

-- WHITESPACE
	, COMMENT =  Cp(scanner.COMMENT)
	, SPACE = Cp(lpeg.S(' \t\f'))
	, NEWLINE = Cp(lpeg.S('\n\r' ))
  
-- SYMBOLS
	, ['+'] = Cp('+')
	, ['-'] = Cp('-')
	, ['*'] = Cp('*')
	, ['/'] = Cp('/')
	, ['%'] = Cp('%')
	, ['^'] = Cp('^')
	, ['#'] = Cp('#')
	, ['=='] = Cp('==')
	, ['~='] = Cp('~=')
	, ['<='] = Cp('<=')
	, ['>='] = Cp('>=')
	, ['<'] = Cp('<')
	, ['>'] = Cp('>')
	, ['='] = Cp('=')
	, ['('] = Cp('(')
	, [')'] = Cp(')')
	, ['{'] = Cp('{')
	, ['}'] = Cp('}')
	, ['['] = Cp('[')
	, [']'] = Cp(']')
	, [';'] = Cp(';')
	, [':'] = Cp(':')
	, [','] = Cp(',')
	, ['.'] = Cp('.')
	, ['..'] = Cp('..')
	, ['...'] = Cp('...')
}
