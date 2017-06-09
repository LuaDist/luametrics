local utils = require 'metrics.templates.utils'

--- Function creates a HTML template containing list of functions or tables separated by name alphabeticaly to tabs in table
-- @param metrics Global metrics with ASTs
-- @param definitions Functions or tables
-- @param withLink If checkbox for anonymous functions or tables will be included
-- @author Martin Nagy
-- @return HTML template containing list of functions or tables sorted according to first letter in name
local function createFunctionTableList(metrics, definitions, withLink)
	
	local sortedTable, letterTable = utils.getSortedTable(metrics[definitions]) --Get letterTable and sortedTable 
	local fragmentCount = #sortedTable --Count of tabs (starting letters)
	local result = utils.addTableCSS("tabs") .. utils.getjQuerryJS() --Add JavaScript script to template
	local list = ""
	local pages = ""
	local funType = "ttype" --Default value represents selecting tables

	if(definitions == "functionDefinitions") then
		funType = "fcntype" --If function list is selected
	end

	for fragmentNumber, key in ipairs(sortedTable) do --For each letter tab in table 

		--list contains header (tabs) in tables
		list = list .. "<li><a href='#fragment-" .. fragmentNumber .. "'><span>" .. key .. "</span></a></li>"
		--pages contains containers for each tab of table
		pages = pages .. "<div id='fragment-" .. fragmentNumber .. "'>"

		for _, fun in pairs(letterTable[key]) do --fill container of tab with functions or table

			if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
				pages = pages .. "<span class='tohide'>" --If type is anonymous or table-field add span to endble hiding
			end

			pages = pages .. fun[funType]

			--Add function name with link to documentation
			pages = pages ..    "<a href='#|type=fileLink|to=" .. fun.path .. "|from=functionlist/index.html|#" .. "#" .. fun.name .. "'> " ..
				fun.name .. "</a>" ..    " - [." .. fun.path .. "]&emsp;" .. utils.replaceSpecials(fun.comment or "") .. "<br />"

			if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
				pages = pages .. "</span>" --Close span for table-field or anonymous  
			end
		end

		pages = pages .. "</div>"

	end

	result = result .. "<div id='tabs'><ul>" .. list --Concat header (tabs) to result

	--If functions are selected add Local and Global categories to header
	if(definitions == "functionDefinitions") then
		result = result .. "<li><a href='#fragment-" .. fragmentCount + 4 .. "'><span>Local</span></a></li>" ..
		"<li><a href='#fragment-" .. fragmentCount + 5 .. "'><span>Global</span></a></li>"
	end
		
	--Add Table-field, Anonymous (can be enabled by checkbox) and All category to header (tabs)
	result = result .. "<li class='tohide'><a href='#fragment-" .. fragmentCount + 1 .. "'><span>Table-field</span>" ..
		"</a></li>" ..
		"<li class='tohide'><a href='#fragment-" .. fragmentCount + 2 .. "'><span>Anonymous</span></a></li>" ..
		"<li><a href='#fragment-" .. fragmentCount + 3 .. "'><span>All</span></a></li>"

	--Add Tree category to header (tabs) only if functions selected
	if(definitions == "functionDefinitions") then
		result = result .. "<li><a href='#fragment-" .. fragmentCount + 6 .. "'><span>Tree</span></a></li>"
	end

	result = result .. "</ul>" .. pages --Close header

	local options = {}

	if(definitions == "functionDefinitions") then --Set which containers to fill if functions or tables are selected
		options = {"table-field", "anonymous", "local", "global"}
	else
		options = {"table-field", "anonymous"}
	end

	for i, fcnType in pairs(options) do --Fill containers set in options table

		if i > 2 then i = i + 1 end --Skip all tab to be last in table

		result = result .. "<div id='fragment-" .. fragmentCount + i .. "'>"

		for _, fInfo in ipairs(metrics[definitions]) do

			if fInfo[funType] == fcnType then --Select functions or tables based on type in oprions

				result = result .. fInfo[funType]
				result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
					"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />" 
			end
		end

		result = result .. "</div>"

	end

	result = result .. "<div id='fragment-" .. fragmentCount + 3 .. "'>" --Add All category container

	for _, fInfo in ipairs(metrics[definitions]) do

		if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then --Set to be able to hide anonymous or table-field
			result = result .. "<span class='tohide'>"
		end

		result = result .. fInfo[funType] --Add all other functions or tables
		result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
			"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />"

		if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
			result = result .. "</span>" --Close anonymous or table-field ability to hide
		end
	end

	result = result .. "</div>"

	if(definitions == "functionDefinitions") then --If functions selected add tree structure

		result = result .. "<div id='fragment-" .. fragmentCount + 6 .. "'><div>"
		result = result .. "<ul id='functiontree' class='menulist' style='list-style-type: none;'>"

		for filename, AST in pairs(metrics.file_AST_list) do --Create structure for each file

			result = result .. "<li><a href='#' class='toggler' onclick='return menu_toggle(this);'>[+]</a>" .. 
				"<a href='#|type=fileLink|to=" .. filename .. "|from=functionlist/index.html|#" .. "'>" .. " ." ..
				filename .. "</a><ul style='list-style-type: none;'>" ..
				utils.drawFunctionTree(AST, filename, fileLink) .. "</ul></li>" --Draw functions under file list item

		end
				
		result = result .. "</ul></div></div>"

	end

	result = result .. "</div>"

	if(withLink or withLink == nil) then --If needed, checkbox to show hide table-field and anonymous functions added
		result = result .. "<form id='myform' style='font-size: 13px;'> <input type='checkbox' class='myCheckbox' />" ..
			"Show table-field functions and anonymous functions. </form>"
	end

	return result

