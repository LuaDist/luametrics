local math = require 'math'

local pairs, print, table = pairs, print, table

local maxLineLength = 80
local maxFunctionNesting = 0
local maxTableNesting = 1
local maxTableFields = 5
local maxUpvalues = 5


--- Function compares 2 table entries by LOSC
-- @param functionA First table entry
-- @param functionB Second table entry
-- @author Martin Nagy
-- @return True if functionA LOSC > functionB LOSC
local function compareLOSC(functionA, functionB)
  
  return functionA.LOSC > functionB.LOSC
  
end

--- Function compares 2 table entries by NOA
-- @param functionA First table entry
-- @param functionB Second table entry
-- @author Martin Nagy
-- @return True if functionA NOA > functionB NOA
local function compareNOA(functionA, functionB)
  
  return functionA.NOA > functionB.NOA
  
end

--- Function compares 2 table entries by cyclomatic
-- @param functionA First table entry
-- @param functionB Second table entry
-- @author Martin Nagy
-- @return True if functionA cyclomatic > functionB cyclomatic
local function compareCyc(functionA, functionB)
  
  return functionA.cyclomatic > functionB.cyclomatic
  
end

--- Function compares 2 table entries by EFF
-- @param functionA First table entry
-- @param functionB Second table entry
-- @author Martin Nagy
-- @return True if functionA EFF > functionB EFF
local function compareHal(functionA, functionB)
  
  return functionA.EFF > functionB.EFF
  
end

--- Function rounds number to n decimal places
-- @param num Number to round
-- @param numDecimalPlaces Decimal places to round
-- @author Martin Nagy
-- @return Number rounded to n decimal places
local function round(num, numDecimalPlaces)
  
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
  
end

--- Function gets metrics from AST of file and copy them to return object
-- @param file_metricsAST_list List of AST of all files
-- @author Martin Nagy
-- @return Tables with long method, cyclomatic complexity and number of arguments code smells
local function countFunctionSmells(file_metricsAST_list)
  
  local functionCount = 0
  
  --Create return object
  local smell = {
    longMethod = {},
    cyclomatic = {},
    manyParameters = {},
    totalFunctions = 0
  }
  
	for filename, AST in pairs(file_metricsAST_list) do --Loop through ASTs of files
    
		for _, fun in pairs(AST.metrics.blockdata.fundefs) do --Loop through functions

      --Select Global, local or functions in general
			if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction' or fun.tag == 'Function') then
        
        functionCount = functionCount + 1
        
        --Only for taged functions (Not anonymous and table field)
        if(fun.fcntype == 'global' or fun.fcntype == 'local') then
          
          --Insert data to tables to use independently
          table.insert(smell.longMethod, {file = filename, name = fun.name, LOC = fun.metrics.LOC.lines, LOSC = fun.metrics.LOC.lines_code})
          table.insert(smell.cyclomatic, {file = filename, name = fun.name, cyclomatic = (fun.metrics.cyclomatic.decisions or 1)})
          table.insert(smell.manyParameters, {file = filename, name = fun.name, NOA = fun.metrics.infoflow.arguments_in})
          
        end
			end	
		end
	end
  
  --Sort each table descending
  table.sort(smell.longMethod, compareLOSC)
  table.sort(smell.cyclomatic, compareCyc)
  table.sort(smell.manyParameters, compareNOA)
  
  smell.totalFunctions = functionCount
  
  return smell
  
end

--- Function gets metrics from AST of file and counts maintainability index of project
-- @param file_metricsAST_list List of AST of all files
-- @author Martin Nagy
-- @return Maintainability index of project
local function countMI(file_metricsAST_list)
  
  --variable preparation
  local MI = 0
  local cyclomatic = 0
  local halsteadVol = 0
  local LOSC = 0
  local comments = 0
  local commentPerc = 0
  local files = 0
  
  for filename, AST in pairs(file_metricsAST_list) do --Loop through ASTs of files
    
    files = files + 1
    if(AST.metrics.cyclomatic ~= nil) then --Count cyclomatic complexity
      cyclomatic = cyclomatic + (AST.metrics.cyclomatic.decisions_all or 0)
    end
    halsteadVol = halsteadVol + AST.metrics.halstead.VOL --Count halstead volume
    LOSC = LOSC + AST.metrics.LOC.lines_code --Lines of source code
    comments = comments + AST.metrics.LOC.lines_comment --Count comment lines
    
	end
  
  --Count maintainability index
  commentPerc = comments / LOSC
  MI = 171 
          - (5.2 * math.log(halsteadVol / files))
          - (0.23 * (cyclomatic / files))
          - (16.2 * math.log(LOSC / files))
          + (50 * math.sin(math.sqrt(2.4 * (commentPerc / files))))
  
  return round(MI, 2) -- Round on 2 decimal places
  
