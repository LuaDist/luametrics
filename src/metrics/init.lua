-------------------------------------------------------------------------------
-- Interface for metrics module
-- @release 2011/05/04, Ivan Simko
-- @release 2013/04/04, Peter Kosa
-------------------------------------------------------------------------------

local lpeg = require 'lpeg'
local parser  = require 'leg.parser'
local grammar = require 'leg.grammar'

local rules = require 'metrics.rules'
local utils = require 'metrics.utils'

local math = require 'math'

local io, table, pairs, type, print = io, table, pairs, type, print

local AST_capt = require 'metrics.captures.AST'
local LOC_capt = require 'metrics.captures.LOC'
local ldoc_capt = require 'metrics.luadoc.captures'
local block_capt = require 'metrics.captures.block'
local infoflow_capt = require 'metrics.captures.infoflow'
local halstead_capt = require 'metrics.captures.halstead'
local ftree_capt = require 'metrics.captures.functiontree'
local stats_capt = require 'metrics.captures.statements'
local cyclo_capt = require 'metrics.captures.cyclomatic'
local smells_capt = require 'metrics.captures.smells'
local document_metrics = require 'metrics.captures.document_metrics'

module ("metrics")

-- needed to set higher because of back-tracking patterns
lpeg.setmaxstack (400)

local capture_table = {}

local maxFunctionNesting = 2
local maxTableNesting = 2
local maxTableFields = 5

grammar.pipe(LOC_capt.captures, AST_capt.captures)
grammar.pipe(block_capt.captures, LOC_capt.captures)
grammar.pipe(infoflow_capt.captures, block_capt.captures)
grammar.pipe(halstead_capt.captures, infoflow_capt.captures)
grammar.pipe(ftree_capt.captures, halstead_capt.captures)
grammar.pipe(ldoc_capt.captures, ftree_capt.captures)
grammar.pipe(stats_capt.captures,ldoc_capt.captures)
grammar.pipe(cyclo_capt.captures, stats_capt.captures)
grammar.pipe(document_metrics.captures,cyclo_capt.captures)
grammar.pipe(smells_capt.captures, document_metrics.captures)
grammar.pipe(capture_table,smells_capt.captures)

local lua = lpeg.P(grammar.apply(parser.rules, rules.rules, capture_table))
local patt = lua / function(...)
	return {...}
end

------------------------------------------------------------------------
-- Main function for source code analysis
-- returns an AST with included metric values in each node
-- @name processText
-- @param code - string containing the source code to be analyzed
function processText(code)

	local result = patt:match(code)[1]

	return result
end

function findParent(ast, smellsTable)
	if(ast.key == "TableConstructor") then					
		if(ast.name == nil)then
			ast.name = findTableName(ast.parent.parent.parent.parent)
		end	
		
		if(not ast.metrics.fieldsCount) then ast.metrics.fieldsCount = 0 end

		ast.metrics.fieldsCount = ast.metrics.fieldsCount + 1

		if(ast.metrics.fieldsCount > maxTableFields) then
			print("Fields count of table \"" .. ast.name .. "\" is more than " .. maxTableFields .. ", refactor this table")
			if(not smellsTable.tableSmells.manyFields) then smellsTable.tableSmells.manyFields = {} end
			if(not smellsTable.tableSmells.manyFields[ast.name]) then 
				smellsTable.tableSmells.manyFields[ast.name] = {} 
				if(not smellsTable.tableSmells.manyFields.count) then smellsTable.tableSmells.manyFields.count = 0 end
				smellsTable.tableSmells.manyFields.count = smellsTable.tableSmells.manyFields.count + 1
			end
			smellsTable.tableSmells.manyFields[ast.name].count = ast.metrics.fieldsCount
		end
		return
	end

	findParent(ast.parent, smellsTable)
end


function isFunction(key)
	return (key == "Function" or key == "GlobalFunction" or key == "LocalFunction")
end

function copyParents(parentTable)

	if(parentTable == nil) then
		return
	end

	local newTable = {}

	for k,v in pairs(parentTable) do
		table.insert( newTable, k, v )
	end

	return newTable
end

function findTableName(ast)

	local name = nil

	for k,v in pairs(ast.data) do
		if(v.key == "Name") then
			return v.text
		end

		name = findTableName(v)
		if(name) then
			return name
		end
	end

end

