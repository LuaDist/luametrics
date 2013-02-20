-------------------------------------------------------------------------------
-- Metrics captures - computing cyclomatic complexity metric for functions
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------

local keys = (require 'metrics.rules').rules
local utils = require 'metrics.utils'
local pairs, print, string = pairs, print, string

module 'metrics.captures.cyclomatic'

-- helper function for adding count(number) of name(example 'operators') into a node
local function add(node, name, count)
	count = count or 0

	if (not node.metrics) then node.metrics = {} end
	if (not node.metrics.cyclomatic) then node.metrics.cyclomatic = {} end
	
	if (node.metrics.cyclomatic[name]) then
		node.metrics.cyclomatic[name] = node.metrics.cyclomatic[name] + count
	else
		node.metrics.cyclomatic[name] = count 
	end
	
end

-- copy number of decisions and conditions from children nodes
local function copyData(node)
	
	local children = node.data
	
	local NOTcopyFrom = {
		Function 		= true, 
		GlobalFunction 	= true, 
		LocalFunction 	= true, 
		Assign 			= true, 
		LocalAssign 	= true,
	}
	
	for _, child in pairs(children) do
		if (child.metrics and child.metrics.cyclomatic) then 
			if (NOTcopyFrom[child.tag] == nil) then
				add(node, 'decisions',  child.metrics.cyclomatic.decisions or 0)
				add(node, 'conditions',  child.metrics.cyclomatic.conditions or 0)
			end
			add(node, 'decisions_all',  child.metrics.cyclomatic.decisions_all or 0)
			add(node, 'conditions_all',  child.metrics.cyclomatic.conditions_all or 0)
		end
	end
	
end

-- calculate lower bound for cyclomatic complexity
local function setLowerBound(node)
	if (not node.metrics) then node.metrics = {} end
	if (not node.metrics.cyclomatic) then node.metrics.cyclomatic = {} end
	
	
	node.metrics.cyclomatic.lowerBound = (node.metrics.cyclomatic.decisions or 0) + 1
	node.metrics.cyclomatic.lowerBound_all = (node.metrics.cyclomatic.decisions_all or 0) + 1
	
end

-- calculate upper bound for cyclomatic complexity
local function setUpperBound(node)
	if (not node.metrics) then node.metrics = {} end
	if (not node.metrics.cyclomatic) then node.metrics.cyclomatic = {} end
	
	node.metrics.cyclomatic.upperBound = (node.metrics.cyclomatic.conditions or 0) + 1
	node.metrics.cyclomatic.upperBound_all = (node.metrics.cyclomatic.conditions_all or 0) + 1
	
end

local function countConditions(expression)
	if (not expression) then return end
	
	local simpleExps = utils.searchForTagArray('_SimpleExp', expression.data)
	
	local binops = utils.searchForTagArray('BinOp', expression.data)
	local count_and_or = 0
	if (not string.find(expression.text, '^%(')) then count_and_or = 1 end
	
	for _, op in pairs(binops) do
		local key = op.data[1].key
		if (key == 'AND' or key == 'OR') then
			count_and_or = count_and_or + 1
		end
	end
	
	for _, simpleExp in pairs(simpleExps) do
		if (string.find(simpleExp.text, '^%(')) then
			local current_exp = utils.searchForTagItem_recursive('Exp', simpleExp, 3)
			count_and_or = count_and_or + countConditions(current_exp)
		end
	end
	return count_and_or
end

--------------------------------------------
-- Captures table for lpeg parsing - computes lines of code metrics for each node
-- @class table
-- @name captures
captures = (function()
	local key,value
	local capture_table = {}
	for key,value in pairs(keys) do
		capture_table[key] = function (node) 
			copyData(node)
			return node 
		end
	end
	
	capture_table.If = function(node)
		copyData(node)
		add(node, 'decisions', 1)
		add(node, 'decisions_all', 1)
		
		local if_else = utils.searchForTagArray_key('ELSEIF', node.data)
		if (#if_else > 0) then 
			add(node, 'decisions', #if_else)
			add(node, 'decisions_all', #if_else)
		end
 		
 		local count = 0
 		local exps = utils.searchForTagArray('Exp', node.data)
 		for _, expression in pairs(exps) do
			count = count + countConditions(expression)
		end
		
		add(node, 'conditions', count)
		add(node, 'conditions_all', count)
		
		return node
	end
	
	capture_table.NumericFor = function(node)
		copyData(node)
		add(node, 'decisions', 1)
		add(node, 'decisions_all', 1)
		add(node, 'conditions', 1)
		add(node, 'conditions_all', 1)
		return node
	end
	
	capture_table.GenericFor = function(node)
		copyData(node)
		add(node, 'decisions', 1)
		add(node, 'decisions_all', 1)
		add(node, 'conditions', 1)
		add(node, 'conditions_all', 1)
		return node
	end
	
	capture_table.While = function(node)	
		copyData(node)
		add(node, 'decisions', 1)
		add(node, 'decisions_all', 1)
		
		local exps = utils.searchForTagItem('Exp', node.data)
		local count = countConditions(exps)
		add(node, 'conditions', count)
		add(node, 'conditions_all', count)
		
		return node
	end
	
	capture_table.Repeat = function(node)	
		copyData(node)
		add(node, 'decisions', 1)
		add(node, 'decisions_all', 1)
		
		local exps = utils.searchForTagItem('Exp', node.data)
		local count = countConditions(exps)
		add(node, 'conditions', count)
		add(node, 'conditions_all', count)
		
		return node
	end
	
	
	capture_table.Function = function(node)
		copyData(node)
		setLowerBound(node)
		setUpperBound(node)
		return node
	end
	
	capture_table.LocalFunction = function(node)
		copyData(node)
		setLowerBound(node)
		setUpperBound(node)
		return node
	end
	
	capture_table.GlobalFunction = function(node)
		copyData(node)
		setLowerBound(node)
		setUpperBound(node)
		return node
	end
	
	return capture_table
end)()