end

function lineSplit(text)
        if sep == nil then
                sep = "%s"
        end
        local table={} ; i=1

		text = string.gsub( text, "\t", "    ")

        for str in string.gmatch(text, "([^\n]*)\n?") do -- '+' is for skipping over empty lines
                table[i] = str
                i = i + 1
        end
        return table
end

local function lineLength(codeText)
  local lines = lineSplit(codeText)

  local longLines = {}
  for key, line in ipairs(lines) do
    actualLineLength = #line
    if(actualLineLength > maxLineLength) then
      table.insert( longLines, { lineNumber = key, length = actualLineLength }) 
    end
  end

  return longLines
end

--- Function gets metrics from AST of file counts module smells and return them back to AST
-- @param funcAST AST of file
-- @author Martin Nagy
-- @return AST enriched by module smells
local function countFileSmells(funcAST)
  
  local RFC = 0 --Response for class - Sum of no. executed methods and no. methods in class (file)
  local CBO = 0 --Coupling between module (file) and other big modules in whole project
  local WMC = 0 --Weighted method per class - sum of cyclomatic complexity of functions in class (file)
  local NOM = 0 --No. methods in class (file)
  
  --Count RFC
  for name, value in pairs(funcAST.metrics.functionExecutions) do
    
    for name, value in pairs(value) do
      RFC = RFC + 1
    end
    
  end
    
  --Count CBO (without math module)
  for name, value in pairs(funcAST.metrics.moduleCalls) do
    
    if(name ~= 'math') then -- something is wrong - math etc. module calls contains math but not table string etc...
      
      CBO = CBO + 1
        
    end
    
  end
  
  --Add RFC and count WMC and NOM
  for _, fun in pairs(funcAST.metrics.blockdata.fundefs) do
    
    if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction' or fun.tag == 'Function') then
      
      RFC = RFC + 1
        
      WMC = WMC + (fun.metrics.cyclomatic.decisions or 1)
      NOM = NOM + 1
        
    end
  end
    
  --Add smell counts back to AST
  funcAST.smells = {}
  funcAST.smells.RFC = RFC
  funcAST.smells.WMC = WMC
  funcAST.smells.NOM = NOM
  funcAST.smells.responseToNOM = round((RFC / NOM), 2)
  funcAST.smells.CBO = CBO
  -- TODO pridane
  funcAST.smells.longLines = lineLength(funcAST.text)

end


--- Function tries to find statement in ast parents
-- @param ast AST node
-- @author Dominik Stevlik
-- @return name of table, when found
local function findStatement(ast)
	local node = ast

	while(node.key ~= "Stat" and node.key ~= "LastStat" and node.key ~= "FunctionCall") do
		node = node.parent 
	end

	return node
end

--- Function tries to recursively find name in ast childs 
-- @param ast AST node
-- @author Dominik Stevlik
-- @return name of table, when found
local function findName(ast)
	local name = nil
	
	-- loop throught childs and find node key Name
	for k,v in pairs(ast.data) do
		if(v.key == "Name") then
			return v.text
		end

		-- continue in recursion when key is not Name
		name = findName(v)
		if(name) then
			-- return when name was found)
			return name
		end
	end
end

--- Function tries to recursively find table name in ast  
-- @param ast AST node
-- @author Dominik Stevlik
-- @return name of table
local function findTableName(ast)
	local stat = findStatement(ast)
	local name = nil

	-- in return statement is not possible to create table with name
	if(stat.key == "LastStat") then 
		name = "#AnonymousReturn"
	elseif(stat.key == "FunctionCall") then
		name = "#AnonymousFunctionParameter"
	else 
		name = findName(stat)
	end

	if(name == nil) then
		name = "Anonymous"
	end
	return name
