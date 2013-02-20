-------------------------------------------------------------------------------
-- Captures for LuaDoc - parsing and matching of LuaDoc comments
-- @release 11.3.2011, Ivan Simko
-------------------------------------------------------------------------------

local commentParser = require 'metrics.luadoc.commentParser'
local utils = require 'metrics.utils'

local io, table, pairs, type, print = io, table, pairs, type, print 

module ('metrics.luadoc.captures')


local stack_functions							-- zoznam funkcii (tabulka dictionary) ktora je neskor vratena
local stack_tables
local funcs = {}
local tabs = {}

--
-- process LuaDoc functions - checks for commented functions
local function processFunction(comment, funcAST) 
	local name = nil
	
	if (funcAST.name) then
		name = funcAST.name
	else
		return
	end

	local result = commentParser.parse(comment)

	if (result) then
		for k,v in pairs(result) do
			if (v.item == 'name') then 
				name = v.text
				break
			end
		end
		
	end				
	
	local block = nil
			
	for k, v in pairs(funcAST.data) do
		if (v.tag == 'FuncBody') then
			for i,j in pairs(v.data) do
				if (j.tag == 'Block') then
					block = j
					break
				end
			end
			break
		end
	end
	
	funcAST.metrics.blockdata 				= {}
	funcAST.metrics.blockdata.locals 		= block.metrics.blockdata.locals
	funcAST.metrics.blockdata.locals_total 	= block.metrics.blockdata.locals_total
	funcAST.metrics.blockdata.remotes 		= block.metrics.blockdata.remotes
	funcAST.metrics.blockdata.read_upvalue 	= block.metrics.blockdata.read_upvalue
	funcAST.metrics.blockdata.write_upvalue = block.metrics.blockdata.write_upvalue
	funcAST.metrics.blockdata.execs 		= block.metrics.blockdata.execs
	
	if name then stack_functions[name] = funcAST end
end

--
-- process LuaDoc assigns (tables) - checks for commented tables
local function processAssign(comment, assignAST)	
	
	if (assignAST.tag ~= 'LocalAssign' and  assignAST.tag ~= 'Assign') then
		return
	end
	
	-- parse luadoc comment
	local result = commentParser.parse(comment)

	local ldoc_class = nil
	local ldoc_name = nil

	if (result) then
		for k,v in pairs(result) do
			if (v.item == 'name') then
				ldoc_name = v.text
			end
			if (v.item == 'class') then
				ldoc_class = v.text
			end
		end
	end	
		
	if ldoc_class == 'table' and ldoc_name ~= nil then
		local namelist = nil
		local explist = nil
		
		for k,v in pairs(assignAST.data) do
			if (v.tag) == 'NameList' or (v.tag == 'VarList') then namelist = v end
			if (v.tag) == 'ExpList' then explist = v end
		end			
				
		for k,v in pairs(namelist.data) do 			-- compare namelist ane explist values ... create resulting table
			if (v.text == ldoc_name) then
				stack_tables[v.text] = explist.data[k]
				break
			end
		end
	end		
end

--------------------------------------------
-- Captures table for lpeg parsing - creates tables of LuaDoc style commented functions and tables
-- @class table
-- @name captures
captures = {
	[1] = function(data)
		stack_functions = {}
		stack_tables = {}
		
		local k, fun, tab
		
		
		for k,fun in pairs(data.metrics.functionDefinitions) do
			local searchNode = fun
			if (fun.assignNode) then searchNode=fun.assignNode end
			local comment = utils.getComment(searchNode)
			if (comment) then processFunction(comment, fun)	end	
		end
		
		for k,tab in pairs(tabs) do
			local comment = utils.getComment(tab)
			if (comment) then processAssign(comment, tab)	end	
		end
		
		-- made work dith current luadoc taglet
		funcs = {}
		tabs = {}		
		
		data.luaDoc_functions = stack_functions 
		data.luaDoc_tables = stack_tables
		
		return data
	end,
	LocalAssign = function(data)
		table.insert(tabs, data)
		return data
	end,
	Assign = function(data)
		table.insert(tabs, data)
		return data
	end,
}
