--[[============================================================================
main.lua
============================================================================]]--

-- Placeholder for the dialog
--local dialog = nil

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

local function sliced_dialog()
   --if dialog and dialog.visible then
   --   dialog:show()
   --   return
   --end

   vb = renoise.ViewBuilder()
   
   local text_to_show = 'This is a sliced instrument.\nPlease run "Destructively Render Slices" first.'
   
   local content = vb:column {
      margin = 10,
      vb:text {
	 text = text_to_show
      }
   } 
   
   
   local buttons = {"OK"}
   local choice = renoise.app():show_custom_prompt(
      tool_name, 
      content, 
      buttons
						  )
end

local function process()
   local selected_sample = renoise.song().selected_sample
   local base_note = selected_sample.sample_mapping.base_note

   if selected_sample.sample_mapping.read_only then
      sliced_dialog()
   else
      renoise.song().selected_instrument.midi_input_properties.note_range = {base_note,base_note}
      renoise.song().selected_instrument.sample_mapping_overlap_mode = renoise.Instrument.OVERLAP_MODE_RANDOM
      for index, value in ipairs(renoise.song().selected_instrument.samples) do
	 value.sample_mapping.base_note = base_note
	 value.sample_mapping.note_range = {base_note,base_note}
	 value.sample_mapping.velocity_range = {0,127}
      end
   end
end




--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   name = "Sample Navigator:"..tool_name,
   invoke = process
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