end


--- Function tries to find parent(table constructor) of table field and checks its nested level
-- @param ast AST node
-- @param smellsTable Reference to smell table, where stores the smells
-- @author Dominik Stevlik
local function findParent(ast, smellsTable)
	if(ast.key == "TableConstructor") then		
		-- get and store name for table, when unknown			
		if(ast.name == nil)then
			ast.name = findTableName(ast)
		end	
		-- initialize cont of fields to 0
		if(not ast.metrics.fieldsCount) then ast.metrics.fieldsCount = 0 end

		ast.metrics.fieldsCount = ast.metrics.fieldsCount + 1
		-- check count of fields
		if(ast.metrics.fieldsCount > maxTableFields) then
			-- create table
			if(not smellsTable.tableSmells.manyFields) then smellsTable.tableSmells.manyFields = {} end
			-- create table
			if(not smellsTable.tableSmells.manyFields[ast.name]) then 
				smellsTable.tableSmells.manyFields[ast.name] = {} 
				-- initialize count of tables with many fields to 0
				if(not smellsTable.tableSmells.manyFields.count) then smellsTable.tableSmells.manyFields.count = 0 end
				-- increase ount of tables with many fields
				smellsTable.tableSmells.manyFields.count = smellsTable.tableSmells.manyFields.count + 1
			end
			-- store count of fields to smells table
			smellsTable.tableSmells.manyFields[ast.name].count = ast.metrics.fieldsCount
		end
		return
	end

	-- when no table contructor, continue in recursion
	findParent(ast.parent, smellsTable)
end

--- Function checks if key is key of functions
-- @param key Key of the AST node
-- @author Dominik Stevlik
-- @return true when the key is function, else return false
local function isFunction(key)
	return (key == "Function" or key == "GlobalFunction" or key == "LocalFunction")
end

--- Function copy all values on keys to new table
-- @param parentTable Table to copy
-- @author Dominik Stevlik
-- @return new table or nil when parentTable is nil
function copyParents(parentTable)

	if(parentTable == nil) then
		return nil
	end

	local newTable = {}

	-- loop throught parents and copy each one
	for k,v in pairs(parentTable) do
		table.insert( newTable, k, v )
	end

	return newTable
end

