-------------------------------------------------------------------------------
-- Metrics captures - counting number of statements
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local pairs, print, table = pairs, print, table

local keys = (require 'metrics.rules').rules
local utils = require 'metrics.utils'

module ('metrics.captures.statements')

local moduleDefinitions = {}

-- the idea in algorithm is almost the same as in metrics.captures.LOC
-- only count the number of different statements

---
--% Function counts the return statements in function
--autor: Peter Kosa
local function countReturnStatements(node,statements)
	if(node == nil)then return 0 end
	
	local count = 0
	local k,v

	for k,v in pairs(node)do
		if( v.tag ~='GlobalFunction' and v.tag ~= 'LocalFunction' and v.tag ~= 'Function')then	
			if(v.tag == 'keyword' and v.text == 'return')then 
				count = count + 1
				table.insert(statements["return"],v)
			end
 			countReturnStatements(v.data,statements)
		end

	end
	return 
end


local function countStatements(node)
	local children = node.data
	local moduleMetrics = nil
	
	local statements = {}
	

-- doplnil : Peter Kosa  
--counts number of return points in function
		if(node.tag == "GlobalFunction" or node.tag =="LocalFunction" or node.tag=="Function")then
			local fbody = utils.searchForTagItem('FuncBody', node.data)
			local fblock =  utils.searchForTagItem('Block', fbody.data)
			
			if (not statements["return"]) then statements["return"] = {} end
			countReturnStatements(fblock.data,statements)
		end
----------------------		
	
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
-- modifikoval Peter Kosa,  aby v HTML tabulke : "Statement usage" nebolo slovo "keyword" ale "return"				
					if(stat.tag == 'keyword' and stat.text == 'return') then
						if (not moduleMetrics["return"]) then moduleMetrics["return"] = {} end
						table.insert(moduleMetrics["return"], stat)
					else
						if (not moduleMetrics[stat.tag]) then moduleMetrics[stat.tag] = {} end
						table.insert(moduleMetrics[stat.tag], stat)
					end
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
