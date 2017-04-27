local metrics = require 'metrics'

local docTemplates = require 'metrics.templates.docMetricsTemplates'
local smellTemplates = require 'metrics.templates.smellTemplates'
local funcTableTemplate = require 'metrics.templates.funcTableTemplates'

local function readFile(_sFileName)

	local f = io.input(_sFileName)
	local sData_ = f:read("*a")
	f:close()
	return sData_

end

local function customStringFind(sample, pattern)
	local i = 1

	if(#pattern > #sample) then 
		return nil 
	end

	for i = 1, #pattern do

		local sampleChar = string.sub(sample, i, i)
		local patternChar = string.sub(pattern, i, i)

		if(sampleChar ~= patternChar) then
			return nil
		end
	end

	return (#pattern + 1)
	
end

function cutPathToSources(path, directiories)
	
	if(directiories == nil) then

		local index = string.find(path, "/[^/]*[[/].[^/]*]?$")
		return string.sub(path, index)

	end

	for _, name in pairs(directiories) do

		local index = name:match('^.*()/')
		name = string.sub(name, 0, index)

		local res = customStringFind(path, name)
		if(res ~= nil) then
			
			return ('/' .. string.sub(path, res))
			
		end
	end

	return path
	
end

local function createASTAndMerge(fileList, directiories)

	local metricsAST_results = {}

	for _, filepath in pairs(fileList) do

		local text = readFile(filepath)
		local formatted_text = text:gsub("\r\n","\n");
		local AST = metrics.processText(formatted_text)
			
		filepath = cutPathToSources(filepath, directiories)

		metricsAST_results[filepath] = AST

	end

	local globalMetrics = metrics.doGlobalMetrics(metricsAST_results)

	globalMetrics.moduleNum = #globalMetrics.moduleDefinitions
	globalMetrics.fileNum = #fileList

	return globalMetrics

end

return {
	createASTAndMerge = createASTAndMerge
}

