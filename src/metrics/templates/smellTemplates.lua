local utils = require 'metrics.templates.utils'

--- Function creates a HTML template containing methods sorted according to number of lines of source code
-- @param globalMetrics Global metrics of project
-- @author Martin Nagy
-- @return HTML template containing methods sorted according to number of lines of source code
local function createLongMethodTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Lines of code", "Lines of source code"})

	--Add rows to table
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.longMethod) do

		local color = nil

		--Set background color according to value
		if(n.LOSC > 55) then color = "RED" elseif(n.LOSC >= 45) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.LOC, n.LOSC}, true, color)

	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

--- Function creates a HTML template containing methods sorted according to cyclomatic complexity
-- @param globalMetrics Global metrics of project
-- @author Martin Nagy
-- @return HTML template containing methods sorted according to cyclomatic complexity
local function createCycloTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Cyclomatic complexity"})

	--Add rows to table
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.cyclomatic) do

		local color = nil

		--Set background color according to value
		if(n.cyclomatic > 20) then color = "RED" elseif(n.cyclomatic >= 11) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.cyclomatic}, true, color)

	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

--- Function creates a HTML template containing methods sorted according to number of parameters
-- @param globalMetrics Global metrics of project
-- @author Martin Nagy
-- @return HTML template containing methods sorted according to number of parameters
local function createManyParamsTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Number of Parameters"})

	--Add rows to table
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.manyParameters) do

		local color = nil

		--Set background color according to value
		if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.NOA}, true, color)

	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

--- Function creates a HTML template containing module smells
-- @param globalMetrics Global metrics of project
-- @author Martin Nagy
-- @return HTML template containing module smells
local function createModuleTables(globalMetrics)

	local result = ""

	for _, s in pairs(globalMetrics.documentSmells.moduleSmells) do --Loop through modules

		--Create title above table
		result = result .. "<div style='float:left; display: block'><h3>" .. s.file .. "</h3>"

		--Create table header
		local smellTable = utils.createTable("smell_table", {"Criteria", "Value"})
		local count = 0

		--Response for module
		local color = nil --Set background color if condition fits and add table row
		if(s.RFC > 100) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Response for module", s.RFC}, false, color)

		--Coupling between modules
		color = nil --Set background color if condition fits and add table row
		if(s.CBO > 5) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Coupling between modules", s.CBO}, false, color)

		--Response for module / number of methods
		color = nil --Set background color if condition fits and add table row
		if(s.responseToNOM > 5) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Response for module / number of methods", s.responseToNOM}, false, color)

		--Weighted methods per module
		color = nil --Set background color if condition fits and add table row
		if(s.WMC > 100) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Weighted methods per module", s.WMC}, false, color)

		--Number of methods
		color = nil --Set background color if condition fits and add table row
		if(s.NOM > 40) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Number of methods", s.NOM}, false, color)

		--Number of long lines
		color = nil --Set background color if condition fits and add table row
		if(#s.longLines > 3) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Number of long lines", #s.longLines}, false, color)

		--If at least 2 conditions fits prints Error result with background set
		if(count > 1) then
			smellTable = smellTable .. utils.addTableRow({"Result", "Refactor!"}, false, "ORANGE")
		else
			smellTable = smellTable .. utils.addTableRow({"Result", "O.K."}, false, "GREEN")
		end

		--Close table
		smellTable = smellTable .. utils.closeTable()

		result = result .. smellTable

		result = result .. "</div><div style='clear:both;'></div>"

	end

	return result

end

--- Function creates a HTML template presenting maintainability index of project
-- @param globalMetrics Global metrics of project
-- @author Martin Nagy
-- @return HTML template presenting maintainability index of project
local function createMITable(globalMetrics)

	local smellTable = "<p><table class='smell_table'>"
	local MI = globalMetrics.documentSmells.MI
	local color = nil

	--Maintainability index table with background color
	if(MI < 65) then color = "RED" elseif(MI < 85) then color = "ORANGE" else color = "GREEN" end
	smellTable = smellTable .. utils.addTableRow({"Maintainability index", MI}, false, color)

	smellTable = smellTable .. utils.closeTable() .. "</p>"

	--Explanation of maintainability index in table
	smellTable = smellTable .. utils.createTable("smell_table", {"Maintainability", "Score"})
	smellTable = smellTable .. utils.addTableRow({"Highly maintainable", ">85"}, false, "GREEN")
	smellTable = smellTable .. utils.addTableRow({"Moderately maintainable", ">65 and <85"}, false, "ORANGE")
	smellTable = smellTable .. utils.addTableRow({"Difficult to maintain", "<65"}, false, "RED")
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createLongLinesTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Line number", "Length of line"})

	for _, s in pairs(globalMetrics.documentSmells.moduleSmells) do
		local color = nil

		--Set background color according to value
		--if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end
		color = "WHITE"
		--smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.NOA}, true, color)
		for k,v in pairs(s.longLines) do
			if(v.length < 100) then color = "GREEN" elseif(v.length < 120) then color = "ORANGE" else color = "RED" end
			smellTable = smellTable .. utils.addTableRow({s.file, v.lineNumber, v.length}, false, color)
		end
	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable
