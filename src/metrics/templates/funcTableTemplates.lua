local utils = require 'metrics.templates.utils'
local tablesCSS = require 'metrics.templates.css.smellTable'

local function createFunctionTableList(metrics, definitions, withLink)
	
	local sortedTable, letterTable = utils.getSortedTable(metrics[definitions])
	local fragmentCount = #sortedTable
	local result = utils.addTableCSS("tabs") .. tablesCSS.getjQuerryJS()
	local list = ""
	local pages = ""
	local funType = "ttype"

	if(definitions == "functionDefinitions") then
		funType = "fcntype"
	end

	for fragmentNumber, key in ipairs(sortedTable) do    

		list = list .. "<li><a href='#fragment-" .. fragmentNumber .. "'><span>" .. key .. "</span></a></li>"
		pages = pages .. "<div id='fragment-" .. fragmentNumber .. "'>"

		for _, fun in pairs(letterTable[key]) do

			if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
				pages = pages .. "<span class='tohide'>"
			end

			pages = pages .. fun[funType]

			pages = pages ..    "<a href='#|type=fileLink|to=" .. fun.path .. "|from=functionlist/index.html|#" .. "#" .. fun.name .. "'> " ..
				fun.name .. "</a>" ..    " - [." .. fun.path .. "]&emsp;" .. utils.replaceSpecials(fun.comment or "") .. "<br />"

			if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
				pages = pages .. "</span>"    
			end
		end

		pages = pages .. "</div>"

	end

	result = result .. "<div id='tabs'><ul>" .. list

	if(definitions == "functionDefinitions") then
		result = result .. "<li><a href='#fragment-" .. fragmentCount + 4 .. "'><span>Local</span></a></li>" ..
		"<li><a href='#fragment-" .. fragmentCount + 5 .. "'><span>Global</span></a></li>"
	end
		
	result = result .. "<li class='tohide'><a href='#fragment-" .. fragmentCount + 1 .. "'><span>Table-field</span>" ..
		"</a></li>" ..
		"<li class='tohide'><a href='#fragment-" .. fragmentCount + 2 .. "'><span>Anonymous</span></a></li>" ..
		"<li><a href='#fragment-" .. fragmentCount + 3 .. "'><span>All</span></a></li>"


	if(definitions == "functionDefinitions") then
		result = result .. "<li><a href='#fragment-" .. fragmentCount + 6 .. "'><span>Tree</span></a></li>"
	end

	result = result .. "</ul>" .. pages

	local options = {}

	if(definitions == "functionDefinitions") then
		options = {"table-field", "anonymous", "local", "global"}
	else
		options = {"table-field", "anonymous"}
	end

	for i, fcnType in pairs(options) do

		if i > 2 then i = i + 1 end

		result = result .. "<div id='fragment-" .. fragmentCount + i .. "'>"

		for _, fInfo in ipairs(metrics[definitions]) do

			if fInfo[funType] == fcnType then

				result = result .. fInfo[funType]
				result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
					"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />" 
			end
		end

		result = result .. "</div>"

	end

	result = result .. "<div id='fragment-" .. fragmentCount + 3 .. "'>"

	for _, fInfo in ipairs(metrics[definitions]) do

		if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
			result = result .. "<span class='tohide'>"
		end

		result = result .. fInfo[funType]
		result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
			"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />"

		if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
			result = result .. "</span>"
		end
	end

	result = result .. "</div>"

	if(definitions == "functionDefinitions") then

		result = result .. "<div id='fragment-" .. fragmentCount + 6 .. "'><div>"
		result = result .. "<ul id='functiontree' class='menulist' style='list-style-type: none;'>"

		for filename, AST in pairs(metrics.file_AST_list) do

			result = result .. "<li><a href='#' class='toggler' onclick='return menu_toggle(this);'>[+]</a>" .. 
				"<a href='#|type=fileLink|to=" .. filename .. "|from=functionlist/index.html|#" .. "'>" .. " ." ..
				filename .. "</a><ul style='list-style-type: none;'>" ..
				utils.drawFunctionTree(AST, filename, fileLink) .. "</ul></li>" 

		end
				
		result = result .. "</ul></div></div>"

	end

	result = result .. "</div>"

	if(withLink or withLink == nil) then
		result = result .. "<form id='myform' style='font-size: 13px;'> <input type='checkbox' class='myCheckbox' />" ..
			"Show table-field functions and anonymous functions. </form>"
	end

	return result

end