end

--- Function creates a HTML template containing list of documented or not documented functions or tables separated by name alphabeticaly to tabs in table
-- @param metrics Global metrics with ASTs
-- @param definitions Functions or tables
-- @param documented Documented or not
-- @param withLink If checkbox for anonymous functions or tables will be included
-- @author Martin Nagy
-- @return HTML template containing list of documented or not documented functions or tables sorted according to first letter in name
local function createDocumentedFunctionTableList(metrics, definitions, documented, withLink)
	
	local sortedTable, letterTable = utils.getSortedTable(metrics[definitions]) --Get letterTable and sortedTable 
	local fragmentCount = #sortedTable --Count of tabs (starting letters)
	local result = ""
	local list = ""
	local pages = ""
	local funType = "ttype" --Default value represents selecting tables
	local lastFragNum = -1 --Counter not to add one tab more times

	if(documented == 0) then --Set different ID to documented and not documented to not interfere with each other in HTML file
		result = utils.addTableCSS("tabs3") .. utils.getjQuerryJS()
	else
		result = utils.addTableCSS("tabs2") .. utils.getjQuerryJS()
	end

	if(definitions == "functionDefinitions") then
		funType = "fcntype" --If function list is selected
	end

	for fragmentNumber, key in ipairs(sortedTable) do --For each letter tab in table     

		--pages contains containers for each tab of table
		pages = pages .. "<div id='fragment-" .. fragmentNumber .. "'>"

		for _, fun in pairs(letterTable[key]) do --Loop through functions or tables in letter table

			if fun.documented == documented or (documented == 0 and fun.documented == nil) then --select documented or not documented

				if(fragmentNumber ~= lastFragNum) then --If tab wasnt added

					lastFragNum = fragmentNumber
					--list contains header (tabs) in tables
					list = list .. "<li><a href='#fragment-" .. fragmentNumber .. "'><span>" .. key .. "</span></a></li>"

				end

				if(fun[funType] == "table-field" or fun[funType] == "anonymous") then --If is anonymous or table-field add ability to hide
					pages = pages .. "<span class='tohide'>"
				end

				pages = pages .. fun[funType]

				--Add functions to container of the tab in table with link to documentation
				pages = pages .. "<a href='#|type=fileLink|to=" .. fun.path .. "|from=functionlist/index.html|#" ..
					"#" .. fun.name .. "'> " ..
					fun.name .. "</a>" .. " - [." .. fun.path .. "]&emsp;" .. utils.replaceSpecials(fun.comment or "") .. "<br />"

				if(fun[funType] == "table-field" or fun[funType] == "anonymous") then
					pages = pages .. "</span>" --Close ability to hide for table-field or anonymous  
				end     
			end 
		end

		pages = pages .. "</div>"

	end

	--Move counter to 6 or 12 to not interfere tables with each other in HTML documentation (Needed for luadocer)
	if(documented == 0) then fragmentCount = fragmentCount + 12 else fragmentCount = fragmentCount + 6 end

	if(list ~= "") then --If any documented or not documented function exists

		result = result .. "<div id='tabs" --create container for containers including functions or tables

		if(documented == 0) then
			result = result .. "3" --Again not to interfere with each other in HTML documentation (Needed for luadocer)
		else
			result = result .. "2"
		end

		result = result .. "'><ul>" .. list --Add header to result

		if(definitions == "functionDefinitions") then --If functions are selected add Local and Global categories to header
			result = result .. "<li><a href='#fragment-" .. fragmentCount + 4 .. "'><span>Local</span></a></li>" ..
			"<li><a href='#fragment-" .. fragmentCount + 5 .. "'><span>Global</span></a></li>"
		end
		
		--Add Table-field, Anonymous (can be enabled by checkbox) and All category to header (tabs)
		result = result .. "<li class='tohide'><a href='#fragment-" .. fragmentCount + 1 ..
			"'><span>Table-field</span>" .. "</a></li>" ..
			"<li class='tohide'><a href='#fragment-" .. fragmentCount + 2 .. "'><span>Anonymous</span></a></li>" ..
			"<li><a href='#fragment-" .. fragmentCount + 3 .. "'><span>All</span></a></li>"

		result = result .. "</ul>" .. pages --Close header

		local options = {}

		if(definitions == "functionDefinitions") then --Set which containers to fill if functions or tables are selected
			options = {"table-field", "anonymous", "local", "global"}
		else
			options = {"table-field", "anonymous"}
		end

		for i, fcnType in pairs(options) do --Fill containers set in options table

			if i > 2 then i = i + 1 end --Skip all tab to be last in table

			result = result .. "<div id='fragment-" .. fragmentCount + i .. "'>"

			for _, fInfo in ipairs(metrics[definitions]) do --Loop functions or tables

				--Select functions or tables based on type in options and select only documented or not documented
				if fInfo[funType] == fcnType and (fInfo.documented == documented or fInfo.documented == nil) then

					result = result .. fInfo[funType]
					result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
						"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />" 
				end
			end

			result = result .. "</div>"

		end

		result = result .. "<div id='fragment-" .. fragmentCount + 3 .. "'>" --Add All category container

		for _, fInfo in ipairs(metrics[definitions]) do

			--Select only documented or not documented functions
			if fInfo.documented == documented or (documented == 0 and fInfo.documented == nil) then

				if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then --Set to be able to hide anonymous or table-field
					result = result .. "<span class='tohide'>"
				end

				--Add all other functions or tables
				result = result .. fInfo[funType] 
				result = result .. "<a href='#|type=fileLink|to=" .. fInfo.path .. "|from=functionlist/index.html|#" .. "#" .. fInfo.name ..
					"'> " .. fInfo.name .. "</a>" .. " - [." .. fInfo.path .. "]&emsp;" .. (fInfo.comment or "") .. "<br />"

				if fInfo[funType] == "table-field" or fInfo[funType] == "anonymous" then
					result = result .. "</span>" --Close anonymous or table-field ability to hide
				end
			end
		end

		result = result .. "</div></div>"

		if(withLink or withLink == nil) then --If needed, checkbox to show hide table-field and anonymous functions added
			result = result .. "<form id='myform' style='font-size: 13px;'> <input type='checkbox' class='myCheckbox' />" ..
				"Show table-field functions and anonymous functions. </form>"
		end

	else

		--If no documented or not documented functions were found add text to table
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