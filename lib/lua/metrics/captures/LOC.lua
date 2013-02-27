-------------------------------------------------------------------------------
-- Metrics captures - computing of various LOC metrics
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local pairs, type, table, string, print = pairs, type, table, string, print

local lpeg = require 'lpeg'
local keys = (require 'metrics.rules').rules
local utils = require 'metrics.utils'

module ('metrics.captures.LOC')


local function alterNode(node, block)
	local comment, fullComment = utils.getComment(block)
	local index = string.find(fullComment, '\n')
	if (index) then
		node.metrics.LOC.lines  = node.metrics.LOC.lines - 1
		node.metrics.LOC.lines_code  = node.metrics.LOC.lines_code - 1
		node.metrics.LOC.lines_nonempty  = node.metrics.LOC.lines_nonempty - 1
	end
end


local function addCount(array, name, count)
	if (array) then
		array[name] = array[name] + count
	end
end

local moduleDefinitions = {}

local function doMetrics(node)
	local children = node.data
	local key, value
	local moduleMetrics = nil
	
	local LOC = {
		lines = 0				-- total number of lines
	
		,lines_nonempty = 0		-- number of non-empty lines ( code or comments )
		,lines_blank = 0		-- number of empty lines 
	
		,lines_code = 0			-- number of lines with code ( nonempty without comments ) ( comment can be at the end of line )
		,lines_comment = 0		-- number of comment lines ( inline too )
	}
	
	for key, value in pairs(children) do
	
		if (value.tag == 'IGNORED') then
			
			-- IGNORED means whitespace
			-- count number of lines and other measures
			
			local only_newline = false
			local only_comment = false
			
			local children, key, value = value.data
			for key, value in pairs(children) do
			
				if (value.tag == 'NEWLINE') then 
					addCount(LOC, 'lines', 1)
					addCount(moduleMetrics, 'lines', 1)
					
					if (only_newline) then
						addCount(LOC, 'lines_blank', 1)
						addCount(moduleMetrics, 'lines_blank', 1)
					else
						addCount(LOC, 'lines_nonempty', 1)
						addCount(moduleMetrics, 'lines_nonempty', 1)
						if (not only_comment) then
							addCount(LOC, 'lines_code', 1)
							addCount(moduleMetrics, 'lines_code', 1)
						end	
					end	
					only_newline = true
				end
				
				if (value.tag == 'COMMENT') then
					addCount(LOC, 'lines_comment', 1)
					addCount(moduleMetrics, 'lines_comment', 1)
					if (only_newline) then
						only_comment = true
					end
					only_newline = false
					
					-- count number of lines in multiline comments
					local count = 0
					for w in string.gmatch(value.text, "\n") do
						count = count + 1						
					end
					
					addCount(LOC, 'lines', count)
					addCount(moduleMetrics, 'lines', count)
					addCount(LOC, 'lines_comment', count)
					addCount(moduleMetrics, 'lines_comment', count)
					addCount(LOC, 'lines_nonempty', count) -- BLANK ??
					addCount(moduleMetrics, 'lines_nonempty', count) 
				end
				
			end			
			
		else 
			
			if (value.tag == 'STRING') then
				local count =0
				for w in string.gmatch(value.text, "\n") do
					count = count + 1
				end
				addCount(LOC, 'lines', count)
				addCount(moduleMetrics, 'lines', count)
				addCount(LOC, 'lines_code', count)
				addCount(moduleMetrics, 'lines_code', count)
				addCount(LOC, 'lines_nonempty', count)
				addCount(moduleMetrics, 'lines_nonempty', count) 
			end
			
			-- TRY MODULE DEFINITION

			only_newline = false
			only_comment = false
		
			addCount(LOC, 'lines', value.metrics.LOC.lines)
			addCount(LOC, 'lines_comment', value.metrics.LOC.lines_comment)
			addCount(LOC, 'lines_blank', value.metrics.LOC.lines_blank)
			addCount(LOC, 'lines_nonempty', value.metrics.LOC.lines_nonempty)
			addCount(LOC, 'lines_code', value.metrics.LOC.lines_code)
			
			addCount(moduleMetrics, 'lines', value.metrics.LOC.lines)
			addCount(moduleMetrics, 'lines_comment', value.metrics.LOC.lines_comment)
			addCount(moduleMetrics, 'lines_blank', value.metrics.LOC.lines_blank)
			addCount(moduleMetrics, 'lines_nonempty', value.metrics.LOC.lines_nonempty)
			addCount(moduleMetrics, 'lines_code', value.metrics.LOC.lines_code)
			
			if (value.tag == 'Stat') then
				local stat = value.data[1]
				local block = utils.searchForTagItem('Block', stat.data)
				if (block) then
					alterNode(stat, block)
				end				
				
				if (stat.tag == 'FunctionCall') then
				if (stat.data[1].data[1].text == 'module') then
					local exec = stat.data[1]
					
					moduleDefinitions[exec] = {}
					if (moduleDefinitions[exec].metrics == nil) then moduleDefinitions[exec].metrics = {} end
					
					moduleDefinitions[exec].LOC = {
						lines = 0,
						lines_comment = 0,
						lines_code = 0,
						lines_blank = 0,
						lines_nonempty = 0
					}
					
					moduleMetrics = moduleDefinitions[exec].LOC
				end
				
			end
				
			elseif (value.tag == 'GlobalFunction' or value.tag == 'LocalFunction' or value.tag == 'Function') then
				local funcbody = utils.searchForTagItem('FuncBody', value.data)
				local block = utils.searchForTagItem('Block', funcbody.data)
				if (block) then
					alterNode(value, block)
				end
			end
		end	
	end
	
	if (node.metrics == nil) then node.metrics = {} end
	node.metrics.LOC 				= LOC
end

--------------------------------------------
-- Captures table for lpeg parsing - computes lines of code metrics for each node
-- @class table
-- @name captures
captures = (function()
	local key,value
	local new_table = {}
	for key,value in pairs(keys) do
		new_table[key] = function (data) 
			doMetrics(data)
			return data 
		end
	end
	
	new_table[1] = function (node) 
		doMetrics(node)
		
		if not node.metrics.moduleDefinitions then node.metrics.moduleDefinitions = {} end
		
		for exec, data in pairs(moduleDefinitions) do
			if not node.metrics.moduleDefinitions[exec] then node.metrics.moduleDefinitions[exec] = {} end
			node.metrics.moduleDefinitions[exec].LOC = data.LOC
		end	
		
		moduleDefinitions = {}
		
		return node 
	end
	
	return new_table
end)()
