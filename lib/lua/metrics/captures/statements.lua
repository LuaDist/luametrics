-------------------------------------------------------------------------------
-- Metrics captures - counting number of statements
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local pairs, print, table = pairs, print, table

local keys = (require 'metrics.rules').rules

module ('metrics.captures.statements')

local moduleDefinitions = {}

-- the idea in algorithm is almost the same as in metrics.captures.LOC
-- only count the number of different statements

local function countStatements(node)
	local children = node.data
	local moduleMetrics = nil
	
	local statements = {}
	
	for _, child in pairs(children) do
		
		if (child.tag == 'Stat') then
			local stat = child.data[1]
			if (not statements[stat.tag]) then statements[stat.tag] = {} end
			table.insert(statements[stat.tag], stat)
			
			if (moduleMetrics) then 
				if (not moduleMetrics[stat.tag]) then moduleMetrics[stat.tag] = {} end
				table.insert(moduleMetrics[stat.tag], stat)
			end
			
			if (stat.tag == 'FunctionCall') then
				if (stat.data[1].data[1].text == 'module') then
					local exec = stat.data[1]
					
					moduleDefinitions[exec] = {}
					if (moduleDefinitions[exec].metrics == nil) then moduleDefinitions[exec].metrics = {} end
					
					moduleDefinitions[exec].statements = {}
					
					moduleMetrics = moduleDefinitions[exec].statements
				end
			end
		end	
		
		for key, stats in pairs(child.metrics.statements) do
			if (not statements[key]) then statements[key] = {} end
			for _, stat in pairs(stats) do
				table.insert(statements[key], stat)
				if (moduleMetrics) then 
					if (not moduleMetrics[stat.tag]) then moduleMetrics[stat.tag] = {} end
					table.insert(moduleMetrics[stat.tag], stat)
				end
			end
		end
		
	end
	
	if (node.metrics == nil) then node.metrics = {} end
	node.metrics.statements = statements	
end


--------------------------------------------
-- Captures table for lpeg parsing
-- @class table
-- @name captures
captures = (function()
	local key,value
	local new_table = {}
	for key,value in pairs(keys) do
		new_table[key] = function (data) 
			countStatements(data)
			return data 
		end
	end
	
	new_table[1] = function (node) 
		countStatements(node)
		
		if not node.metrics.moduleDefinitions then node.metrics.moduleDefinitions = {} end
		
		for exec, data in pairs(moduleDefinitions) do
			if not node.metrics.moduleDefinitions[exec] then node.metrics.moduleDefinitions[exec] = {} end
			node.metrics.moduleDefinitions[exec].statements = data.statements
		end	
		
		moduleDefinitions = {}
		
		return node 
	end
	
	return new_table
end)()