end

local function createTablesWithManyFieldsTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Table name", "Table fields"})


	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do
		local color = nil

		--Set background color according to value
		--if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end
		color = "WHITE"

	--	if(s.smells.tableSmells.manyFields.count > 0) then -- when smells were detected 	
			for k,v in pairs(s.smells.tableSmells.manyFields) do
				if( type(v) == "table") then --variable is a table (count is not table)	
					smellTable = smellTable .. utils.addTableRow({s.file, k, v.count}, false, color)
				end
			end
	--	end
	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createFunctionDepthTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Function name", "Function nesting level"})


	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do
		local color = nil

		--Set background color according to value
		--if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end
		color = "WHITE"
	
		for k,v in pairs(s.smells.functionSmells) do
			if( type(v) == "table") then --variable is a table (count is not table)	
				smellTable = smellTable .. utils.addTableRow({s.file, k, v.level}, false, color)
			end
		end
	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do

		for k,v in pairs(s.smells.functionSmells) do	

			if(type(v) == "table") then --variable is a table (count is not table)
				if(v.parents) then -- if no parents, then no smell
					smellTable = smellTable .. utils.drawParentTree(v.parents, s.file, "function")
				end
			end
		end
	
	end

	return smellTable

end

local function createTableDepthTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Table name", "Table nesting level"})


	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do
		local color = nil

		--Set background color according to value
		--if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end
		color = "WHITE"

		for k,v in pairs(s.smells.tableSmells.depth) do
			if( type(v) == "table") then --variable is a table (count is not table)	
				smellTable = smellTable .. utils.addTableRow({s.file, k, v.level}, false, color)
			end
		
		end
	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do

		for k,v in pairs(s.smells.tableSmells.depth) do	

			if(type(v) == "table") then --variable is a table (count is not table)
				if(v.parents) then -- if no parents, then no smell
					smellTable = smellTable .. utils.drawParentTree(v.parents, s.file, "Table")
				end
			end
		end
	
	end

	return smellTable

end


local function createUpvaluesTable(globalMetrics)

	--Create table header
	local smellTable = utils.createTable("smell_table", {"File path", "Function name", "Upvalue", "Number of uses"})	

	for _, s in pairs(globalMetrics.documentSmells.smellsTable) do
		for k, v in pairs(s.upvalues.info) do
			color = "WHITE"
			smellTable = smellTable .. utils.addTableRow({s.file, v.functionName, v.varName, v.usages}, true, color)			
		end
	end

	--Close table
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end


--- Function creates a Bar graph presenting long method smell
-- @param globalMetrics Global metrics of project
-- @param withLink If JavaScript script should be concated (May be used as standalone graph)
-- @author Martin Nagy
-- @return Bar graph presenting long method smell
local function createLongMethodGraph(globalMetrics, withScript)
	
	local seriesData1 = ""
	local seriesData2 = ""
	local xAxis = ""

	--Loop to create series from data
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.longMethod) do
		xAxis = xAxis .. "'" .. n.name .. "', " --Name of functions to x axis
		seriesData1 = seriesData1 .. n.LOC .. ", " --Lines of code in function
		seriesData2 = seriesData2 .. n.LOSC .. ", " --Lines of source code in function
	end

	--Create graph
	return utils.createBarGraph('Lines of code in functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Lines of code', {'Total', 'Source code'}, {seriesData1, seriesData2}, 45, 55, withScript)

end

--- Function creates a Bar graph presenting cyclomatic complexity
-- @param globalMetrics Global metrics of project
-- @param withLink If JavaScript script should be concated (May be used as standalone graph)
-- @author Martin Nagy
-- @return Bar graph presenting cyclomatic complexity
local function createCycloGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.cyclomatic) do
		xAxis = xAxis .. "'" .. n.name .. "', " --Name of functions to x axis
		seriesData = seriesData .. n.cyclomatic .. ", " --Cyclomatic complexity in function
	end

	--Create graph
	return utils.createBarGraph('Cyclomatic complexity of functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Cyclomatic complexity', {'Cyclomatic complexity'}, {seriesData}, 11, 21, withScript)

end

