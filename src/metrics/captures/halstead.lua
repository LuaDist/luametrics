-------------------------------------------------------------------------------
-- Metrics captures - computing of halstead metrics for each node
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------


local pairs, type, print, table = pairs, type, print, table
local utils = require 'metrics.utils'
local keys = (require 'metrics.rules').rules

local math = require('math')

module 'metrics.captures.halstead'

local function add(array, opText, count)
	if (array[opText] == nil) then 
		array[opText] = count or 1
	else
		array[opText] = array[opText] + (count or 1)
	end	
end

local moduleDefinitions = {}

----------------------------------------------
-- Function calculates Halstead metrics from its arguments and stored it into appropriate table in node
-- @param operators table of operators {name, count}
-- @param opedanrd table of operands {name, count}
-- @param metricsHalstead table to store values in
function calculateHalstead(metricsHalstead, operators, operands)

	local number_of_operators = 0
	local unique_operators = 0
	for op, count in pairs(operators) do 
		unique_operators = unique_operators + 1
		number_of_operators = number_of_operators + count
	end
	
	local number_of_operands = 0
	local unique_operands = 0
	for op, count in pairs(operands) do 
		unique_operands = unique_operands + 1
		number_of_operands = number_of_operands + count
	end

	metricsHalstead.operators = operators
	metricsHalstead.operands = operands
	
	metricsHalstead.number_of_operators = number_of_operators
	metricsHalstead.number_of_operands = number_of_operands
	metricsHalstead.unique_operands = unique_operands
	metricsHalstead.unique_operators = unique_operators
	
	metricsHalstead.LTH = number_of_operators + number_of_operands
	metricsHalstead.VOC = unique_operands + unique_operators
	metricsHalstead.DIF = (unique_operators / 2) * (number_of_operands/unique_operands)
	
	metricsHalstead.VOL = metricsHalstead.LTH * (math.log(metricsHalstead.VOC) / math.log(2) )
	metricsHalstead.EFF = metricsHalstead.DIF * metricsHalstead.VOL
	metricsHalstead.BUG = metricsHalstead.VOL/3000
	metricsHalstead.time = metricsHalstead.EFF / 18
	
end

-- for 'switch' like function calling
local actions = {

		_PrefixExp = function(node, operators, operands)
			-- operand - identifier
			add(operands, node.text)
			if (moduleMetrics) then 
				add(moduleMetrics.operands, node.text)
			end
		end,
		STRING = function(node, operators, operands)
			-- operand - constant
			add(operands, node.text)
			if (moduleMetrics) then 
				add(moduleMetrics.operands, node.text)
			end
		end,
		NUMBER = function(node, operators, operands)
			-- operand - constant
			add(operands, node.text)
			if (moduleMetrics) then 
				add(moduleMetrics.operands, node.text)
			end
		end,
		NameList = function(node, operators, operands)
			-- operand - identifier
			local names = utils.getNamesFromNameList(node)
			for _, name in pairs(names) do
				add(operands, name.text)
				if (moduleMetrics) then 
				add(moduleMetrics.operands, node.text)
			end
			end
		end,
		NumericFor = function(node, operators, operands)
			-- it's name is operand - identifier
			local nameNode = utils.searchForTagItem('Name', node.data)
			if (nameNode) then
				add(operands, nameNode.text)
				if (moduleMetrics) then 
				add(moduleMetrics.operands, node.text)
			end
			end
		end,
		symbol = function(node, operators, operands)
			-- operator - parts reserved for language Lua
			add(operators, node.text)
			if (moduleMetrics) then 
				add(moduleMetrics.operators, node.text)
			end
		end,
		keyword = function(node, operators, operands)
			-- operator - parts reserved for language Lua
			add(operators, node.text)
			if (moduleMetrics) then 
				add(moduleMetrics.operators, node.text)
			end
		end	
	}

local function doHalstead(node)
	local operators = {}				-- > {string_operator, number of times used}
	local operands = {}					-- > {string operand , number of times used}
	
	local moduleMetrics = nil

	for _, value in pairs(node.data) do
		
		-- check if current statement is function 'module'
		if (value.tag == 'Stat') then
			local stat = value.data[1]
			if (stat.tag == 'FunctionCall') then
				if (stat.data[1].data[1].text == 'module') then
					local exec = stat.data[1]
					
					-- set moduleMetrics variable - all next child nodes will also add its operator and operand values to moduleMetrics variable
					-- module is only from module function call downwards
					moduleDefinitions[exec] = {}
					if (moduleDefinitions[exec].metrics == nil) then moduleDefinitions[exec].metrics = {} end
					
					moduleDefinitions[exec].halstead = {
						operators = {},
						operands = {}
					}
					
					if (moduleMetrics) then 
						calculateHalstead(moduleMetrics, moduleMetrics.operators, moduleMetrics.operands)
					end
					
					moduleMetrics = moduleDefinitions[exec].halstead
				end	
			end
		end
		
		for k,v in pairs(value.metrics.halstead.operators) do
			add(operators, k, v)
			if (moduleMetrics) then 
				add(moduleMetrics.operators, k, v)
			end
		end
		
		for k,v in pairs(value.metrics.halstead.operands) do
			add(operands, k, v)
			if (moduleMetrics) then 
				add(moduleMetrics.operands, k, v)
			end
		end
		
		
		if (type(actions[value.tag]) == 'function') then actions[value.tag](value, operators, operands) end
		
	end
	
	if (node.metrics == nil) then node.metrics = {} end
	if (node.metrics.halstead == nil) then node.metrics.halstead = {} end
	
	calculateHalstead(node.metrics.halstead, operators, operands)
	if (moduleMetrics) then 
		calculateHalstead(moduleMetrics, moduleMetrics.operators, moduleMetrics.operands)
	end
	
end

--------------------------------------------
-- Captures table for lpeg parsing - computes halstead metrics for each node
-- @class table
-- @name captures
captures = (function()
	local key,value
	local new_table = {}
	for key,value in pairs(keys) do
		new_table[key] = function (node) 
			doHalstead(node)
			return node 
		end
	end	
	
	new_table[1] = function (node) 
		doHalstead(node)
		
		if not node.metrics.moduleDefinitions then node.metrics.moduleDefinitions = {} end
		
		for exec, data in pairs(moduleDefinitions) do
			if not node.metrics.moduleDefinitions[exec] then node.metrics.moduleDefinitions[exec] = {} end
			node.metrics.moduleDefinitions[exec].halstead = data.halstead
		end	
		
		moduleDefinitions = {}
		
		return node 
	end
	
	return new_table
end)()


