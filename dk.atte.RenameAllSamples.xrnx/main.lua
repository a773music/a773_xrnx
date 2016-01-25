--[[============================================================================
main.lua
============================================================================]]--

-- Reload the script whenever this file is saved. 
-- Additionally, execute the attached function.
_AUTO_RELOAD_DEBUG = function()
  
end

-- Read from the manifest.xml file.
class "RenoiseScriptingTool" (renoise.Document.DocumentNode)
function RenoiseScriptingTool:__init()    
   renoise.Document.DocumentNode.__init(self) 
   self:add_property("Name", "Untitled Tool")
   self:add_property("Id", "Unknown Id")
end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value


local function rename()
   local basename = renoise.song().selected_instrument.name
   local nb_samples = #renoise.song().selected_instrument.samples
   local format = "%01d"
   if nb_samples >= 10 then
      format = "%02d"
   end
   if nb_samples >= 100 then
      format = "%03d"
   end

   for index, value in ipairs(renoise.song().selected_instrument.samples) do
      value.name = basename.." "..string.format(format, index)
   end

end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   name = "Sample Navigator:"..tool_name,
   invoke = rename
			      }