local function createDocumentedFunctionTableList(metrics, definitions, documented, withLink)
	
	local sortedTable, letterTable = utils.getSortedTable(metrics[definitions])
	local fragmentCount = #sortedTable
	local result = ""
	local list = ""
	local pages = ""
	local funType = "ttype"
	local lastFragNum = -1

	if(documented == 0) then
		result = utils.addTableCSS("tabs3") .. tablesCSS.getjQuerryJS()
	else
		result = utils.addTableCSS("tabs2") .. tablesCSS.getjQuerryJS()
	end

	if(definitions == "functionDefinitions") then
		funType = "fcntype"
	end

	for fragmentNumber, key in ipairs(sortedTable) do    

		pages = pages .. "<div id='fragment-" .. fragmentNumber .. "'>"

		for _, fun in pairs(letterTable[key]) do

			if fun.documented == documented or (documented == 0 and fun.documented == nil) then

				if(fragmentNumber ~= lastFragNum) then

					lastFragNum = fragmentNumber
					list = list .. "<li><a href='#fragment-" .. fragmentNumber .. "'><span>" .. key .. "</span></a></li>"

				end

				if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
					pages = pages .. "<span class='tohide'>"
				end

				pages = pages .. fun[funType]

				pages = pages .. "<a href='#|type=fileLink|to=" .. fun.path .. "|from=functionlist/index.html|#" ..
					"#" .. fun.name .. "'> " ..
					fun.name .. "</a>" .. " - [." .. fun.path .. "]&emsp;" .. utils.replaceSpecials(fun.comment or "") .. "<br />"

				if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
					pages = pages .. "</span>"    
				end     
			end 
		end

		pages = pages .. "</div>"

	end

	if(documented == 0) then fragmentCount = fragmentCount + 12 else fragmentCount = fragmentCount + 6 end

	if(list ~= "") then

		result = result .. "<div id='tabs"

		if(documented == 0) then
			result = result .. "3"
		else
			result = result .. "2"
		end

		result = result .. "'><ul>" .. list

		if(definitions == "functionDefinitions") then
			result = result .. "<li><a href='#fragment-" .. fragmentCount + 4 .. "'><span>Local</span></a></li>" ..
			"<li><a href='#fragment-" .. fragmentCount + 5 .. "'><span>Global</span></a></li>"
		end
		
		result = result .. "<li class='tohide'><a href='#fragment-" .. fragmentCount + 1 ..
			"'><span>Table-field</span>" .. "</a></li>" ..
			"<li class='tohide'><a href='#fragment-" .. fragmentCount + 2 .. "'><span>Anonymous</span></a></li>" ..
			"<li><a href='#fragment-" .. fragmentCount + 3 .. "'><span>All</span></a></li>"

		result = result .. "</ul>" .. pages

		local options = {}

		if(definitions == "functionDefinitions") then
			options = {"table-field", "anonymous", "local", "global"}
		else
			options = {"table-field", "anonymous"}
		end

		for i, fcnType in pairs(options) do

			if i > 2 then i = i + 1 end

			result = result .. "<div id='fragment-" .. fragmentCount + i .. "'>"

			for _, fInfo in ipairs(metrics[definitions]) do

				if fInfo[funType] == fcnType and (fInfo.documented == documented or fInfo.documented == nil) then

					result = result .. fInfo[funType]
					result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
						"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />" 
				end
			end

			result = result .. "</div>"

		end

		result = result .. "<div id='fragment-" .. fragmentCount + 3 .. "'>"

		for _, fInfo in ipairs(metrics[definitions]) do

			if fInfo.documented == documented or fInfo.documented == nil then

				if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
					result = result .. "<span class='tohide'>"
				end

				result = result .. fInfo[funType]
				result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
					"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />"

				if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
					result = result .. "</span>"
				end
			end
		end

		result = result .. "</div></div>"

		if(withLink or withLink == nil) then
			result = result .. "<form id='myform' style='font-size: 13px;'> <input type='checkbox' class='myCheckbox' />" ..
				"Show table-field functions and anonymous functions. </form>"
		end

	else

		result = result .. "<ul>There are no "

		if(documented == 0) then
			result = result .. "non-"
		end

		result = result .. "documented "

		if(definitions == "functionDefinitions") then
			result = result .. "functions</ul>"
		else
			result = result .. "tables</ul>"
		end

	end

	return result

end

return {
	createFunctionTableList = createFunctionTableList,
	createDocumentedFunctionTableList = createDocumentedFunctionTableList
}