local metrics = require 'metrics'

local math = require 'math'

local io, table, pairs, type, print, ipairs = io, table, pairs, type, print, ipairs

module ("smells")

function doSomeStuff(file_metricsAST_list) --parameter anonymne funkcie
  
  local functionCount = 0
  
  local smell = {
    longMethod = {},
    cyclomatic = {},
    halstead = {},
    manyParameters = {},
    totalFunctions = 0,
    maxLOSC = 50,
    maxNOA = 10
  }
  
	for filename, AST in pairs(file_metricsAST_list) do
    
		for _, fun in pairs(AST.metrics.blockdata.fundefs) do

			if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction' or fun.tag == 'Function') then
        
        functionCount = functionCount + 1
        
        if(fun.fcntype == 'global' or fun.fcntype == 'local') then
          
          table.insert(smell.longMethod, {name = fun.name, LOC = fun.metrics.LOC.lines, LOSC = fun.metrics.LOC.lines_code})
          table.insert(smell.cyclomatic, {name = fun.name, cyclomatic = (fun.metrics.cyclomatic.decisions or 1)})
          table.insert(smell.manyParameters, {name = fun.name, NOA = fun.metrics.infoflow.arguments_in})
          table.insert(smell.halstead, {name = fun.name, EFF = fun.metrics.halstead.EFF})
          
        end
			end	
		end
	end
  
  table.sort(smell.longMethod, compareLOSC)
  table.sort(smell.cyclomatic, compareCyc)
  --table.sort(smell.halstead, compareCyc)
  table.sort(smell.manyParameters, compareNOA)
  
  smell.totalFunctions = functionCount
  
  return smell
  
end

function compareLOSC(functionA, functionB)
  
  return functionA.LOSC > functionB.LOSC
  
end

function compareNOA(functionA, functionB)
  
  return functionA.NOA > functionB.NOA
  
end

function compareCyc(functionA, functionB)
  
  return functionA.cyclomatic > functionB.cyclomatic
  
end

function compareHal(functionA, functionB)
  
  return functionA.EFF > functionB.EFF
  
end
