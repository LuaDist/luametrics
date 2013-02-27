-------------------------------------------------------------------------------
-- Metrics captures - generating tables for tree visualization of functions
-- @release 2011/05/04, Ivan Simko
-------------------------------------------------------------------------------


local pairs, print, table = pairs, print, table

local utils = require 'metrics.utils'

module ('metrics.captures.functiontree')

--------------------------------------------
-- Captures table for lpeg parsing - creates functiontree display
-- @class table
-- @name captures
captures = {

	[1] = function(node)
	
	
		local topmetrics = node.metrics
		topmetrics.functiontree = {}
	
		local block = utils.searchForTagItem_recursive('Block', node, 2)
		
		for _,fun in pairs(block.metrics.blockdata.fundefs) do
			
			-- all declared functions
			if (fun.metrics.functiontree == nil) then fun.metrics.functiontree = {} end
			local block = utils.searchForTagItem_recursive('Block', fun, 2)
			
			-- go upwards in AST tree and insert itself into functiontree variables of parent function
				
			local parent = fun.parent
				
			while (parent ~= nil) do
					
				if ((parent.tag == 'GlobalFunction' or parent.tag == 'LocalFunction' or parent.tag == 'Function') and parent.name ~= nil) then
					if (parent.metrics.functiontree == nil) then parent.metrics.functiontree = {} end
					table.insert(parent.metrics.functiontree, fun)
					break
				end
					
				parent = parent.parent
			end
				
			-- no parent function - insert itself into topmetrics - metrics of the topmost node	
			if (parent == nil) then
				table.insert(topmetrics.functiontree, fun)
			end
			
		end		
		
		return node
	end
}
