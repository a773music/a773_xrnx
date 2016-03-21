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


--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function clear_all_slice_markers(sample)
   for i,j in ipairs(sample.slice_markers) do
      sample.delete_slice_marker(sample,j)
   end
end

local function set_slices()
   local pos, len

--   print('---')

   local selected_sample = renoise.song().selected_sample
   if selected_sample.sample_mapping.read_only then
      clear_all_slice_markers(selected_sample)
   end

--   print(selected_sample.sample_buffer.selection_start)
--   print(selected_sample.sample_buffer.selection_end)
--   print(selected_sample.sample_buffer.number_of_frames)


   pos = selected_sample.sample_buffer.selection_start
   len = selected_sample.sample_buffer.selection_end -selected_sample.sample_buffer.selection_start

   while pos < selected_sample.sample_buffer.number_of_frames do
      selected_sample.insert_slice_marker(selected_sample,pos)
      pos = pos + len + 1
   end

   
   --renoise.song().instruments[].samples[]:insert_slice_marker(marker_sample_pos)

   
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------


renoise.tool():add_menu_entry {
   name = "Sample Editor:"..tool_name.."...",
   invoke = set_slices
			      }


--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

--[[
renoise.tool():add_keybinding {
  name = "Global:Tools:" .. tool_name.."...",
  invoke = show_dialog
}
--]]


--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
