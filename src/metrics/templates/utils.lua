--- Function rounds number to 2 decimal places
-- @param num Number to round
-- @author Martin Nagy
-- @return Number rounded to 2 decimal places
local function round(num)
	
	return math.floor(num * 100 + 0.5) / 100
	
end

--- Function rreads whole file and returns content
-- @param _sFileName Path to file to read
-- @author Martin Nagy
-- @return Content of file
local function readFile(_sFileName)

	local f = io.input(_sFileName)
	local sData_ = f:read("*a")
	f:close()
	return sData_

end

--- Function replaces special characters to HTML encoding
-- @param text String to analyze
-- @author Martin Nagy
-- @return String with replaced characters to HTML encoding
local function replaceSpecials(text)

	if text ~= nil then
		text = text:gsub(lfs.currentdir(), "")
	end

	if(text == nil) then
		return nil;
	end

	if(type(text) ~= "string") then
		return text;
	end

	--replace there characters with their equivalents in HTML
	text = text:gsub("&", "&amp;");
  	text = text:gsub("&#", "&#38;&#35;");
	text = text:gsub("<", "&lt;");
	text = text:gsub(">", "&gt;");
	text = text:gsub("\"", "&#34;");
	text = text:gsub("'", "&#39;");

	return text;

end

--- Function reads a file containing javascript code needed to create graphs
-- @author Martin Nagy
-- @return Javascript code
local function getGraph()

	return readFile('../share/luametrics/highcharts.js')

end

--- Function reads a file containing javascript code needed to create clickable tabs
-- @author Martin Nagy
-- @return Javascript code wraped in script tag
local function getjQuerryJS()

	local jquery =  readFile('../share/luametrics/jquery.js')

	local result = "<script type='text/javascript'>" .. jquery .. "</script>"

	return result

end

--- Function reads a file containing css styles of tables used to present code smells
-- @author Martin Nagy
-- @return CSS styles
local function getSmellTable()

	return readFile('../share/luametrics/smellTable.css')

end

--- Function reads a file containing css styles of tables used to present project metrics
-- @author Martin Nagy
-- @return CSS styles
local function getMetricsTable()

	return readFile('../share/luametrics/metricsTable.css')

end

--- Function reads a file containing css styles of clickable tabs
-- @author Martin Nagy
-- @return CSS styles
local function getjQuerryTable()

	return readFile('../share/luametrics/jQueryTable.css')

end

--- Function reads a file containing css styles of tables used to present list of functions or tables
-- @author Martin Nagy
-- @return CSS styles
local function getTabs(id, margin)

	local result = readFile('../share/luametrics/tabs.css')

	return  "#tabs" .. id .. " { margin-top:" .. margin .. "px; }" .. result

end

--- Function calls other functions to read needed CSS styles from file sources
-- @param tableClass CSS Class to determine which CSS styles to read
-- @author Martin Nagy
-- @return CSS styles of needed CSS classes wraped in style HTML tag
local function addTableCSS(tableClass)

	local result = "<style>"

	if(tableClass == "smell_table") then
		result = result .. getSmellTable()
	elseif(tableClass == "metric_index") then
		result = result .. getMetricsTable()
	elseif(tableClass == "tabs") then
		result = result .. getjQuerryTable()
		result = result .. getTabs("", 50)
	elseif(tableClass == "tabs2") then
		result = result .. getjQuerryTable()
		result = result .. getTabs("2", 10)
	elseif(tableClass == "tabs3") then
		result = result .. getjQuerryTable()
		result = result .. getTabs("3", 10)
	end

	return result .. "</style>"

end

--- Function creates a header for HTML table
-- @param tableClass CSS Class of table (design)
-- @param collumnNames List of names of collumns
-- @param style Aditional CSS styles
-- @author Martin Nagy
-- @return table template header
local function createTable(tableClass, collumnNames, style)
	
	local result = addTableCSS(tableClass) --Add CSS styles from file to template
	local style = style or ""

	--Create HTML table starting tag with table row starting tag
	result = result .. "<table class='" .. tableClass .. "' style='" .. style .. "'><tr>"

	for i = 1, #collumnNames do --Add each collumn to template
		result = result .. "<th>" .. collumnNames[i] .. "</th>"
	end

	result = result .. "</tr>" --Close table row tag

	return result

end