function recursive(ast, functionNesting, tableNesting, smellsTable)

	local insertedF = false
	local insertedT = false
	if(ast) then
		if(ast.key == "Field") then 
			--print(ast.key)
			findParent(ast, smellsTable)			
		elseif (isFunction(ast.key)) then
			--print(ast.name)
			
			if(ast.metrics == nil) then
				ast.metrics = {}
				print("metrics created")
			end

			ast.metrics.depth = functionNesting.level
			table.insert(functionNesting.parents, ast.name)

			if(functionNesting.level > maxFunctionNesting) then
				print("Nesting level of FUNCTION \"" .. ast.name .. "\" is more than " .. maxFunctionNesting .. ", refactor this function: ")

				if(not smellsTable.functionSmells[ast.name]) then 
					if(not smellsTable.functionSmells.count) then smellsTable.functionSmells.count = 0 end
					smellsTable.functionSmells.count = smellsTable.functionSmells.count + 1
				end

				smellsTable.functionSmells[ast.name] = { level = functionNesting.level, parents = copyParents(functionNesting.parents) }
			end

			functionNesting.level = functionNesting.level + 1
			insertedF = true
		elseif (ast.key == "TableConstructor") then
			ast.metrics.depth = tableNesting.level
			table.insert(tableNesting.parents, ast.name)	

			if(ast.name == nil) then
				ast.name = findTableName(ast.parent.parent.parent.parent)
			end			
			
			if(tableNesting.level > maxTableNesting) then
				print("Nesting level of TABLE \"" .. ast.name .. "\" is more than " .. maxTableNesting .. ", refactor this table: ")
				if(not smellsTable.tableSmells.depth) then smellsTable.tableSmells.depth = {} end

				if(not smellsTable.tableSmells.depth[ast.name]) then 
					if(not smellsTable.tableSmells.depth.count) then smellsTable.tableSmells.depth.count = 0 end
					smellsTable.tableSmells.depth.count = smellsTable.tableSmells.depth.count + 1
				end

				smellsTable.tableSmells.depth[ast.name] = { level = tableNesting.level, parents = copyParents(tableNesting.parents) }
			end

			tableNesting.level = tableNesting.level + 1	
			insertedT = true

		end
	else
		return
	end

	for key, child in pairs(ast.data) do
		recursive(child, functionNesting, tableNesting, smellsTable)
	end

	if(insertedF) then
		functionNesting.level = functionNesting.level - 1
		functionNesting.parents[#functionNesting.parents] = nil -- remove last item
	end

	if(insertedT) then
		tableNesting.level = tableNesting.level - 1
		tableNesting.parents[#tableNesting.parents] = nil -- remove last item
	end

end

function smells(AST_list)

	local result = {}

	for file, ast in pairs(AST_list) do

		local smellsTable = {tableSmells = {manyFields = {count = 0}, depth = {count = 0}}, functionSmells = {count = 0}}
		recursive(ast, {level = 0, parents = {}}, {level = 0, parents = {}}, smellsTable)
		table.insert(result, {file = file, smells = smellsTable})

	end

	return result

end

------------------------------------------------------------------------
-- Function to join metrics from different AST's
-- returns an AST with joined metrics, where possible
-- @name doGlobalMetrics
-- @param file_metricsAST_list table of AST's' generated by function processText
function doGlobalMetrics(file_metricsAST_list)

	-- keep AST lists
	local returnObject = {}
	returnObject.file_AST_list = file_metricsAST_list

	--- function declarations
	local total_function_definitions = {}

	local anonymouscounter=0   -- for naming anonymous functions
	local anonymouscounterT = 0 -- for naming anonymous  tables
	for filename, AST in pairs(file_metricsAST_list) do
		for _, fun in pairs(AST.metrics.blockdata.fundefs) do

			-- edit to suit luadoc expectations
			if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction' or fun.tag == 'Function') then
-- anonymous function type
				if(fun.name=="#anonymous#")then
					anonymouscounter=anonymouscounter+1
					fun.name = fun.name .. anonymouscounter
					fun.path = filename
				elseif(fun.name:match("[%.%[]") or fun.isGlobal==nil)then
-- table-field function type
					fun.fcntype = 'table-field'
				elseif (fun.isGlobal) then fun.fcntype = 'global' else fun.fcntype = 'local' end
					fun.path = filename
					table.insert(total_function_definitions, fun)
			end
		end
	end
	table.sort(total_function_definitions, utils.compare_functions_by_name)
	returnObject.functionDefinitions = total_function_definitions


-- ^ `tables` list of tables in files , concatenate luaDoc_tables and docutables
	local total_table_definitions = {}
	local set = {}
	for filename, AST in pairs(file_metricsAST_list) do

	-- concatenate two tables by  Exp node tables

		for k,tabl in pairs(AST.luaDoc_tables) do
			tabl.path=filename
			tabl.name = k
			table.insert(total_table_definitions, tabl)
			set[tabl] = true
		end
		for k,tabl in pairs(AST.metrics.docutables) do
			if(tabl.ttype=="anonymous")then
				anonymouscounterT=anonymouscounterT+1
			 	tabl.name = tabl.name .. anonymouscounterT
			end
			if (not tabl.Expnode) then
			 	tabl.path = filename
				table.insert(total_table_definitions, tabl)
			elseif(set[tabl.Expnode]~=true)then
				tabl.path = filename
				table.insert(total_table_definitions, tabl)
				set[tabl.Expnode] = true
			end
		end
 	end
	returnObject.tables = total_table_definitions



	-- merge number of lines metrics
	returnObject.LOC = {}

	for filename, AST in pairs(file_metricsAST_list) do

		for name, count in pairs(AST.metrics.LOC) do
			if not returnObject.LOC[name] then returnObject.LOC[name] = 0 end
			returnObject.LOC[name] = returnObject.LOC[name] + count
		end

	end
	-- combine halstead metrics

	local operators, operands = {}, {}

	for filename, AST in pairs(file_metricsAST_list) do
		for name, count in pairs(AST.metrics.halstead.operators) do
			if (operators[name] == nil) then
				operators[name] = count
			else
				operators[name] = operators[name] + count
			end
		end
		for name, count in pairs(AST.metrics.halstead.operands) do
			if (operands[name] == nil) then
				operands[name] = count
			else
				operands[name] = operands[name] + count
			end
		end
	end

	local number_of_operators = 0
	local unique_operators = 0
	for op, count in pairs(operators) do
		unique_operators = unique_operators + 1
		number_of_operators = number_of_operators + count
	end

	local number_of_operands = 0
	local unique_operands = 0
	for op, count in pairs(operands) do
		unique_operands = unique_operands + 1
		number_of_operands = number_of_operands + count
	end

	returnObject.halstead = {}

	halstead_capt.calculateHalstead(returnObject.halstead, operators, operands)

	-- instability metric for each module
	-- 		afferent and efferent coupling --- instability metric
	-- 		afferent - connection to other modules
	-- 		efferent - connetions from other modules

	for currentFilename, currentAST in pairs(file_metricsAST_list) do

		currentAST.metrics.coupling = {}
		currentAST.metrics.coupling.afferent_coupling = 0
		currentAST.metrics.coupling.efferent_coupling = 0

		local currentName = currentAST.metrics.currentModuleName or filename

		for name in pairs(currentAST.metrics.moduleCalls) do
			currentAST.metrics.coupling.afferent_coupling = currentAST.metrics.coupling.afferent_coupling + 1
		end

		for filename, AST in pairs(file_metricsAST_list) do
			if (filename ~= currentFilename) then
				if (AST.metrics.moduleCalls[currentName]) then currentAST.metrics.coupling.efferent_coupling = currentAST.metrics.coupling.efferent_coupling + 1 end
			end
		end

		currentAST.metrics.coupling.instability = currentAST.metrics.coupling.afferent_coupling / (currentAST.metrics.coupling.efferent_coupling + currentAST.metrics.coupling.afferent_coupling)

	end

	-- statement metrics

	returnObject.statements = {}

	for filename, AST in pairs(file_metricsAST_list) do

		for name, stats in pairs(AST.metrics.statements) do
			if not returnObject.statements[name] then returnObject.statements[name] = {} end
			for _, stat in pairs(stats) do
				table.insert(returnObject.statements[name], stat)
			end
		end

	end

	-- merge moduleDefinitions
	returnObject.moduleDefinitions = {}

	for filename, AST in pairs(file_metricsAST_list) do
		for exec, moduleRef in pairs(AST.metrics.moduleDefinitions) do
			if (moduleRef.moduleName) then
				table.insert(returnObject.moduleDefinitions, moduleRef)
			end
		end

	end


	--merge document metrics
	returnObject.documentMetrics={}
	for filename, AST in pairs(file_metricsAST_list) do
		for name, count in pairs(AST.metrics.documentMetrics) do
			if( type(count)=="table")then
				if not returnObject.documentMetrics[name] then returnObject.documentMetrics[name]={} end
				for _,v in pairs(count) do
					table.insert(returnObject.documentMetrics[name],v)
				end
			else
				if not returnObject.documentMetrics[name] then returnObject.documentMetrics[name] = 0 end
				returnObject.documentMetrics[name]=returnObject.documentMetrics[name]+count
			end
		end
	end		
  
  --merge code smells
  returnObject.documentSmells = {} --Document smells sub-table
  returnObject.documentSmells.MI = smells_capt.countMI(file_metricsAST_list) --Add maintainability index
  returnObject.documentSmells.functionSmells = smells_capt.countFunctionSmells(file_metricsAST_list) --Add function smells eg: LOC, cyclomatic, halstead etc.
  returnObject.documentSmells.moduleSmells = {} --Module smells sub-table

  returnObject.documentSmells.smellsTable = smells(file_metricsAST_list)


--pozriet co treba indexovat v smellstable, co sa posiela do templates
  for filename, AST in pairs(file_metricsAST_list) do --Merge smells in modules to sub-table
    table.insert(returnObject.documentSmells.moduleSmells, {file = filename, RFC = AST.smells.RFC, WMC = AST.smells.WMC, NOM = AST.smells.NOM, responseToNOM = AST.smells.responseToNOM, CBO = AST.smells.CBO, 
															longLines = AST.smells.longLines })
  end

	return returnObject
end



-- test vypis
--[[ 
keys = {}
for k,v in pairs(node) do
	table.insert( keys, k)
end
	--print("--- START\n" .. value.text .. "\n --- END")
	print(" { " .. table.concat(keys, ", ") .. " }\n")
--]]
