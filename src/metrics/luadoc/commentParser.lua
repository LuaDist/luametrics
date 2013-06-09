-------------------------------------------------------------------------------
-- CommentParser - parser of Luadoc comments(and Explua comments starting with --- )
-- @release 2011/05/04, Ivan Simko
-- @release 2013/04/24, Peter Kosa
-------------------------------------------------------------------------------

local lpeg = require 'lpeg'
local grammar = require 'leg.grammar'
local scanner = require 'leg.scanner'
local comments = require 'comments'

module ('metrics.luadoc.commentParser', package.seeall)

-------------------------------------------------
-- Function for LuaDoc comment parsing (and Explua comments starting with --- )
-- @class function
-- @name parse
function parse(text)

local result
--^ `novy parser z modulu comments`
--info converts new result table of comments parser to old form
local t={}

if(string.match(text,"^[%s]*%-%-%-"))then
	for v in string.gmatch(text,"[^\n]+")do
		-- print(v)
			local minires =comments.Parse(v)
				
			if(minires and minires.style=="luadoc")then 
				table.insert(t,v)
				for key,val in pairs(minires) do
					if(key~="style")then
						if(key=="type" and val=="descr" )then
							table.insert(t,minires.text)	
							table.insert(t,{tag="comment",text=minires.text})
						elseif(key=="type" and (val=="class" or val=="name") )then
							table.insert(t,minires.name)	
							table.insert(t,{tag="item",item=val,text=minires.name})
						elseif(key=="type")then
							table.insert(t,minires.text)	
							table.insert(t,{tag="item",item=val,text=minires.name,textt=minires.text})
						end

					end
				end
			elseif(minires and minires.style=="explua")then
				table.insert(t,v)
				for key,val in pairs(minires) do
					if(key~="style")then
						if(key=="type" and val=="descr" )then
							table.insert(t,minires.text)	
							table.insert(t,{tag="comment",text=minires.text})
						elseif(key=="type" and (val=="class" or val=="name") )then
							table.insert(t,minires.name)	
							table.insert(t,{tag="item",item=val,text=minires.name})
						elseif(key=="type" and val=="table" )then
							table.insert(t,"table")
							table.insert(t,{text="table",item="class",tag="item"})	
							table.insert(t,{text=minires.var,item="name",tag="item"})	
							table.insert(t,{tag="comment",text=minires.text})
						elseif(key=="type" and val=="tablefield")then
							table.insert(t,"table")
							table.insert(t,{text=minires.var,item="field",tag="item",textt=minires.text,table=minires.table})	
						elseif(key=="type")then
							table.insert(t,minires.text)	
							table.insert(t,{tag="item",item=val,text=minires.name,textt=minires.text})
						end

					end
				end
			end

	end
	result=t
end
--v
	return result
end
