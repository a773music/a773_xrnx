--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
local dialog = nil

-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil

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

local function extract_loop_point(filename)
   if string.match(filename,'loop_') then
      local loop_point = string.gsub(filename,'.*loop_','')
      return tonumber(loop_point)
   end
end

local function set_loops()
   local instrument = renoise.song().selected_instrument
   for i, sample in pairs(renoise.song().selected_instrument.samples) do
      local loop_point = extract_loop_point(sample.name)
      if loop_point then
	 sample.loop_mode = renoise.Sample.LOOP_MODE_FORWARD
	 sample.loop_start = loop_point + 1
      end
   end
      
      
end



--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
--  name = "Main Menu:Tools:"..tool_name.."...",
   name = "Instrument Box:"..tool_name.." (All Samples)",
   invoke = set_loops
}


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = set_loops
}
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = set_loops
}
--]]
