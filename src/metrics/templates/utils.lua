local tablesCSS = require 'metrics.templates.css.smellTable'

local function round(num)
	
	return math.floor(num * 100 + 0.5) / 100
	
end

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

	text = text:gsub("&", "&amp;");
  	text = text:gsub("&#", "&#38;&#35;");
	text = text:gsub("<", "&lt;");
	text = text:gsub(">", "&gt;");
	text = text:gsub("\"", "&#34;");
	text = text:gsub("'", "&#39;");

	return text;

end

local function addTableCSS(tableClass)

	local result = "<style>"

	if(tableClass == "smell_table") then
		result = result .. tablesCSS.getSmellTable()
	elseif(tableClass == "metric_index") then
		result = result .. tablesCSS.getMetricsTable()
	elseif(tableClass == "tabs") then
		result = result .. tablesCSS.getjQuerryTable()
		result = result .. tablesCSS.getTabs("", 50)
	elseif(tableClass == "tabs2") then
		result = result .. tablesCSS.getjQuerryTable()
		result = result .. tablesCSS.getTabs("2", 10)
	elseif(tableClass == "tabs3") then
		result = result .. tablesCSS.getjQuerryTable()
		result = result .. tablesCSS.getTabs("3", 10)
	end

	return result .. "</style>"

end

local function createTable(tableClass, collumnNames, style)
	
	local result = addTableCSS(tableClass)
	local style = style or ""

	result = result .. "<table class='" .. tableClass .. "' style='" .. style .. "'><tr>"

	for i = 1, #collumnNames do
		result = result .. "<th>" .. collumnNames[i] .. "</th>"
	end

	result = result .. "</tr>"

	return result

end

local function closeTable()
	return "</table>"
end

local function addTableRow(collumns, withLink, color)

	local result = "<tr>"
	local start = 1
	local bg = color or "WHITE"

	if(withLink) then
		result = result .. "<td class='file'>" .. 
			"<img src='../fileIcon.jpg' title='" .. collumns[1] .. "' />" ..
			"</td>"
		start = 2
	end

		result = result .. "<td class='name' nowrap>" .. collumns[start] .. "</td>"

	for i = start + 1, #collumns do
		result = result .. "<td class='value' bgcolor='" .. bg .. "'><center>" .. collumns[i] .. "</center></td>" 
	end

	result = result .. "</tr>"

	return result

end

local function createBarGraph(title, subtitle, height, xAxis, yAxis, seriesName, seriesData, green, orange, withScript)
	
	local result = ""
	local div = "bar_graph_" .. math.random(2, 955)
	local graphHeight = height * 20

	result = result .. "<div id='" .. div .. "' style='width: 800px; height: " .. graphHeight .. "px; min-height: 400px; margin: 0 auto'></div><script>"

	if(withScript or withScript == nil) then
		result = result .. tablesCSS.getGraph()
	end

	result = result .. "Highcharts.chart('" .. div .. "', { chart: { type: 'bar' }, " ..
		"title: { text: '" .. title .. "' }, subtitle: { text: '" .. subtitle .. "' }, " ..
		"xAxis: { categories: [ " .. xAxis .. " ], title: { text: null } }, " ..
		"yAxis: { min: 0, title: { text: '" .. yAxis .. "', align: 'high' }, labels: { overflow: 'justify' } }, " ..
		"plotOptions: { bar: { dataLabels: { enabled: true } } }, " ..
		"legend: { layout: 'vertical', align: 'right', verticalAlign: 'top', x: -40, y: 80, floating: true, borderWidth: 1, backgroundColor: '#FFFFFF', shadow: true }, " ..
		"credits: { enabled: true }, " ..
		"series: ["

		for i = 1, #seriesName do

			result = result .. "{ name: '" .. seriesName[i] .. "', data: [" .. seriesData[i] .. "]," ..
				"zones: [{ value: " .. green .. ", color: 'green'}, " ..
					"{ value: " .. orange .. ", color: 'orange'}, " ..
					"{ color: 'red' }]},"

		end

		result = result .. "]});</script>"

		return result

end

local function createPieGraph(title, data, withScript)
 
	local result = ""
	local div = "pie_graph_" .. math.random(2, 955)

	result = result .. "<div style='margin: 20px;' id='" .. div .. "'></div><script>"

	if(withScript or withScript == nil) then
		result = result .. tablesCSS.getGraph()
	end

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

local function getSortedTable(definitions)

	local letterTable = {}
	local sortedTable = {}

	for _, fun in ipairs(definitions) do

		local firstLetter = string.char(string.byte(fun.name))

		if(firstLetter ~= "#") then

			if (letterTable[firstLetter] == nil) then letterTable[firstLetter] = {} end
			table.insert(letterTable[firstLetter], fun)

		end
	end
	
	for key in pairs(letterTable) do table.insert(sortedTable, key) end
	table.sort(sortedTable)

	return sortedTable, letterTable

end

local function drawFunctionTree(node, filepath)

	local result = ""

	for _ ,fun in pairs(node.metrics.functiontree) do

		result = result .. "<li>"
			
		if (#fun.metrics.functiontree > 0) then
			result = result .. "<a href='#' class='toggler' onclick='return menu_toggle(this);'>[+]</a>"
		end

		result = result .. fun.fcntype .. "<a href='#|type=fileLink|to=" .. filepath .. "|from=functionlist/index.html|#" .. "#" ..
			fun.name .. "'>" .. fun.name .. "</a><ul style='list-style-type: none;'>" ..
			drawFunctionTree(fun, filepath, fileLink) .. "</ul></li>"

	end

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
	getPagesAndList = getPagesAndList,
	round = round,
	replaceSpecials = replaceSpecials,
	addTableCSS = addTableCSS
}