--- Function closes table HTML tag 
-- @author Martin Nagy
-- @return Closing table HTML tag
local function closeTable()
	return "</table>"
end

--- Function adds row to pre-prepared table header HTML template
-- @param collumns Data to be inserted in collumns of a row
-- @param withLink If link to a file will be provided in first collumn (smell tables)
-- @param color Special color of data collumns
-- @author Martin Nagy
-- @return Table row HTML template
local function addTableRow(collumns, withLink, color)

	local result = "<tr>" --Starting HTML tag of the row
	local start = 1
	local bg = color or "WHITE" --Default color of data collumns

	if(withLink) then --If link to the file will be provided in first collumn
		result = result .. "<td class='file'>" .. 
			"<img src='../fileIcon.jpg' title='" .. collumns[1] .. "' />" ..
			"</td>"
		start = 2
	end

	result = result .. "<td class='name' nowrap>" .. collumns[start] .. "</td>" --Name of the data in the row

	for i = start + 1, #collumns do --For each data entry create new collumn in table, with background set
		result = result .. "<td class='value' bgcolor='" .. bg .. "'><center>" .. collumns[i] .. "</center></td>" 
	end

	result = result .. "</tr>" --Close HTML tag of the row

	return result

end

--- Function create template of Bar Graph
-- @param title Graph title
-- @param subtitle Graph subtitle
-- @param height Minimal graph height
-- @param xAxis Title of X axis
-- @param yAxis Title of Y axis
-- @param seriesName Name of the series of data
-- @param seriesData Data contained in each serie
-- @param green Criteria set to color data entry to green color
-- @param orange Criteria set to color data entry to orange color
-- @param withScript If result will be used as standalone graph or as a part of the LuaDocer documentation
-- @author Martin Nagy
-- @return Graph HTML template with or without JS script
local function createBarGraph(title, subtitle, height, xAxis, yAxis, seriesName, seriesData, green, orange, withScript)
	
	local result = ""
	local div = "bar_graph_" .. math.random(2, 955) --Random graph ID to prevent errors when more graphs will be on one site
	local graphHeight = height * 20

	--Create box where graph will be rendered
	result = result .. "<div id='" .. div .. "' style='width: 800px; height: " .. graphHeight .. "px; min-height: 400px; margin: 0 auto'></div><script>"

	if(withScript or withScript == nil) then --Include JavaScript script from file
		result = result .. getGraph()
	end

	--Create graph object in JavaScript
	result = result .. "Highcharts.chart('" .. div .. "', { chart: { type: 'bar' }, " ..
		"title: { text: '" .. title .. "' }, subtitle: { text: '" .. subtitle .. "' }, " ..
		"xAxis: { categories: [ " .. xAxis .. " ], title: { text: null } }, " ..
		"yAxis: { min: 0, title: { text: '" .. yAxis .. "', align: 'high' }, labels: { overflow: 'justify' } }, " ..
		"plotOptions: { bar: { dataLabels: { enabled: true } } }, " ..
		"legend: { layout: 'vertical', align: 'right', verticalAlign: 'top', x: -40, y: 80, floating: true, borderWidth: 1, backgroundColor: '#FFFFFF', shadow: true }, " ..
		"credits: { enabled: true }, " ..
		"series: ["

		for i = 1, #seriesName do --Add series to object with color borders of data values

			result = result .. "{ name: '" .. seriesName[i] .. "', data: [" .. seriesData[i] .. "]," ..
				"zones: [{ value: " .. green .. ", color: 'green'}, " ..
					"{ value: " .. orange .. ", color: 'orange'}, " ..
					"{ color: 'red' }]},"

		end

		result = result .. "]});</script>" -- Close JavaScript object and HTML script tag

		return result

end

