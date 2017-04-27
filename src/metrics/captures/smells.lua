local math = require 'math'

local pairs, print, table = pairs, print, table

local function compareLOSC(functionA, functionB)
  
  return functionA.LOSC > functionB.LOSC
  
end

local function compareNOA(functionA, functionB)
  
  return functionA.NOA > functionB.NOA
  
end

local function compareCyc(functionA, functionB)
  
  return functionA.cyclomatic > functionB.cyclomatic
  
end

local function compareHal(functionA, functionB)
  
  return functionA.EFF > functionB.EFF
  
end

local function round(num, numDecimalPlaces)
  
  local mult = 10^(numDecimalPlaces or 0)
  return math.floor(num * mult + 0.5) / mult
  
end

local function countFunctionSmells(file_metricsAST_list)
  
  local functionCount = 0
  
  local smell = {
    longMethod = {},
    cyclomatic = {},
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
          
          table.insert(smell.longMethod, {file = filename, name = fun.name, LOC = fun.metrics.LOC.lines, LOSC = fun.metrics.LOC.lines_code})
          table.insert(smell.cyclomatic, {file = filename, name = fun.name, cyclomatic = (fun.metrics.cyclomatic.decisions or 1)})
          table.insert(smell.manyParameters, {file = filename, name = fun.name, NOA = fun.metrics.infoflow.arguments_in})
          
        end
			end	
		end
	end
  
  table.sort(smell.longMethod, compareLOSC)
  table.sort(smell.cyclomatic, compareCyc)
  table.sort(smell.manyParameters, compareNOA)
  
  smell.totalFunctions = functionCount
  
  return smell
  
end

local function countMI(file_metricsAST_list)
  
  local MI = 0
  local cyclomatic = 0
  local halsteadVol = 0
  local LOSC = 0
  local comments = 0
  local commentPerc = 0
  local files = 0
  
  for filename, AST in pairs(file_metricsAST_list) do
    
    files = files + 1
    cyclomatic = cyclomatic + AST.metrics.cyclomatic.decisions_all
    halsteadVol = halsteadVol + AST.metrics.halstead.VOL
    LOSC = LOSC + AST.metrics.LOC.lines_code
    comments = comments + AST.metrics.LOC.lines_comment  
    
	end
  
  commentPerc = comments / LOSC
  MI = 171 
          - (5.2 * math.log(halsteadVol / files))
          - (0.23 * (cyclomatic / files))
          - (16.2 * math.log(LOSC / files))
          + (50 * math.sin(math.sqrt(2.4 * (commentPerc / files))))
  
  return round(MI, 2)
  
end

local function countFileSmells(funcAST)
  
  local RFC = 0 --Response for class - Sum of no. executed methods and no. methods in class (file)
  local CBO = 0 --Coupling between module (file) and other big modules in whole project
  local WMC = 0 --Weighted method per class - sum of cyclomatic complexity of functions in class (file)
  local NOM = 0 --No. methods in class (file)
  
  for name, value in pairs(funcAST.metrics.functionExecutions) do
    
    for name, value in pairs(value) do
      RFC = RFC + 1
    end
    
  end
    
  for name, value in pairs(funcAST.metrics.moduleCalls) do
    
    if(name ~= 'math') then -- something is wrong - math etc. module calls contains math but not table string etc...
      
      CBO = CBO + 1
        
    end
    
  end
  
  for _, fun in pairs(funcAST.metrics.blockdata.fundefs) do
    
    if (fun.tag == 'GlobalFunction' or fun.tag == 'LocalFunction' or fun.tag == 'Function') then
      
      RFC = RFC + 1
        
      WMC = WMC + (fun.metrics.cyclomatic.decisions or 1)
      NOM = NOM + 1
        
    end
  end
    
  funcAST.smells = {}
  funcAST.smells.RFC = RFC
  funcAST.smells.WMC = WMC
  funcAST.smells.NOM = NOM
  funcAST.smells.responseToNOM = round((RFC / NOM), 2)
  funcAST.smells.CBO = CBO
  
end



local captures = {
  
	[1] = function(data) countFileSmells(data) return data end,
  
}

return {captures = captures, countFunctionSmells = countFileSmells, countMI = countMI, countFunctionSmells = countFunctionSmells}