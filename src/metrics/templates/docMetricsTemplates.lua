local utils = require 'metrics.templates.utils'

local function createLOCTable(LOC, fileNum, moduleNum)

	local metricsTable = utils.createTable("metric_index", {"Lines of code", "Value"})

	if (fileNum and moduleNum) then
		metricsTable = metricsTable .. utils.addTableRow({"Number of files", fileNum}, false)
		metricsTable = metricsTable .. utils.addTableRow({"Number of modules", moduleNum}, false)
	end

	metricsTable = metricsTable .. utils.addTableRow({"Lines Total", LOC.lines}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Executable code lines", LOC.lines_code}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Commented lines", LOC.lines_comment}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Blank lines", LOC.lines_blank}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Nonempty lines", LOC.lines_nonempty}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Comment percentage", utils.round(LOC.lines_comment / LOC.lines_code) * 100 .. "%"}, false)

	metricsTable = metricsTable .. utils.closeTable()

	return metricsTable

end

local function createDocMetricsTable(documentMetrics)
	
	if ((documentMetrics.nondocumentedTablesCounter + documentMetrics.documentedTablesCounter) ~= 0) then
		commTablePercentage = utils.round(documentMetrics.documentedTablesCounter/(documentMetrics.nondocumentedTablesCounter + documentMetrics.documentedTablesCounter))*100 
	else
		commTablePercentage = 0
	end
	if((documentMetrics.nondocumentedFunctionsCounter + documentMetrics.documentedFunctionsCounter)~=0)then
		commFunctionPercentage = utils.round(documentMetrics.documentedFunctionsCounter/(documentMetrics.nondocumentedFunctionsCounter + documentMetrics.documentedFunctionsCounter))*100
	else
		commFunctionPercentage = 0
	end

	local metricsTable = utils.createTable("metric_index", {"Document metrics", "Value"})

	metricsTable = metricsTable .. utils.addTableRow({"Number of all documented functions", documentMetrics.documentedFunctionsCounter}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of all nondocumented functions", documentMetrics.nondocumentedFunctionsCounter}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Documented function percentage", commFunctionPercentage .. "%"}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of all documented tables", documentMetrics.documentedTablesCounter}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of all nondocumented tables", documentMetrics.nondocumentedTablesCounter}, false) 
	metricsTable = metricsTable .. utils.addTableRow({"Documented table percentage", commTablePercentage .. "%"}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of TODO comments", #documentMetrics.todos}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of bug comments", #documentMetrics.bugs}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of question comments", #documentMetrics.questions}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of fixme comments", #documentMetrics.fixmes}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of how comments", #documentMetrics.hows}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of info comments", #documentMetrics.infos}, false)

	metricsTable = metricsTable .. utils.closeTable()

	return metricsTable

end

local function createHalsteadTable(halstead)
	
	local metricsTable = utils.createTable("metric_index", {"Halstead metrics", "Value"})

	metricsTable = metricsTable .. utils.addTableRow({"Number of operators", halstead.number_of_operators}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of operands", halstead.number_of_operands}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of unique operators", halstead.unique_operators}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of unique operands", halstead.unique_operands}, false)
	metricsTable = metricsTable .. utils.addTableRow({"LTH - Halstead length", utils.round(halstead.LTH)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"VOC - Halstead vocabulary", utils.round(halstead.VOC)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"DIF - Halstead difficulty", utils.round(halstead.DIF)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"VOL - Halstead volume", utils.round(halstead.VOL)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"EFF - Halstead Effort", utils.round(halstead.EFF)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"BUG - Halstead bugs", utils.round(halstead.BUG)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Time - Halstead Time", utils.round(halstead.time)}, false)

	metricsTable = metricsTable .. utils.closeTable()

	return metricsTable

end

local function createStatementsTable(statements)
	
	local metricsTable = utils.createTable("metric_index", {"Statement usage", "Value"})

	for name, stats in pairs(statements) do

		metricsTable = metricsTable .. utils.addTableRow({name, #stats}, false)

	end

	metricsTable = metricsTable .. utils.closeTable()

	return metricsTable

end

local function createFunctionsTable(globalMetrics, fileNum)

	local funDefinitions = globalMetrics.functionDefinitions
	local file_AST_list = globalMetrics.file_AST_list

	count_all = #funDefinitions
	count_global = 0
	count_local = 0
	
	count_lines = 0
	count_lines_code = 0
	count_lines_comment = 0
	count_lines_blank = 0
	count_lines_nonempty = 0
	
	count_global_lines = 0
	count_global_lines_code = 0
	count_global_lines_comment = 0
	count_global_lines_blank = 0
	count_global_lines_nonempty = 0
	
	count_local_lines = 0
	count_local_lines_code = 0
	count_local_lines_comment = 0
	count_local_lines_blank = 0
	count_local_lines_nonempty = 0
		
	
	for _, fun in pairs(funDefinitions) do
		if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction') then 
			count_lines         = count_lines             + fun.metrics.LOC.lines
			count_lines_code    = count_lines_code        + fun.metrics.LOC.lines_code
			count_lines_comment = count_lines_comment + fun.metrics.LOC.lines_comment
			count_lines_blank = count_lines_blank     + fun.metrics.LOC.lines_blank
			count_lines_nonempty= count_lines_nonempty    + fun.metrics.LOC.lines_nonempty
	
			if (fun.isGlobal) then 
				count_global = count_global + 1
				count_global_lines            = count_global_lines            + fun.metrics.LOC.lines
				count_global_lines_code     = count_global_lines_code     + fun.metrics.LOC.lines_code
				count_global_lines_comment    = count_global_lines_comment    + fun.metrics.LOC.lines_comment
				count_global_lines_blank    = count_global_lines_blank        + fun.metrics.LOC.lines_blank
				count_global_lines_nonempty = count_global_lines_nonempty + fun.metrics.LOC.lines_nonempty
			else 
				count_local = count_local + 1
				count_local_lines             = count_local_lines             + fun.metrics.LOC.lines
				count_local_lines_code        = count_local_lines_code        + fun.metrics.LOC.lines_code
				count_local_lines_comment     = count_local_lines_comment + fun.metrics.LOC.lines_comment
				count_local_lines_blank     = count_local_lines_blank     + fun.metrics.LOC.lines_blank
				count_local_lines_nonempty    = count_local_lines_nonempty    + fun.metrics.LOC.lines_nonempty
			end
		end
	end
	
	
	if (file_AST_list) then -- which file has the most number of functions (and the least number)
		min_fun_in_modulem, max_fun_in_module = nil, nil
		for filename, AST in pairs(file_AST_list) do
			if (max_fun_in_module == nil) then max_fun_in_module = { AST.metrics.currentModuleName or filename, #AST.metrics.functionDefinitions } end
			if (min_fun_in_module == nil) then min_fun_in_module = { AST.metrics.currentModuleName or filename, #AST.metrics.functionDefinitions } end
			
			if (max_fun_in_module[2] <    #AST.metrics.functionDefinitions ) then
				max_fun_in_module = { AST.metrics.currentModuleName or filename,    #AST.metrics.functionDefinitions }
			end
			if (min_fun_in_module[2] >    #AST.metrics.functionDefinitions ) then
				min_fun_in_module = { AST.metrics.currentModuleName or filename,    #AST.metrics.functionDefinitions }
			end
			
		end
	end

	local metricsTable = utils.createTable("metric_index", {"Function metrics", "Value"}, "width: 570px;")

	metricsTable = metricsTable .. utils.addTableRow({"Number of all functions", count_all}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of all global functions", count_global}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Number of all local functions", count_local}, false)
	
	if (fileNum) then
	
		metricsTable = metricsTable .. utils.addTableRow({"Average number of functions per file", utils.round(count_all / fileNum)}, false)
		metricsTable = metricsTable .. utils.addTableRow({"Average number of global function per file", utils.round(count_global / fileNum)}, false)
		metricsTable = metricsTable .. utils.addTableRow({"Average number of local functions per file", utils.round(count_local / fileNum)}, false)
	
	end    
	if (count_all>0) then
	metricsTable = metricsTable .. utils.addTableRow({"Average number of lines for function", utils.round(count_lines / count_all)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of code lines for function", utils.round(count_lines_code / count_all)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of comment lines for function", utils.round(count_lines_comment / count_all)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of blank lines for function", utils.round(count_lines_blank / count_all)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of nonempty lines for function", utils.round(count_lines_nonempty / count_all)}, false)
	end
	if count_global>0 then
	metricsTable = metricsTable .. utils.addTableRow({"Average number of lines for global function", utils.round(count_global_lines / count_global)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of code lines for global function", utils.round(count_global_lines_code / count_global)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of comment lines for global function", utils.round(count_global_lines_comment / count_global)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of blank lines for global function", utils.round(count_global_lines_blank / count_global)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of nonempty lines for global function", utils.round(count_global_lines_nonempty / count_global)}, false)
	end
	if count_local>0 then
	metricsTable = metricsTable .. utils.addTableRow({"Average number of lines for local function", utils.round(count_local_lines / count_local)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of code lines for local function", utils.round(count_local_lines_code / count_local)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of comment lines for local function", utils.round(count_local_lines_comment / count_local)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of blank lines for local function", utils.round(count_local_lines_blank / count_local)}, false)
	metricsTable = metricsTable .. utils.addTableRow({"Average number of nonempty lines for local function", utils.round(count_local_lines_nonempty / count_local)}, false)
	end
	if (file_AST_list) then
		metricsTable = metricsTable .. utils.addTableRow({"Maximum number of functions in module", max_fun_in_module[1] .. " " .. max_fun_in_module[2]}, false)
		metricsTable = metricsTable .. utils.addTableRow({"Minimum number of functions in module", min_fun_in_module[1] .. " " .. min_fun_in_module[2]}, false)         
	end
		
	metricsTable = metricsTable .. utils.closeTable()

	return metricsTable

end

local function createModuleLenGraph(globalMetrics, withLink)
	
	local data = ""

	for _, moduleRef in pairs(globalMetrics.moduleDefinitions) do
		data = data .. "['" .. moduleRef.moduleName .. "', " .. moduleRef.LOC.lines .. "], "
	end

	return utils.createPieGraph("Module lengths", data, withLink)

end

local function createFileLenGraph(globalMetrics, withLink)
	
	local data = ""

	for filename, AST in pairs(globalMetrics.file_AST_list) do
		data = data .. "['" .. filename .. "', " .. AST.metrics.LOC.lines .. "], "
	end

	return utils.createPieGraph("File lengths", data, withLink)

end

local function createCouplingTable(globalMetrics)
	
	local metricsTable = "<h2>Module dependency</h2>" ..
		"<div style='min-width: 800px; background-color: #F0F0F0; text-align: center; font-size: 16px; font-weight: bold; margin-bottom: 15px;'> Module" .. 
			"<div style='width: 600px; float: right;'> Dependeds on module" ..
				"<div style='width: 300px; float: right;'> Function or variable - used n times" ..
		"</div> <div style='clear: right;'></div></div><div style='clear: right;'></div></div>"

	for filename, fileAST in pairs(globalMetrics.file_AST_list) do

		metricsTable = metricsTable .. "<div style='min-width: 800px; border-bottom: 1px #F0F0F0 solid; margin-bottom: 2px;'>"
		
		for exec, moduleDef in pairs(fileAST.metrics.moduleDefinitions) do 
						
			if    moduleDef.moduleName then
					
				metricsTable = metricsTable .. moduleDef.moduleName .. "<div style='width: 600px; float: right; '>"
				
				local modules = {}
						
				for moduleName in pairs(moduleDef.moduleCalls) do modules[moduleName] = true end
				for moduleName in pairs(moduleDef.moduleReferences) do modules[moduleName] = true end
							
				for moduleName in pairs(modules) do
				
					metricsTable = metricsTable .. "<div style='border-bottom: 1px #F0F0F0 solid;'>" ..    moduleName ..
						"<div style='width: 300px; float: right;'>"
				
					for funName, count in pairs(moduleDef.moduleCalls[moduleName] or {}) do

						metricsTable = metricsTable .. "<span style='color: #bcbcbc;'>function</span>" .. funName ..
							"<div style='float: right;'>" .. count .. "</div><br /><div style='clear: right;'></div>"

					end
					
					for varName, fullInfo in pairs(fileAST.metrics.moduleReferences[moduleName] or {}) do 
						
						local countAll = 0
						local divString = ""

						for fullname, count in pairs(fullInfo) do 

							countAll = countAll + count
							divString = divString .. "<div style='width: 245px; float:right;'>" .. fullname ..
								"<div style='float: right;'>".. count .. "</div></div><div style='clear: right;'></div>"

						end

						metricsTable = metricsTable .. "<a class='rollVariable'>[+]</a><span style='color: #bcbcbc;'>" ..
							"Variable</span>" .. varName .. "<div style='float: right;'>" .. countAll .. "</div>" ..
							"<div style='display: none;'><%=divString%></div><div style='clear: right;'></div>"
	
					end
					
					metricsTable = metricsTable .. "</div><div style='clear: right;'></div></div>"
					
				end
						
				metricsTable = metricsTable .. "</div><div style='clear: right;'></div>"
						
			end
		end
						
		metricsTable = metricsTable .. "</div>"

	end

	return metricsTable

end

return {
	createLOCTable = createLOCTable,
	createDocMetricsTable = createDocMetricsTable,
	createHalsteadTable = createHalsteadTable,
	createStatementsTable = createStatementsTable,
	createFunctionsTable = createFunctionsTable,
	createModuleLenGraph = createModuleLenGraph,
	createFileLenGraph = createFileLenGraph,
	createCouplingTable = createCouplingTable
}