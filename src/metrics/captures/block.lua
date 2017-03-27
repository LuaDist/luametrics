-------------------------------------------------------------------------------
-- Metrics captures - analysis of blocks. Output is syntax highlight, declarations of variables, function definitions and function calls
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local pairs, type, table, string, print = pairs, type, table, string, print

local utils = require 'metrics.utils'

module ('metrics.captures.block')

local total_moduleCalls = {}			-- > { module_name {function_name, exec_count} }
local total_moduleReferences = {}

local total_function_def = nil			-- > { _, node of function}
local total_execs_stack = nil			-- > { name_of_function, {nodes} }
local total_locals_stack = nil

local all_locals_stack = nil			-- > { _ , { name_of_variable, { nodes }  }   } -- holds all references
local locals_stack = nil				-- > { name_of_variable, {nodes} } -- holds only the current reference (the last defined)
local remotes_stack = nil				-- > { name_of_variable, {nodes} }

local highlight_local = nil				-- > { name_of variable, {nodes = {nodes}, next_nodes =  {__recursion__} } }
local highlight_remote = nil

local node_callbacks = {}

local moduleDefinitions = {}
local moduleMetrics = nil

local id_generator = (function()
	local id = 0;
	return function()
		id = id + 1
		return id
	end
end)()

-- called when an variable is beaing evaluated as 'end of scope' and is associated with module referemce
local function evaluate_require_execs(node, secondary_nodes, nodeName, scopeArray, data) 		--- node assign operacie (Name) a data {args} (prefixExp celeho volania)

	local name			-- FULL name of variable assigned to ! ... leftname when searching for functions and variables
	local modulename	-- FULL name of required module

	if (node.tag == 'STRING' ) then -- if node is a STRING node - require function was not part of an assign, defines a new variable
		name = string.sub(node.text, 2 , string.len(node.text) -1) -- delete '' and "" 
		modulename = name
	else
		name = node.text
		if (secondary_nodes) then 
			for k,v in pairs (secondary_nodes) do
				name = name .. v.text
			end
		end
		modulename = utils.searchForTagItem_recursive('STRING', data[1], 5)
		modulename = string.sub(modulename.text, 2 , string.len(modulename.text) -1)
	end
	
	if (not modulename) then return end -- require does not contain string with its name but only a variable (subject to future dynamic analysis)
	
	local index

	-- evaluate function calls of a referenced module
	local functions = {}
	if (total_moduleCalls[modulename] == nil) then total_moduleCalls[modulename] = {} end
	local moduleref = total_moduleCalls[modulename]
		
	for callName, node in pairs(total_execs_stack) do
		index = string.find(callName, name)
		if (index == 1) then
			local rightname = string.sub(callName, index + string.len(name) + 1)
			functions[rightname] = node
			for _, node in pairs(node) do
				node.metrics.module_functionCall = {}
				node.metrics.module_functionCall.moduleName = modulename
				node.metrics.module_functionCall.functionName = rightname
			end			
		end
	end
	
	for key, value in pairs(functions) do
		if (moduleref[key] == nil) then moduleref[key] = 0 end
		moduleref[key] = moduleref[key] + table.getn(value)
	end
	
	-- evaluate variables of a references module .. the same scope as the beginning of a variable (jedna.dva = require 'aa') - scope of 'jedna'
	local variables = {}
	
	for _ ,var in pairs(scopeArray[nodeName]) do
		-- build name for variable (join parts into one string ( one.two.three ) (var is only a reference to node Name 'one')
		local varName = var.text
		if (var.parent.tag == '_PrefixExp') then
			nameNode, secondaryNodes = process_PrefixExpChildren(var.parent.data)
			for k,v in pairs(secondaryNodes) do 				
				varName = varName .. v.text
			end
			
			-- split name into left.mid.right parts (left+mid = localmodulename)
			local leftname = var.text
			i = 1
			while (leftname ~= name and i<#secondaryNodes + 1) do 
				leftname = leftname .. secondaryNodes[i].text
				i = i + 1
			end
			local midname
			if (i < #secondaryNodes + 1) then 
				midname = secondaryNodes[i].text
			end
			i = i + 1
			local rightname = ''
			while (i<#secondaryNodes + 1) do 
				rightname = rightname .. secondaryNodes[i].text
				i = i + 1
			end
			
			if (midname) then
				-- compare with local variable holding the module
				midname = string.sub(midname, 2) -- get rid of the dot in .variable
				if (variables[midname] == nil) then variables[midname] = {} end
				if (variables[midname][midname..rightname] == nil) then 
					variables[midname][midname..rightname] = 1 
				else
					variables[midname][midname..rightname] = variables[midname][midname..rightname] + 1
				end
				var.metrics.module_reference = {}
				var.metrics.module_reference.moduleName = modulename
				var.metrics.module_reference.referenceName = midname
				var.metrics.module_reference.referenceName_full = midname .. rightname
			end
			
		end	
	end
	
	total_moduleReferences[modulename] = variables
	
end

-- simple helper to add a node into array[name]
local function addItemToArray(array, name, node)

	if (array[name] == nil) then array[name] = {} end
	table.insert(array[name], node)
	
end

-- merging of highlight tables
local function merge_tables(new_table, stack1, stack2)
	
	-- get keys from both tables
	
	local keys = {}
	
	if (stack1 ~=  nil) then
		for key, _ in pairs(stack1) do
			keys[key] = true
		end
	end
	
	if (stack2 ~= nil) then
		for key, _ in pairs(stack2) do
			keys[key] = true
		end
	end
	
	-- go over keys and merge values
	
	for key, _ in pairs(keys) do
		if (new_table[key] == nil) then new_table[key] = {} end
		if (new_table[key].nodes == nil) then new_table[key].nodes = {} end
		if (new_table[key].parents == nil) then new_table[key].parents = {} end
		
		local s1_next_nodes, s2_next_nodes
	
		if (stack1 ~= nil and stack1[key] ~= nil) then
			for k,v in pairs(stack1[key].nodes) do
				table.insert(new_table[key].nodes, v)
			end
			for k,v in pairs(stack1[key].parents) do
				table.insert(new_table[key].parents, v)
			end
			s1_next_nodes = stack1[key].next_nodes
		end
		
		if (stack2 ~= nil and stack2[key] ~= nil) then
			for k,v in pairs(stack2[key].nodes) do
				table.insert(new_table[key].nodes, v)
			end
			for k,v in pairs(stack2[key].parents) do
				table.insert(new_table[key].parents, v)
			end
			s2_next_nodes = stack2[key].next_nodes
		end
	
		-- create table for next_nodes - array of nodes in +1 depth
	
		new_table[key].next_nodes = {}
	
		-- recursion
			
		merge_tables(new_table[key].next_nodes, s1_next_nodes, s2_next_nodes )
	
	end

end

-- simple helper function to add an idem with basic 'name' and secondary nodex 'next_nodes' into hightlight array
local function addItemToHighlightArray(stack, name, next_nodes)

	local node_name = name.text

	-- require 'modulename' - is inserted with full modulename STRING ... we want to match this to the appropriate nodes with name by its first. name
	local index = string.find(node_name, '%.')
	if (index) then node_name = string.sub(node_name, 2, index - 1)	end
	---

	if (stack[node_name] == nil) then stack[node_name] = {} end
	if (stack[node_name].nodes == nil) then stack[node_name].nodes = {} end
	table.insert(stack[node_name].nodes, name)
	stack[node_name].parents = {}
	
	local parents = {name}
	
	if (next_nodes) then	
		if (stack[node_name].next_nodes == nil) then stack[node_name].next_nodes = {} end
		local current = stack[node_name].next_nodes
				
		for k, node in pairs(next_nodes) do
			if (current[node.text] == nil) then	current[node.text] = {}	end
			if (current[node.text].nodes == nil) then current[node.text].nodes = {} end
			if (current[node.text].parents == nil) then current[node.text].parents = {} end
	
			for _,parentNode in pairs(parents) do table.insert(current[node.text].parents, parentNode) end
			table.insert(current[node.text].nodes, node)
			table.insert(parents, node)
	
			if (current[node.text].next_nodes == nil) then current[node.text].next_nodes = {} end
			current = current[node.text].next_nodes
		end
	end

end

-- checks whether given expression is a function declaration (expression is right side of an assign operation)
local function checkAndAddFunctionDeclaration(name, expression)
	if (expression == nil) then 
		return nil
	else
		local fun = utils.searchForTagItem_recursive('Function', expression, 3)	
		if (fun) then
			fun.name = name.text
			table.insert(total_function_def , fun )
			
			return fun
		else
			return nil
		end
	end
	return nil	
end

-- function is called each time a variable is used (referenced)
-- node - node of tree that contains the variable
-- text - name of the variable
-- idRead - boolean value - true if the operation is reading from the variable
local function newVariable(node, text, secondary_nodes, isRead)
		
	if (locals_stack[text]==nil) then							-- if variable was not defined before - it belongs to the 'remotes' variables
		addItemToArray(remotes_stack, text, node)
		addItemToHighlightArray(highlight_remote, node, secondary_nodes)
	
		if (isRead) then -- variable is read from
			node.isRead = true
		else -- write											
			node.isWritten = true
		end
	else
		table.insert(locals_stack[text], node)					-- the variable is local - table was defined before
																-- insert it into the table (table holds froup of nodes corresponding to the variable with the same text)
		addItemToHighlightArray(highlight_local, node, secondary_nodes)	
	end
	
	if (moduleMetrics) then
		table.insert(moduleMetrics.variables, node)
	end
	
end

-- return table of names from the assign operation
-- format of returned table = { name_of_variable, { list of nodes for the name}   }
local function processAssign(node, isLocal)

	local results = {}
	
	local nameList = utils.getNamesFromNameList(node.nameList)
	
	local expList = {}
	if (node.expList) then expList = utils.getExpsFromExpsList(node.expList) end
	
	for k,v in pairs(nameList) do
		
		local functionNode = checkAndAddFunctionDeclaration(v,expList[k])
		local secondary_nodes
		
		if (v.tag == 'Var') then -- if normal assign (not local) find the 'Var' node instead of a Name node
			v, secondary_nodes = process_PrefixExpChildren(v.data[1].data)		-- v.data[1].data is table of _PrefixExp's children
		end
		
		v.functionNode = functionNode
		if functionNode then functionNode.assignNode = v end
		
		-- check right side of assign for function call
		-- test for 'require' function call
		local getPrefixExp = utils.searchForTagItem_recursive('_PrefixExp', expList[k], 3)
		if (getPrefixExp) then
			local name, results, isFunctionCall, args = process_PrefixExpChildren(getPrefixExp.data)
			if (isFunctionCall) then
				if (name.text == 'require') then 
	
					local modulename = utils.searchForTagItem_recursive('STRING', args, 5)
					if (modulename) then
						local nodeName = string.sub(modulename.text, 2, string.len(modulename.text) -1) -- delete '' and "" from beginning and end
												
						local index = string.find(nodeName, '%.')
						if (index) then nodeName = string.sub(nodeName, 0, index - 1) end
						
						newVariable(modulename, nodeName, nil, true) -- set callbacks for node ... evaluate_require_execs is called with node as argument when 'end of scope' happens
						node_callbacks[v] = {}
						node_callbacks[v].sec_nodes = secondary_nodes
						node_callbacks[v].fun = evaluate_require_execs
						node_callbacks[v].call_data = {args}
					end
					
				end
			end
		end
		
		-- create table to be returned
		local str = v.text
		table.insert(results, {str, v, secondary_nodes})
		
	end	
	return results
end

local function processFunction(node)
	-- get Block and ParList nodes for function
	local block = utils.searchForTagItem_recursive('Block', node, 2) 
	local parlist = utils.searchForTagItem_recursive('ParList', node, 2) 
	node.metrics.blockdata = block.metrics.blockdata
	
	-- treat function as an Assign operation - the name of a function is left side of assign operation
	if (node.name) then -- funkcie function()... check needed because function() without names are processed together in with Assign operations (later)
		local nameBlock, secondaryNames = utils.searchForTagItem('Name', node.data)
		
		if (nameBlock == nil) then
			local funcname = utils.searchForTagItem('FuncName', node.data)
			nameBlock, secondaryNames = process_PrefixExpChildren(funcname.data)
		end
		
		nameBlock.functionNode = node
		
		-- correct setting of isLocal or isGlobal value for function
		
		if (node.tag == 'LocalFunction') then
			if (locals_stack[nameBlock.text] ~= nil) then
				table.insert(all_locals_stack, {nameBlock.text,locals_stack[nameBlock.text]})
				endScopeOfVariable(locals_stack, nameBlock.text)
				highLightVariable(highlight_local, nameBlock.text)
			end
			addItemToArray(locals_stack, nameBlock.text, nameBlock)
			addItemToHighlightArray(highlight_local, nameBlock, secondaryNames)
			if (moduleMetrics) then
				table.insert(moduleMetrics.variables, nameBlock)
			end
		else
			newVariable(nameBlock, nameBlock.text, secondaryNames, false)
		end
		nameNode = nameBlock		
	end
	
	
	-- body of a function - set function arguments as local variables , and do 'end of scope' (highlight them)
	if (block ~= nil and parlist ~= nil) then
		-- get table of variables from nameList
						
		local k,v, names
		local nameList = utils.searchForTagItem('NameList', parlist.data)
		if (nameList) then
			names = utils.getNamesFromNameList(nameList)
		end
							
		-- get table containing remote variables for function (from its block)
		local remotes = block.metrics.blockdata.remotes		
		local highlight_remotes_block = block.metrics.blockdata.highlight_remote
		if (names ~= nil ) then
			-- if remote variable is an argument of a function - call endScopeOfVariable functino that takes care of them (delete them from arrays and highlights them)
			-- this variable is a temporary holder
			local holder = {}
			
			for k,v in pairs(names) do
				addItemToArray(remotes, v.text, v)
				addItemToHighlightArray(highlight_remotes_block, v, nil)
				
				-- number and throw aray
				
				holder[v.text] = remotes[v.text]
				
				endScopeOfVariable(remotes, v.text)
				highLightVariable(highlight_remotes_block, v.text)
			end
			
			doRecursion(block.parent)
			
			-- remotes set earlier are actualy local variables for the block !
			-- dane remotes su v skutocnosti lokalne premenne pre dany block !
			
			-- only for that one block !
			
			for k,v in pairs(holder) do
				table.insert(block.metrics.blockdata.locals, { k, v })
				table.insert(block.metrics.blockdata.locals_total, {k,v} )
				if (moduleMetrics) then
					for _, node in pairs(v) do
						table.insert(moduleMetrics.variables, v)
					end
				end
			end
			
		else
			doRecursion(block.parent)
		end
	else		
		doRecursion(block.parent)
	end
end

function process_PrefixExpChildren(children)
	
	local results = {}
	local name = nil
	local isFunctionCall = nil
	local args = nil
	
	for k, child in pairs(children) do

		if (child.tag == 'Name') then
			name = child
		elseif (child.tag == '_PrefixExpDot') then
			table.insert(results, child)
		elseif (child.tag == 'IGNORED') then
		elseif (child.tag == '_PrefixExpSquare') then
			table.insert(results, child)
		elseif (child.tag == '_PrefixExpColon') then
			table.insert(results, child.data[3])
			break
		elseif (child.tag == '_PrefixExpArgs') then
			args = child
			isFunctionCall = true
			break
		else
			break
		end
	end
	return name, results, isFunctionCall, args
end

local function process_PrefixExp(node)
	local names = {}
	
	local name, secondary_names = process_PrefixExpChildren(node.data)
	
	local args = utils.searchForTagItem('_PrefixExpArgs', node.data)
	if (args) then 																-- IS A FUNCTION CALL
		if (name) then
			local text = name.text
			
			-- check if this call is 'module' call - remember the name of this module
			if (text == 'module') then 
				-- is package.seeall ?
				
				local explist = utils.searchForTagItem('ExpList', args.data[1].data)
				if (explist) then
					local exps = utils.searchForTagArray('Exp', explist.data)
					local packageSeall = exps[#exps]
				
					if (not (packageSeall and packageSeall.text == 'package.seeall')) then  					
				
						-- end of scope for all global variables, and highlight them -- TODO whatif package.seeall ?
						for k,v in pairs(remotes_stack) do
							endScopeOfVariable(remotes_stack, k, true)	
						end					
						for k, v in pairs(highlight_remote) do
							highLightVariable(highlight_remote, k)
						end
					
					end
				end
			
				-- begin collection of module variables
				
				local modulename = utils.searchForTagItem_recursive('STRING', node, 6)
			
				if (modulename) then 
					modulename = string.sub(modulename.text, 2, string.len(modulename.text) -1 )
									
					moduleDefinitions[node] = {}
					moduleDefinitions[node].moduleName = modulename
					moduleDefinitions[node].references = {
						variables = {},
						execs = {}
					}
					moduleMetrics = moduleDefinitions[node].references					
				end
				
			
			elseif (text == 'require') then -- this is a require call
				-- make sure it is not a part of an assign
				local helper = node.parent.parent.parent.parent
				if (helper.tag ~= 'LocalAssign' and helper.tag ~= 'Assign') then 
					local modulename = utils.searchForTagItem_recursive('STRING', args, 5)
					if (modulename) then
						-- require function defines local variable with arguments name
						local nodeName = string.sub(modulename.text, 2, string.len(modulename.text) -1) -- delete '' and "" from beginning and end
												
						local index = string.find(nodeName, '%.')
						if (index) then nodeName = string.sub(nodeName, 0, index - 1) end
						
						newVariable(modulename, nodeName, nil, true)
						if (name.text == 'require') then -- set callback arguments for node ... called when 'end of scope' is run - function evaluate_require_execs is called with the node and arguments
							node_callbacks[modulename] = {}
							node_callbacks[modulename].sec_nodes = nil
							node_callbacks[modulename].fun = evaluate_require_execs
							node_callbacks[modulename].call_data = {nil}
						end
					end
					
				end
				
			end
			
			-- build function name from secondary nodes
			for k,v in pairs(secondary_names) do text = text .. v.text end
		
			addItemToArray(total_execs_stack, text, node)
			if (moduleMetrics) then
				addItemToArray(moduleMetrics.execs, text, node)
			end
			
			if (highlight_local[name.text] == nil) then
				addItemToHighlightArray(highlight_remote, name, secondary_names)
			else
				addItemToHighlightArray(highlight_local, name, secondary_names)
			end
		end
	else	
																		-- PREMENNA
		if (name ~= nil) then
			table.insert(names, {name.text, name, secondary_names})
		end
	end
	
	return names
end

-- function numbers a group of variables with the same ID and removes the variable from stack table
function endScopeOfVariable(stack, text, setGlobal)
	for k,v in pairs(stack[text]) do
		if (v.functionNode) then
			v.functionNode.isGlobal = setGlobal or false
		end
		if (node_callbacks[v] ~= nil) then node_callbacks[v].fun(v, node_callbacks[v].secondary_nodes, text, stack, node_callbacks[v].call_data) end
	end
	stack[text] = nil
end

-- gives each variable node a varid number - all nodes referencing the same variable have the same varid number
function highLightVariable(stack, text)
	if (stack == nil) then return {} end
			
	if (text) then 
		highLightVariable(stack[text].next_nodes, nil)
		
		local id = id_generator()
		for k,v in pairs(stack[text].nodes) do
			if (v.tag == '_PrefixExpSquare') then v = v.data[1] end
			v.varid = id
		end
		for k,v in pairs(stack[text].parents) do
			if (v.secid == nil) then v.secid = {} end
			table.insert(v.secid, id)
		end
		stack[text] = nil
	else
		for k,v in pairs(stack) do
			highLightVariable(v.next_nodes, nil)
			
			local id = id_generator()
			for k,v in pairs(v.nodes) do
				if (v.tag == '_PrefixExpSquare') then v = v.data[1] end -- if in square brackets then highlight only left bracket [ ...  inside can be a variable
				v.varid = id
			end
			
			for k,v in pairs(v.parents) do
				if (v.secid == nil) then v.secid = {} end
				table.insert(v.secid, id)
			end
			stack[k] = nil
		end
	end	
end

-- handling of nodes
local actions = {
	
	Block = function(node)
		-- do not go into a new block - only copy and evaluate its already generated values
		
		-- go over defined remote(=not local) variables defined in this block
		for i,j in pairs(node.metrics.blockdata.remotes) do
		
			-- check whether variable was not defined before
			-- if defined - the variable is local
			-- otherwise the variable is remote
			-- put the variable into the correct local table
			if (locals_stack[i] ~= nil) then
				local k,v
				for k,v in pairs(j) do
					table.insert(locals_stack[i], v)
				end
			else
				if (remotes_stack[i] == nil ) then remotes_stack[i] = {} end
				local k,v
				for k,v in pairs(j) do
					table.insert(remotes_stack[i], v)
				end
			end
			
			if (moduleMetrics) then
				for _, node in pairs(j) do
					table.insert(moduleMetrics.variables, node)
				end
			end
			
		end
		
		-- copy data
		for i,j in pairs(node.metrics.blockdata.highlight_remote) do
			if (locals_stack[i] ~= nil) then 	-- local
				local new_table = {}
				local to_merge = {}
				to_merge[i] = j
				merge_tables(new_table, highlight_local, to_merge)
				highlight_local = new_table
			else 								-- remote
				local new_table = {}
				local to_merge = {}
				to_merge[i] = j
				merge_tables(new_table, highlight_remote, to_merge)
				highlight_remote = new_table
			end
		end
		
		-- copy data
		for i,j in pairs(node.metrics.blockdata.fundefs) do
			table.insert(total_function_def , j)
		end
		
		-- copy data
		for i,j in pairs(node.metrics.blockdata.locals_total) do
			table.insert(total_locals_stack, j)
			if (moduleMetrics) then
				for _, node in pairs(j[2]) do
					table.insert(moduleMetrics.variables, node)
				end
			end
		end
		
		-- copy data
		for i,j in pairs(node.metrics.blockdata.execs) do
			for _, callF in pairs(j) do
				addItemToArray(total_execs_stack, i, callF)
				if (moduleMetrics) then
					addItemToArray(moduleMetrics.execs, i, callF)
				end
			end
		end
		
	end,
	LocalAssign = function(node)
		doRecursion(node) -- evaluate the right side of assign first
		local names = processAssign(node, true) -- get names of variables defined
		
		-- evaluate the list of assigned variables from right side - in reverse order
		-- (local a, a = 6, 7) - first the right 'a' gets defined as 7, and then the left 'a' is defined as 6
		for i = #names, 1, -1 do
			---
			local text, node = names[i][1], names[i][2]
			
			if (locals_stack[text] ~= nil) then
				-- variable was defined as local before
				-- insert the previous declaration into all_locals_stack and assign ID numbers to it
				-- endScopeOfVariable deletes the record from locals_stack table
				table.insert(all_locals_stack, {text,locals_stack[text]})
				endScopeOfVariable(locals_stack, text)
				highLightVariable(highlight_local, text)
			end
			-- insert the newly defined variable into locals_stack
			addItemToArray(locals_stack, text, node)
			addItemToHighlightArray(highlight_local, node, nil)
			if (moduleMetrics) then
				table.insert(moduleMetrics.variables, node)
			end
			----
		end
		
	end,
	Assign = function(node)
		 -- evaluate the right side of assign operation
		doRecursion(node.expList)
		
		-- evaluate the left side of assign operation
		local names = processAssign(node, false) 
		for i = #names, 1, -1 do
			newVariable(names[i][2], names[i][1], names[i][3], false)
			doRecursion(names[i][2].parent) -- all others can be normaly evaluated ... names[i][2].parent is _PrefixExp - recursion evaluates nested immediately (without evaluating the 'recursed' node) 
											-- dalsie uz mozeme normalne prechadzat do dalsich urovni, names[i][2].parent je _PrefixExp - rekurzia okamzite ide do hlbky teda dany node uz neskuma (alebo Name co nas netrapi)
		end			
	end,
	GlobalFunction = function(node)
		table.insert(total_function_def, node)
		processFunction(node)
		-- doRecursion is called inside the processFunction to make sure of proper handling of function's arguments
	end,
	LocalFunction = function(node)
		table.insert(total_function_def, node)
		processFunction(node)
		-- doRecursion is called inside the processFunction to make sure of proper handling of function's arguments
	end,
	Function = function(node)
		processFunction(node)
		-- doRecursion is called inside the processFunction to make sure of proper handling of function's arguments
	end,
	_PrefixExp = function(node)
		local names = process_PrefixExp(node)
		for i,j in pairs(names) do
			newVariable(j[2], j[1], j[3], true)
		end
		doRecursion(node)
	end,
	NumericFor = function(node)
		local nameNode = utils.searchForTagItem('Name', node.data)
		local block = utils.searchForTagItem_recursive('Block', node)
		local holder = {}
		
		if (nameNode and block) then
			local remotes = block.metrics.blockdata.remotes	
			local highlight_remotes_secondary = block.metrics.blockdata.highlight_remote				
			addItemToArray(remotes, nameNode.text, nameNode)
			addItemToHighlightArray(highlight_remotes_secondary, nameNode, nil)
			-- number and throw array .. same as with function arguments
			
			holder[nameNode.text] = remotes[nameNode.text]
			
			endScopeOfVariable(remotes, nameNode.text)
			highLightVariable(highlight_remotes_secondary, nameNode.text)
			
		end			
		
		for i,j in pairs(holder) do
			table.insert(block.metrics.blockdata.locals, { i, j })
			table.insert(block.metrics.blockdata.locals_total, {i, j} )
			if (moduleMetrics) then
				for _, node in pairs(j) do
					table.insert(moduleMetrics.variables, node)
				end
			end
		end
		
		doRecursion(node)
	end,
	GenericFor = function(node)
		local nameList = utils.searchForTagItem('NameList', node.data)
		local block = utils.searchForTagItem_recursive('Block', node)
		
		if (nameList and block) then
			local names = utils.getNamesFromNameList(nameList)
			local remotes = block.metrics.blockdata.remotes
			local highlight_remotes_secondary = block.metrics.blockdata.highlight_remote			
			local holder = {}
			
			for k,v in pairs(names) do
				addItemToArray(remotes, v.text, v)				
				addItemToHighlightArray(highlight_remotes_secondary, v, nil)
				-- number and throw array ... same as with function arguments
				
				holder[v.text] = remotes[v.text]
				
				endScopeOfVariable(remotes, v.text)
				highLightVariable(highlight_remotes_secondary, v.text)
			end			
			
			-- obnovit remotes kedze pre funkciu stale su remote -- TODO - a v skutocnosti su to local
			-- len pre dany block (tento - nie block funkcie) uz niesu podstatne - a teda boli zmazane funkciou endScopeOfVariable
			
			for i,j in pairs(holder) do
				table.insert(block.metrics.blockdata.locals, { i, j })
				table.insert(block.metrics.blockdata.locals_total, {i,j} )
				if (moduleMetrics) then
					for _, node in pairs(j) do
					
						table.insert(moduleMetrics.variables, node)
					end
				end
			end
		end
		doRecursion(node)
	end,
	ELSE = function(node)
		doRecursion(node)
	end,
}

function doRecursion(node)

	-- go recursively over each node in tree
	-- for each node call its function defined in actions table
	-- if function is not defined - call function ELSE defined in actions table

	local k,v
	for k,v in pairs(node.data) do
		local tag = v.tag		
		if (type(actions[tag])=='function') then
			actions[tag](v)
		else
			actions.ELSE(v)
		end
	end
	return
end


local function getModuleDependency(references)
	
	local moduleCalls = {}

	for name, execs in pairs(references.execs) do
		local name = nil
		local fname = nil
		for _, exec in pairs(execs) do
			if (exec.metrics.module_functionCall) then 
				name = exec.metrics.module_functionCall.moduleName
				fname = exec.metrics.module_functionCall.functionName
				break
			end
		end
		if (name) then 
			if not moduleCalls[name] then moduleCalls[name] = {} end
			moduleCalls[name][fname] = #execs
		end
	end
	
	local moduleReferences = {}
	
	for _, node in pairs(references.variables) do
		if (node.metrics and node.metrics.module_reference) then
			local name = node.metrics.module_reference.moduleName
			local refname = node.metrics.module_reference.referenceName
			local refname_full = node.metrics.module_reference.referenceName_full
			
			if not moduleReferences[name] then moduleReferences[name] = {} end
			if not moduleReferences[name][refname] then moduleReferences[name][refname] = {} end
			
			if not moduleReferences[name][refname][refname_full] then 
				moduleReferences[name][refname][refname_full] = 1 
			else
				moduleReferences[name][refname][refname_full] = moduleReferences[name][refname][refname_full] + 1
			end
		end
	end
	
	return moduleCalls, moduleReferences

end

--------------------------------------------
-- Captures table for lpeg parsing - analyzes blocks for variables, function definitions and calls
-- @class table
-- @name captures
captures = {
	
	[1] = function(data)
	
		local chunk = data.data[1]
		local block = nil
		
		block = utils.searchForTagItem_recursive('Block', data, 2)
		
		-- EOF - call endScopeOfVariable to all remaining variables - causes its proper numbering and handling
		
		local backup_stack = {}
		local remote_stack = block.metrics.blockdata.remotes
		for k,v in pairs(remotes_stack) do
			backup_stack[k] = backup_stack[k] or {}			
			table.insert(backup_stack[k], v)
			endScopeOfVariable(remotes_stack, k, true)	
		end	
		block.metrics.blockdata.remotes = backup_stack
		
		local highlight_remote = block.metrics.blockdata.highlight_remote
		for k, v in pairs(highlight_remote) do
			highLightVariable(highlight_remote, k)
		end

		-- save all
		data.metrics.functionExecutions = block.metrics.blockdata.execs
		data.metrics.functionDefinitions = block.metrics.blockdata.fundefs
		data.metrics.moduleCalls = total_moduleCalls
		data.metrics.moduleReferences = total_moduleReferences
		
		data.metrics.blockdata = block.metrics.blockdata
		
		-- save defined module names
		
		if not data.metrics.moduleDefinitions then data.metrics.moduleDefinitions = {} end
		
		for exec, moduleDef in pairs(moduleDefinitions) do
			if not data.metrics.moduleDefinitions[exec] then data.metrics.moduleDefinitions[exec] = {} end
			
			data.metrics.moduleDefinitions[exec].moduleName = moduleDef.moduleName
			
			local moduleCalls, moduleReferences = getModuleDependency(moduleDef.references)
			
			data.metrics.moduleDefinitions[exec].moduleCalls = moduleCalls
			data.metrics.moduleDefinitions[exec].moduleReferences = moduleReferences
			
			data.metrics.currentModuleName = moduleDef.moduleName
		end
		
		-- reset data for next run
		
		node_callbacks = {}
		total_moduleCalls = {}
		total_moduleReferences = {}
		moduleDefinitions = {}
		
		return data
	end,	
	Block = function(data)	
		-- reset data when starting to evaluate a new block
		
		total_locals_stack = {}
		all_locals_stack = {}
		locals_stack = {}
		remotes_stack = {}	
		
		highlight_local = {}
		highlight_remote = {}
		
		total_execs_stack = {}
		total_function_def = {}
		
		-- start
		
		doRecursion(data)
		
		-- prepare tables to store information in
		
		if (data.metrics == nil) then data.metrics ={} end
		
		data.metrics.blockdata = {}		
		data.metrics.blockdata.locals = {}
		data.metrics.blockdata.locals_total = {}
		data.metrics.blockdata.remotes = {}
		
		data.metrics.blockdata.highlight_remote = {}
		
		data.metrics.blockdata.execs = {}
		data.metrics.blockdata.fundefs = {}
		
		-- copy/store data
		
		for k,v in pairs(total_execs_stack) do
			data.metrics.blockdata.execs[k] = v
		end
		
		for k,v in pairs(total_function_def) do
			table.insert(data.metrics.blockdata.fundefs, v)
		end
		
		-- format ==> { name , {nodes} }
		for k,v in pairs(remotes_stack) do
			data.metrics.blockdata.remotes[k] = v
		end
		
		-- store not numbered references to variable (because it's scope did not start here')		
		for k,v in pairs(highlight_remote) do
			data.metrics.blockdata.highlight_remote[k] = v
		end
		
		-- copy last values into total locals stack .... then number and delete them
		-- metrics.blockdata.LOCALS = ALL LOCALS STACK
		-- highlight remaining local variables
		
		-- prekopirovanie poslednych hodnot do total locals stack a ich nasledne ocislovanie a zmazanie z locals stack
		-- metrics.blockdata.LOCALS = ALL LOCALS STACK
		-- priradenie ID este nepriradenym lokalnym premennym
		for k,v in pairs(locals_stack) do
			table.insert(all_locals_stack, {k,v})
			endScopeOfVariable(locals_stack, k)
			highLightVariable(highlight_local, k)
		end		
		
		-- format ==> { _ , {name , {nodes} }
		for k,v in pairs(all_locals_stack) do
			table.insert(total_locals_stack, v)
			table.insert(data.metrics.blockdata.locals, v)
		end
			
		for k,v in pairs(total_locals_stack) do
			table.insert(data.metrics.blockdata.locals_total, v)
		end
					
		return data
	end,
}