--- Function creates a Bar graph presenting many parameters smell
-- @param globalMetrics Global metrics of project
-- @param withLink If JavaScript script should be concated (May be used as standalone graph)
-- @author Martin Nagy
-- @return Bar graph presenting many parameters smell
local function createManyParamsGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data
	for _, n in pairs(globalMetrics.documentSmells.functionSmells.manyParameters) do
		xAxis = xAxis .. "'" .. n.name .. "', " --Name of functions to x axis
		seriesData = seriesData .. n.NOA .. ", " --Cyclomatic complexity in function
	end

	--Create graph
	return utils.createBarGraph('Number of parameters in functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Number of Parameters', {'Number of Parameters'}, {seriesData}, 5, 10, withScript)

end

local function createLongLinesGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data
	for k, v in pairs(globalMetrics.documentSmells.moduleSmells) do
		xAxis = xAxis .. "'" .. v.file .. "', " --Name of functions to x axis
		seriesData = seriesData .. #v.longLines .. ", " --Count of long lines in file
	end

	--Create graph
	return utils.createBarGraph('Count of long lines in modules', '', #globalMetrics.documentSmells.moduleSmells, xAxis, 'Count of long lines', {'Count of long lines'}, {seriesData}, 2, 7, withScript)

end

local function createTablesWithManyFieldsGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data	
	for k, v in pairs(globalMetrics.documentSmells.smellsTable) do
		if(v.smells.tableSmells.manyFields) then -- when smells were detected
			xAxis = xAxis .. "'" .. v.file .. "', " --Name of functions to x axis
			seriesData = seriesData .. v.smells.tableSmells.manyFields.count .. ", " --Count of tables with many fields in file
		end		
	end

	--Create graph
	return utils.createBarGraph('Count of tables with many fields in modules', '',  #globalMetrics.documentSmells.smellsTable , xAxis, 'Count of tables with many fields', {'Count of tables with many fields'}, {seriesData}, 2, 7, withScript)

end

local function createFunctionDepthGraph(globalMetrics, withScript)
			
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data	
	for k, v in pairs(globalMetrics.documentSmells.smellsTable) do
		if(v.smells.functionSmells) then -- when smells were detected
			xAxis = xAxis .. "'" .. v.file .. "', " --Name of functions to x axis
			seriesData = seriesData .. v.smells.functionSmells.count .. ", " --Count of tables with many fields in file
		end		
	end

	--Create graph
	return utils.createBarGraph('Count of function with high nesting level', '',  #globalMetrics.documentSmells.smellsTable , xAxis, 'Count of function with high nesting level', {'Count of function with high nesting level'}, {seriesData}, 2, 7, withScript)

end

local function createTableDepthGraph(globalMetrics, withScript)
		
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data	
	for k, v in pairs(globalMetrics.documentSmells.smellsTable) do
		if(v.smells.tableSmells.depth) then -- when smells were detected
			xAxis = xAxis .. "'" .. v.file .. "', " --Name of functions to x axis
			seriesData = seriesData .. v.smells.tableSmells.depth.count .. ", " --Count of tables with many fields in file
		end		
	end

	--Create graph
	return utils.createBarGraph('Count of tables with high nesting level', '',  #globalMetrics.documentSmells.smellsTable , xAxis, 'Count of tables with high nesting level', {'Count of tables with high nesting level'}, {seriesData}, 2, 7, withScript)

end


local function createUpvaluesGraph(globalMetrics, withScript)
			
	local seriesData = ""
	local xAxis = ""

	--Loop to create series from data	
	for k, v in pairs(globalMetrics.documentSmells.smellsTable) do
			xAxis = xAxis .. "'" .. v.file .. "', " --Name of functions to x axis
			seriesData = seriesData .. #v.upvalues.info .. ", " --Count of tables with many fields in file
				
	end

	--Create graph
	return utils.createBarGraph('Count of variables with upvalue', '',  #globalMetrics.documentSmells.smellsTable , xAxis, 'Count of upvalues', {'Total variables with upvalue'}, {seriesData}, 5, 10, withScript)
end

return {
	createLongMethodTable = createLongMethodTable,
	createCycloTable = createCycloTable,
	createManyParamsTable = createManyParamsTable,
	createModuleTables = createModuleTables,
	createMITable = createMITable,
	createLongLinesTable = createLongLinesTable,
	createTablesWithManyFieldsTable = createTablesWithManyFieldsTable,
	createFunctionDepthTable = createFunctionDepthTable,
	createTableDepthTable = createTableDepthTable,
	createUpvaluesTable = createUpvaluesTable,

	createLongMethodGraph = createLongMethodGraph,
	createCycloGraph = createCycloGraph,
	createManyParamsGraph = createManyParamsGraph,
	createLongLinesGraph = createLongLinesGraph,
	createTablesWithManyFieldsGraph = createTablesWithManyFieldsGraph,
	createFunctionDepthGraph = createFunctionDepthGraph,
	createTableDepthGraph = createTableDepthGraph,
	createUpvaluesGraph = createUpvaluesGraph,
}