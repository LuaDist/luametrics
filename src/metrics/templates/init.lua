--Metrics initialization 

local metrics = require 'metrics'

local utils = require 'metrics.templates.utils'
local docTemplates = require 'metrics.templates.docMetricsTemplates'
local smellTemplates = require 'metrics.templates.smellTemplates'
local funcTableTemplates = require 'metrics.templates.funcTableTemplates'

--- Function that takes path to source file and directory that contains these souce files and find the tree structure from directory, returns number where the tree structure begins or nil when pattern not found
-- @param sample Sample path to source file
-- @param pattern Path to root directory of analysed source files
-- @author Martin Nagy
-- @return start of the tree structure in sample string or nil when pattern not found
local function customStringFind(sample, pattern)
	local i = 1

	if(#pattern > #sample) then --If path to root directory is longer than path to file
		return nil 
	end

	for i = 1, #pattern do --Looping trough paths and looking for match

		local sampleChar = string.sub(sample, i, i)
		local patternChar = string.sub(pattern, i, i)

		if(sampleChar ~= patternChar) then --If paths does not match
			return nil
		end
	end

	return (#pattern + 1) --If paths matches returns start of sample which is not included in pattern
	
end

--- Function takes path and directories and returns that part of the path which is not contained in one of the directories path
-- @param path Path to source file
-- @param directories List of directories of project in which can be path found
-- @author Martin Nagy
-- @return subpart of the path when success, full path when directory substring not found
function cutPathToSources(path, directiories)
	
	if(directiories == nil) then --If directory list not provided
		
		local index = string.find(path, "/[^/]*[[/].[^/]*]?$")
		return string.sub(path, index) --Returns subpath of last directory and filename eg: /directory/file.lua

	end

	for _, name in pairs(directiories) do --Loops through directories

		local index = name:match('^.*()/') --Checks for last /
		name = string.sub(name, 0, index)

		local res = customStringFind(path, name)
		if(res ~= nil) then --If file is in directory
			
			return ('/' .. string.sub(path, res)) --Returns substring
			
		end
	end
	
	return path --If none of the directories contains file returns full path
	
end

--- Function takes list of files and directories where are these stored, creates AST for each file and merge them in one result object with all metrics and ASTs
-- @param fileList List of fies to analyze
-- @param directories List of directories of project where files are stored
-- @author Martin Nagy
-- @return Object with all metrics and ASTs
local function createASTAndMerge(fileList, directiories)

	local metricsAST_results = {} --Create table for ASTs

	for _, filepath in pairs(fileList) do --Loop through files in fileList

		local text = utils.readFile(filepath) --Reads file
		local formatted_text = text:gsub("\r\n","\n"); --Substracts windows newlines (\r\n) with linux ones (\n) to prevent failures
		local AST = metrics.processText(formatted_text) --Create AST
			
		filepath = cutPathToSources(filepath, directiories) --Cut path to file to only contain filename and directory

		metricsAST_results[filepath] = AST --Save AST in temp table

	end

	local globalMetrics = metrics.doGlobalMetrics(metricsAST_results) --Create return object with all metrics and ASTs of project

	globalMetrics.moduleNum = #globalMetrics.moduleDefinitions --Add number of modules
	globalMetrics.fileNum = #fileList --Add number of files

	return globalMetrics

end

return {
	createASTAndMerge = createASTAndMerge
}

