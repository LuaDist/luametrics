-------------------------------------------------------------------------------
-- Metrics captures - computing of information flow metrics for functions
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------


local pairs, print, table = pairs, print, table
local utils = require 'metrics.utils'

module ('metrics.captures.infoflow')


local function do_information_flow(funcAST)

	local in_counter = 0
	local return_counter = 0
	local block = utils.getBlockFromFunction(funcAST)
	
	if (block) then -- should always be true but to be sure
		
		local usedNodes = {}
		
		-- get number of expressions in return statement
		local lastStat = utils.searchForTagItem('LastStat', block.data[1].data)
		if (lastStat) then
			local explist = utils.searchForTagItem('ExpList', lastStat.data)
			if (explist) then -- moze byt len obycajny return bez argumentov
				local expressions = utils.getExpsFromExpsList(explist)
				return_counter = #expressions			
				for k,v in pairs(expressions) do table.insert(usedNodes, v) end
			end
		end
		
		local parListNames = {}
		
		-- search for function's parameters
		local parlist = utils.searchForTagItem_recursive('ParList', funcAST, 2)
		if (parlist) then
			local nameList = parlist.data[1] -- can be a 'symbol' node (...)
			if (nameList.tag == 'NameList') then
				local names = utils.getNamesFromNameList(nameList)
				in_counter = #names
				for k,v in pairs(names) do 
					parListNames[v.text] = v
					table.insert(usedNodes, v) 
				end
			end
		end
	
		if (funcAST.metrics == nil) then funcAST.metrics = {} end
		
		local v_in, v_out = {}, {}
		
		-- count number of read and written remote variables
		for name, vars in pairs(block.metrics.blockdata.remotes) do
			for _, node in pairs(vars) do
				local used = false
				if (node.isRead) and parListNames[node.text] == nil then
					if not used then table.insert(v_in, node) used = true end
					table.insert(usedNodes, node)
				end
				if (node.isWritten) and parListNames[node.text] == nil then
					if not used then table.insert(v_out, node) used = true end
					table.insert(usedNodes, node)
				end
			end
		end
		
		-- calculate the metric
		funcAST.metrics.infoflow = {}
		funcAST.metrics.infoflow.information_flow = (#v_in * (#v_out + return_counter))^2
		funcAST.metrics.infoflow.arguments_in =	in_counter
		funcAST.metrics.infoflow.arguments_out = return_counter
		funcAST.metrics.infoflow.interface_complexity = in_counter + return_counter
		funcAST.metrics.infoflow.used_nodes = usedNodes	
	end
end

--------------------------------------------
-- Captures table for lpeg parsing - computes information flow metrics for functions
-- @class table
-- @name captures
captures = {
	GlobalFunction = function(data) do_information_flow(data) return data end, 
	LocalFunction = function(data) do_information_flow(data) return data end, 
	Function = function(data) do_information_flow(data) return data end,
}