--- Function create template of Pie Graph
-- @param title Graph title
-- @param data Data to be added to graph
-- @param withScript If result will be used as standalone graph or as a part of the LuaDocer documentation
-- @author Martin Nagy
-- @return Graph HTML template with or without JS script
local function createPieGraph(title, data, withScript)
 
	local result = ""
	local div = "pie_graph_" .. math.random(2, 955)	--Random graph ID to prevent errors when more graphs will be on one site

	--Create box where graph will be rendered
	result = result .. "<div style='margin: 20px;' id='" .. div .. "'></div><script>"

	if(withScript or withScript == nil) then --Include JavaScript script from file
		result = result .. getGraph()
	end

	--Create graph object in JavaScript with specified data and closing HTML script tag
	result = result .. "Highcharts.chart('" .. div .. "', {" ..
        "chart: { plotBackgroundColor: null, plotBorderWidth: null, plotShadow: false, type: 'pie' }," ..
        "title: { text: '" .. title .. "' }," ..
        "tooltip: { formatter: function() { return '<b>' + this.point.name + '</b>: ' + this.y + ' lines'; } }," ..
        "plotOptions: { pie: { allowPointSelect: true, cursor: 'pointer'," ..
            "dataLabels: { enabled: true }, showInLegend: true } }," ..
        "series: [{ type: 'pie', name: 'Lines', colorByPoint: true," ..
			"data: [" .. data .. "]}]});</script>"

	return result

end

--- Function creates a sorted table alphabeticaly by starting character
-- @param definitions Functions to be sorted
-- @author Martin Nagy
-- @return Table with starting letters of functions
-- @return Table containing functions sorted alphabeticaly based on starting character
local function getSortedTable(definitions)

	local letterTable = {}
	local sortedTable = {}

	for _, fun in ipairs(definitions) do --Loop throung functions

		local firstLetter = string.char(string.byte(fun.name)) --Get first letter

		if(firstLetter ~= "#") then

			if (letterTable[firstLetter] == nil) then letterTable[firstLetter] = {} end --If subtable does not exist create one
			table.insert(letterTable[firstLetter], fun) --Add function name to table under starting letter

		end
	end
	
	for key in pairs(letterTable) do table.insert(sortedTable, key) end --Add starting letters to letterTable
	table.sort(sortedTable)

	return sortedTable, letterTable

end

--- Function creates a tree structure where each file of project contains functions in this file
-- @param node Node in AST of file where functions are contained
-- @param filepath Path to file where functions are contained
-- @author Martin Nagy
-- @return Tree structure created based on files in project
local function drawFunctionTree(node, filepath)

	local result = ""

	for _ ,fun in pairs(node.metrics.functiontree) do --Loop throung function trees under project

		result = result .. "<li>"
			
		if (#fun.metrics.functiontree > 0) then --If file contains functions create header with filename
			result = result .. "<a href='#' class='toggler' onclick='return menu_toggle(this);'>[+]</a>"
		end

		--Add functions with links to documentation contained in file
		result = result .. fun.fcntype .. "<a href='#|type=fileLink|to=" .. filepath .. "|from=functionlist/index.html|#" .. "#" ..
				fun.name .. "'>" .. fun.name .. "</a><ul style='list-style-type: none;'>" ..
				drawFunctionTree(fun, filepath, fileLink) .. "</ul></li>" --Trying to go one level deeper (submodule in module)

	end

	return result

end

--- Function creates a tree structure where nested function have function parent
-- @param parents Table with parents of function
-- @author Dominik Stevlik
-- @return Tree structure created based function parents
local function drawParentTree(parents, prefix)

	if(not prefix) then prefix = "" end

	local result = ""
	local endTags = ""

	if(#parents == 0) then
		return ""
	end

	result = result .. "<ul class='menulist' style='list-style-type: none;'><li><a href='#' class='toggler' onclick='return parent_toggle(this);'>[+]</a> " 
			.. prefix .. " " .. parents[#parents] .. " is nested in:"
	endTags = "</li></ul>" .. endTags

	for _ ,p in pairs(parents) do --Loop throung parents trees under project
		result = result .. "<ul style='list-style-type: none; display:none;'><li> "
		if(p ~= parents[#parents]) then
			result = result .. "<a href='#' class='toggler' onclick='return parent_toggle(this);'>[+]</a> "
		end
		result = result .. prefix .. " " .. p
		endTags = "</li></ul>" .. endTags
	end

	result = result .. endTags

	return result

end

return {
	createTable = createTable,
	closeTable = closeTable,
	addTableRow = addTableRow,
	createBarGraph = createBarGraph,
	createPieGraph = createPieGraph,
	getSortedTable = getSortedTable,
	drawFunctionTree = drawFunctionTree,
	round = round,
	replaceSpecials = replaceSpecials,
	addTableCSS = addTableCSS,
	readFile = readFile,
	getjQuerryJS = getjQuerryJS,
	drawParentTree = drawParentTree
}