--- Function recursively passes ast nodes and searches for smells of tables and functions
-- @param ast AST node
-- @param functionNesting Table which holds nesting level and parents of function
-- @param tableNesting Table which holds nesting level and parents of table
-- @param smellsTable Reference to smell table, where stores the smells
-- @author Dominik Stevlik
local function recursive(ast, functionNesting, tableNesting, smellsTable)

	-- set true when nesting level of function is increased, decrease nesting level and remove last parent after return from childs, when this was true
	local insertedF = false
	-- set true when nesting level of table is increased, decrease nesting level and remove last parent after return from childs, when this was true
	local insertedT = false

	if(ast) then
		if(ast.key == "Field") then 
			-- search for table constructor
			findParent(ast, smellsTable)			
		elseif (isFunction(ast.key)) then
			
			if(ast.metrics == nil) then
				ast.metrics = {}
			end

			-- store nesting level to current node
			ast.metrics.depth = functionNesting.level
			-- insert node name as parent for next nested functions
			table.insert(functionNesting.parents, ast.name)

			-- check function nesting level
			if(functionNesting.level > maxFunctionNesting) then
				if(not smellsTable.functionSmells[ast.name]) then 
					if(not smellsTable.functionSmells.count) then smellsTable.functionSmells.count = 0 end
					-- increase total count of nested functions
					smellsTable.functionSmells.count = smellsTable.functionSmells.count + 1
				end

				-- store function name, level, parents in smells table
				smellsTable.functionSmells[ast.name] = { level = functionNesting.level, parents = copyParents(functionNesting.parents) }
			end

			-- increase nesting level
			functionNesting.level = functionNesting.level + 1
			-- set true for decrease nesting level after recursion
			insertedF = true
		elseif (ast.key == "TableConstructor") then
			if(ast.name == nil) then
				-- find and store table name, when unknown
				ast.name = findTableName(ast)
			end	

			-- store nesting level for table
			ast.metrics.depth = tableNesting.level
			-- insert node name as parent for next nested functions
			table.insert(tableNesting.parents, ast.name)	


			-- check table nesting level
			if(tableNesting.level > maxTableNesting) then
				if(not smellsTable.tableSmells.depth) then smellsTable.tableSmells.depth = {} end

				if(not smellsTable.tableSmells.depth[ast.name]) then 
					if(not smellsTable.tableSmells.depth.count) then smellsTable.tableSmells.depth.count = 0 end
					-- increase total count of nested tables
					smellsTable.tableSmells.depth.count = smellsTable.tableSmells.depth.count + 1
				end

				-- store table name, level, parents in smells table
				smellsTable.tableSmells.depth[ast.name] = { level = tableNesting.level, parents = copyParents(tableNesting.parents) }
			end

			-- increase nesting level
			tableNesting.level = tableNesting.level + 1	
			-- set true for decrease nesting level after recursion
			insertedT = true
		
		end
	else
		-- stop recursion when ast node is nil
		return
	end

	-- continue in recursion
	for key, child in pairs(ast.data) do
		recursive(child, functionNesting, tableNesting, smellsTable)
	end

	-- when function nesting level was increased
	if(insertedF) then
		functionNesting.level = functionNesting.level - 1
		functionNesting.parents[#functionNesting.parents] = nil -- remove last item
	end

	-- when table nesting level was increased
	if(insertedT) then
		tableNesting.level = tableNesting.level - 1
		tableNesting.parents[#tableNesting.parents] = nil -- remove last item
	end

end

--- Function gets upvalues from function definitions and their data
-- @param ast AST node
-- @author Dominik Stevlik
-- @return table with info(function name, variable name, number of uses) and functions(function name(as key), upvalues count)
local function getUpvalues(ast)
	upvalues = {info = {}, functions = {}, totalUsages = 0}

	-- loop throught all functions
	for k, functionTable in pairs(ast.metrics.blockdata.fundefs) do
		upvaluesCount = 0

		-- loop throught all remotes
		for name, vars in pairs(functionTable.metrics.blockdata.remotes) do
			upvaluesCount = upvaluesCount + 1
			-- 
			--[[for _, node in pairs(vars) do
				if (node.isRead) then
					upvaluesCount = upvaluesCount + 1
					break
				end		
			end --]] 

			-- store info like function name, variable name and usage count, and create easy access to count of total upvalues
			table.insert(upvalues.info, {functionName = functionTable.name, varName = name, usages = #vars})
			upvalues.totalUsages = upvalues.totalUsages + #vars

			--upvalues[fileName][table.name][name] = #vars
		end

		-- store count of variables in function
		upvalues.functions[functionTable.name] = upvaluesCount
		
	end

	return upvalues

end

--- Function recursively search smells for each file in AST list 
-- @param AST_list list of AST nodes 
-- @author Dominik Stevlik
-- @return table with found smells
local function getSmells(AST_list)

	-- table with number keys (1,2,3,....) and values (file name, smells, upvalues)
	local result = {}

	-- loop throught list of file AST
	for file, ast in pairs(AST_list) do
		local smellsTable = {tableSmells = {manyFields = {count = 0}, depth = {count = 0}}, functionSmells = {count = 0}}
		recursive(ast, {level = 0, parents = {}}, {level = 0, parents = {}}, smellsTable)
		-- get upvalues from blockdata
		local upvalues = getUpvalues(ast)
		table.insert(result, {file = file, smells = smellsTable, upvalues = upvalues})

	end

	return result

end


--Run countFileSmells function as capture (when creating global AST)
local captures = {
  
	[1] = function(data) countFileSmells(data) return data end, --Run automaticaly when file AST created 
  
}

return {
  captures = captures,
  countFileSmells = countFileSmells,
  countMI = countMI,
  countFunctionSmells = countFunctionSmells,
  getSmells = getSmells
}