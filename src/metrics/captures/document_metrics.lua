-------------------------------------------------------------------------------
-- Metrics captures - Metrics of custom comments, table constructors, extends function definitions table with anonymous an table-field functions.
-- Creates list(table) of tables created in file.
-- @release 2013/04/04, Peter Kosa
--TODO reorganize(refactor) this code, part of this code logicaly belongs to module metrics.captures.block ( or don't ? )
-------------------------------------------------------------------------------


local utils = require 'metrics.utils'
local comments = require 'comments'

local io, table, pairs,ipairs, type, print,next,string,error,tostring = io, table, pairs,ipairs, type, print ,next,string,error,tostring

module('metrics.captures.document_metrics')


local tableConstructorCount=0
local docutables={}
local TODOs = {}
local BUGs = {}
local QUESTIONs = {} 
local FIXMEs={}
local HOWs={}
local INFOs={}

---
--% Recursive search for name of table-field functions/tables.
--@ ast node in ast
--: (string|nil) Returns the name of field or nil
local function searchFieldID(ast)
	local res=nil
	if type(ast.data) == "table"  then
		if(ast.key=="ID" and ast.parent.tag=="_FieldID")then
		 	return ast.text 
		end
		for _,v in ipairs(ast.data) do
			res  = searchFieldID(v)
			if(res)then
				return res
			end
		end
	end
end

---
-- Recursive search for anonymous and table-field functions/tables.
-- Inserts node to the global metrics table to the proper table (docutables/functionDefinitions)
-- @param data Current sub-AST node
-- @param AST the whole AST
local function travers(data,AST)
	if type(data.data) == "table" and #data.data > 0 then
		for _,v in ipairs(data.data) do
			travers(v,AST)
		end
	
		if data.key == "Function" then

			local name
			if(data.isGlobal==nil)then

				local whatisthis= data.parent.parent.parent
				if(whatisthis.tag=="_FieldID")then	
					name=searchFieldID(whatisthis)
				end
				data.isGlobal=nil
				if(name)then
					data.name=name 
					data.fcntype="table-field"				
				else 
					data.name="#anonymous#"
					data.fcntype="anonymous"
				end
				table.insert(AST.metrics.functionDefinitions,data)
			end
		end

		 if data.key=="TableConstructor" then
			local name
			local whatisthis=data.parent.parent.parent

			if(whatisthis.tag=="_FieldID")then
				name=searchFieldID(whatisthis)		
				if(name)then
					data.name=name 
					data.ttype="table-field"				
				else 
					data.name="#anonymous#"
					data.ttype="anonymous"
				end
				table.insert(AST.metrics.docutables,data)				
			elseif(whatisthis.tag=="_FieldExp")then
				data.name="#anonymous#"
				data.ttype="anonymous"
				table.insert(AST.metrics.docutables,data)
			end
		end
	end


end

captures = {
[1] =function(data)
	data.metrics.documentMetrics = { 
		documentedFunctionsCounter =  0 , 
		nondocumentedFunctionsCounter = 0,
		documentedTablesCounter = 0, 
		nondocumentedTablesCounter = 0,
		todos = {},
		questions = {},
		bugs = {},
		fixmes={},
		infos={},
		hows={}	
	}


	data.metrics.docutables={}


-- searching recursive
	travers(data,data)
 

--^ `custom comment metrics` some custom comment metrics
	data.metrics.documentMetrics.todos = TODOs
	data.metrics.documentMetrics.bugs = BUGs
	data.metrics.documentMetrics.questions = QUESTIONs
	data.metrics.documentMetrics.fixmes = FIXMEs
	data.metrics.documentMetrics.infos = INFOs
	data.metrics.documentMetrics.hows = HOWs

	TODOs={}
	BUGs = {}
 	QUESTIONs = {} 
 	FIXMEs={}
 	INFOs={}
 	HOWs={}
--v 

-- insert tables from current file into global docutables  table 
	for k,v in pairs(docutables) do
		table.insert(data.metrics.docutables,v)
	end

-- count metric FUNCTIONS
	if(data.metrics.functionDefinitions ~=nil) then
		for k,v in pairs(data.metrics.functionDefinitions) do
			if(v.documented==1)then
				data.metrics.documentMetrics.documentedFunctionsCounter = data.metrics.documentMetrics.documentedFunctionsCounter +1
			else
				data.metrics.documentMetrics.nondocumentedFunctionsCounter = data.metrics.documentMetrics.nondocumentedFunctionsCounter +1
			end
		end
	end

--count metric TABLES --number of constructors (documented/commented tables are in luaDoc_tables)
	if(data.luaDoc_tables~=nil)then
		for k,v in pairs(data.luaDoc_tables) do	
			data.metrics.documentMetrics.documentedTablesCounter = data.metrics.documentMetrics.documentedTablesCounter +1			
		end
	end
-- count non documented tables number of all constructors- documented
	data.metrics.documentMetrics.nondocumentedTablesCounter  = 	tableConstructorCount - data.metrics.documentMetrics.documentedTablesCounter 	
	tableConstructorCount = 0
	docutables={}
	return data
end,

Assign=function(data)

	local varlist,explist

	varlist = utils.searchForTagItem("VarList",data.data)
	explist = utils.searchForTagItem("ExpList",data.data)

	for k,v in pairs(explist.data) do
		
		local node = utils.searchForTagItem_recursive("TableConstructor",v,2)
		if(node and varlist.data[k]) then
			local varname = varlist.data[k]
		if(varname.text:match("[%.%[]"))then
				table.insert(docutables,{ttype='table-field', name=varname.text, text=node.text,Expnode=node.parent.parent}) 
		else
--TODO set tables ttype property to correct value(global/local). See module metrics.captures.block 
				table.insert(docutables,{ttype='', name=varname.text, text=node.text,Expnode=node.parent.parent}) --node.parent.parent is the Exp node for future creating total tabl definitions table
		end	
	end
		
	end
	return data
end,

LocalAssign = function(data)
	local varlist,explist
		varlist = utils.searchForTagItem("NameList",data.data)
		explist = utils.searchForTagItem("ExpList",data.data)
		if(explist and varlist) then
			for k,v in pairs(explist.data) do

				local node = utils.searchForTagItem_recursive("TableConstructor",v,2)
				if(node and varlist.data[k]) then
				local varname = varlist.data[k]
				table.insert(docutables,{ttype='local', name=varname.text, text=node.text,Expnode=node.parent.parent})--node.parent.parent is the Exp node for future creating total tabl definitions table
				end

			end
		end
	return(data)
end,

TableConstructor = function(data)
	tableConstructorCount = tableConstructorCount +1
	return data
end,

COMMENT = function(data)
	data.parsed=comments.Parse(data.text)
	if(data.parsed and data.parsed.style=="custom")then
		if(data.parsed.type == "todo")then
			table.insert(TODOs,data)
		end
		if(data.parsed.type == "bug")then
			table.insert(BUGs,data)
		end
		if(data.parsed.type == "question")then
			table.insert(QUESTIONs,data)
		end
		if(data.parsed.type == "fixme")then
			table.insert(FIXMEs,data)
		end
		if(data.parsed.type == "how")then
			table.insert(HOWs,data)
		end
		if(data.parsed.type == "info")then
			table.insert(INFOs,data)
		end
	end

return data
end

}
