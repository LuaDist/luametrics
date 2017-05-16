local function getGraph()

	local f = io.input('../lib/lua/metrics/templates/css/highcharts.js')
	local result = f:read("*a")
	f:close()

	return result

end

local function getjQuerryJS()

	local f = io.input('../lib/lua/metrics/templates/css/jquery.js')
	local jquery = f:read("*a")
	f:close()

	local result = "<script type='text/javascript'>" .. jquery .. "</script>"

	return result

end

local function getSmellTable()

	local f = io.input('../lib/lua/metrics/templates/css/smellTable.css')
	local result = f:read("*a")
	f:close()

	return result

end

local function getMetricsTable()

	local f = io.input('../lib/lua/metrics/templates/css/metricsTable.css')
	local result = f:read("*a")
	f:close()

	return result

end

local function getjQuerryTable()

	local f = io.input('../lib/lua/metrics/templates/css/jQueryTable.css')
	local result = f:read("*a")
	f:close()

	return result

end

local function getTabs(id, margin)

	local f = io.input('../lib/lua/metrics/templates/css/tabs.css')
	local result = f:read("*a")
	f:close()

	return  "#tabs" .. id .. " { margin-top:" .. margin .. "px; }" .. result

end

return {
	getSmellTable = getSmellTable,
	getGraph = getGraph,
	getMetricsTable = getMetricsTable,
	getjQuerryTable = getjQuerryTable,
	getjQuerryJS = getjQuerryJS,
	getTabs = getTabs
}