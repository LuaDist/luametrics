local utils = require 'metrics.templates.utils'

local function createLongMethodTable(globalMetrics)

	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Lines of code", "Lines of source code"})

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.longMethod) do

		local color = nil

		if(n.LOSC > 55) then color = "RED" elseif(n.LOSC >= 45) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.LOC, n.LOSC}, true, color)

	end

	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createCycloTable(globalMetrics)

	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Cyclomatic complexity"})

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.cyclomatic) do

		local color = nil

		if(n.cyclomatic > 20) then color = "RED" elseif(n.cyclomatic >= 11) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.cyclomatic}, true, color)

	end

	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createManyParamsTable(globalMetrics)

	local smellTable = utils.createTable("smell_table", {"File path", "Function", "Number of Parameters"})

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.manyParameters) do

		local color = nil

		if(n.NOA > 10) then color = "RED" elseif(n.NOA >= 5) then color = "ORANGE" else color = "GREEN" end

		smellTable = smellTable .. utils.addTableRow({n.file, n.name, n.NOA}, true, color)

	end

	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createModuleTables(globalMetrics)

	local result = ""

	for _, s in pairs(globalMetrics.documentSmells.moduleSmells) do 

		result = result .. "<div style='float:left; display: block'><h3>" .. s.file .. "</h3>"

		local smellTable = utils.createTable("smell_table", {"Criteria", "Value"})
		local count = 0

		local color = nil
		if(s.RFC > 100) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Response for module", s.RFC}, false, color)

		color = nil
		if(s.CBO > 5) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Coupling between modules", s.CBO}, false, color)

		color = nil
		if(s.responseToNOM > 5) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Response for module / number of methods", s.responseToNOM}, false, color)

		color = nil
		if(s.WMC > 100) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Weighted methods per module", s.WMC}, false, color)

		color = nil
		if(s.NOM > 40) then color = "ORANGE" count = count + 1 else color = "GREEN" end
		smellTable = smellTable .. utils.addTableRow({"Number of methods", s.NOM}, false, color)

		if(count > 1) then
			smellTable = smellTable .. utils.addTableRow({"Result", "Refactor!"}, false, "ORANGE")
		else
			smellTable = smellTable .. utils.addTableRow({"Result", "O.K."}, false, "GREEN")
		end

		smellTable = smellTable .. utils.closeTable()

		result = result .. smellTable

		result = result .. "</div><div style='clear:both;'></div>"

	end

	return result

end

local function createMITable(globalMetrics)

	local smellTable = "<p><table class='smell_table'>"
	local MI = globalMetrics.documentSmells.MI
	local color = nil

	if(MI < 65) then color = "RED" elseif(MI < 85) then color = "ORANGE" else color = "GREEN" end
	smellTable = smellTable .. utils.addTableRow({"Maintainability index", MI}, false, color)

	smellTable = smellTable .. utils.closeTable() .. "</p>"

	smellTable = smellTable .. utils.createTable("smell_table", {"Maintainability", "Score"})
	smellTable = smellTable .. utils.addTableRow({"Highly maintainable", ">85"}, false, "GREEN")
	smellTable = smellTable .. utils.addTableRow({"Moderately maintainable", ">65 and <85"}, false, "ORANGE")
	smellTable = smellTable .. utils.addTableRow({"Difficult to maintain", "<65"}, false, "RED")
	smellTable = smellTable .. utils.closeTable()

	return smellTable

end

local function createLongMethodGraph(globalMetrics, withScript)
	
	local seriesData1 = ""
	local seriesData2 = ""
	local xAxis = ""

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.longMethod) do
		xAxis = xAxis .. "'" .. n.name .. "', "
		seriesData1 = seriesData1 .. n.LOC .. ", "
		seriesData2 = seriesData2 .. n.LOSC .. ", "
	end

	return utils.createBarGraph('Lines of code in functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Lines of code', {'Total', 'Source code'}, {seriesData1, seriesData2}, 45, 55, withScript)

end

local function createCycloGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.cyclomatic) do
		xAxis = xAxis .. "'" .. n.name .. "', "
		seriesData = seriesData .. n.cyclomatic .. ", "
	end

	return utils.createBarGraph('Cyclomatic complexity of functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Cyclomatic complexity', {'Cyclomatic complexity'}, {seriesData}, 11, 21, withScript)

end

local function createManyParamsGraph(globalMetrics, withScript)
	
	local seriesData = ""
	local xAxis = ""

	for _, n in pairs(globalMetrics.documentSmells.functionSmells.manyParameters) do
		xAxis = xAxis .. "'" .. n.name .. "', "
		seriesData = seriesData .. n.NOA .. ", "
	end

	return utils.createBarGraph('Number of parameters in functions', '(Sorted descending)', globalMetrics.documentSmells.functionSmells.totalFunctions, xAxis, 'Number of Parameters', {'Number of Parameters'}, {seriesData}, 5, 10, withScript)

end

return {
	createLongMethodTable = createLongMethodTable,
	createCycloTable = createCycloTable,
	createManyParamsTable = createManyParamsTable,
	createModuleTables = createModuleTables,
	createMITable = createMITable,
	createLongMethodGraph = createLongMethodGraph,
	createCycloGraph = createCycloGraph,
	createManyParamsGraph = createManyParamsGraph
}