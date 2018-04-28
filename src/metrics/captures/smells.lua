local math = require 'math'
local rules = require 'metrics.rules'

local pairs, print, table = pairs, print, table

local maxLineLength = 80
local maxFunctionNesting = 0
local maxTableNesting = 0
local maxTableFields = 5


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

function lineSplit(string)
        if sep == nil then
                sep = "%s"
        end
        local table={} ; i=1
        for str in string.gmatch(string, "([^\n]+)") do -- '+' is for skipping over empty lines
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

local function findParent(ast, smellsTable)
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


local function isFunction(key)
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

local function findTableName(ast)

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

local function recursive(ast, functionNesting, tableNesting, smellsTable)

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
			end

			ast.metrics.depth = functionNesting.level
			table.insert(functionNesting.parents, ast.name)

			if(functionNesting.level > maxFunctionNesting) then
				--print("Nesting level of FUNCTION \"" .. ast.name .. "\" is more than " .. maxFunctionNesting .. ", refactor this function: ")

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
				--print("Nesting level of TABLE \"" .. ast.name .. "\" is more than " .. maxTableNesting .. ", refactor this table: ")
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

local function getUpvalues(ast)
	upvalues = {info = {}, functions = {}}

	for k, functionTable in pairs(ast.metrics.blockdata.fundefs) do
		upvaluesCount = 0

		for name, vars in pairs(functionTable.metrics.blockdata.remotes) do
		--dobry vystup, len upravit nejako meno suboru.. este to hodit to tabulky upvalues a returnut...
			--print(fileName, functionTable.name, name, #vars)
			upvaluesCount = upvaluesCount + 1
			-- pri zmene zmenit aj v luadocer-smells.lp
			--[[for _, node in pairs(vars) do
				if (node.isRead) then
					upvaluesCount = upvaluesCount + 1
					break
				end		
			end --]] 
			
			table.insert(upvalues.info, {functionName = functionTable.name, varName = name, usages = #vars})

			--upvalues[fileName][table.name][name] = #vars
		end

		upvalues.functions[functionTable.name] = upvaluesCount
		--upvalues[fileName][table.name]["TOTAL"] = 
	end

	return upvalues

end

local function getSmells(AST_list)

	local result = {}

	for file, ast in pairs(AST_list) do
		local smellsTable = {tableSmells = {manyFields = {count = 0}, depth = {count = 0}}, functionSmells = {count = 0}}
		recursive(ast, {level = 0, parents = {}}, {level = 0, parents = {}}, smellsTable)
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