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

local function fade_in(sample, nb_samples)
   local sample_value
   local nb_channels = sample.sample_buffer.number_of_channels
   local nb_frames = sample.sample_buffer.number_of_frames
   
   nb_samples = math.min(nb_samples,nb_frames/2)
   
   local gain = 0
   for frame_index=1,nb_samples do
      gain = 1 / nb_samples * (frame_index-1)
      for channel_index=1,nb_channels do
	 sample_value = sample.sample_buffer:sample_data(channel_index, frame_index)
	 sample.sample_buffer:set_sample_data(channel_index, frame_index, sample_value*gain)
      end
   end
end

local function fade_out(sample, nb_samples)
   local sample_value, frame_index
   local nb_channels = sample.sample_buffer.number_of_channels
   local nb_frames = sample.sample_buffer.number_of_frames
   
   nb_samples = math.min(nb_samples,nb_frames/2)
   
   local gain = 0
   for i=0,nb_samples-1 do
      frame_index = nb_frames - i
      gain = 1 / nb_samples * i
      for channel_index=1,nb_channels do
	 sample_value = sample.sample_buffer:sample_data(channel_index, frame_index)
	 sample.sample_buffer:set_sample_data(channel_index, frame_index, sample_value*gain)
      end
   end
end

local function declick_one_sample(sample)
   sample.sample_buffer:prepare_sample_data_changes()
   local fade_time = 0.002
   local nb_samples = sample.sample_buffer.sample_rate * fade_time

   fade_in(sample,nb_samples)
   fade_out(sample,nb_samples)

   sample.sample_buffer:finalize_sample_data_changes()
end

local function declick_instrument()
   for s, sample in pairs(renoise.song().selected_instrument.samples) do
      declick_one_sample(sample)
   end
end

local function declick_sample()   
   declick_one_sample(renoise.song().selected_sample)

end

-- This example function is called from the GUI below.
-- It will return a random string. The GUI function displays 
-- that string in a dialog.
local function get_greeting()
  local words = {"Hello world!", "Nice to meet you :)", "Hi there!"}
  local id = math.random(#words)
  return words[id]
end


--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()

  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end
  
  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  
  -- The content of the dialog, built with the ViewBuilder.
  local content = vb:column {
    margin = 10,
    vb:text {
      text = get_greeting()
    }
  } 
  
  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.   
  dialog = renoise.app():show_custom_dialog(tool_name, content)  
  
  
  -- A custom prompt is a modal dialog, restricting interaction to itself. 
  -- As long as the prompt is displayed, the GUI thread is paused. Since 
  -- currently all scripts run in the GUI thread, any processes that were running 
  -- in scripts will be paused. 
  -- A custom prompt requires buttons. The prompt will return the label of 
  -- the button that was pressed or nil if the dialog was closed with the 
  -- standard X button.  
  --[[ 
    local buttons = {"OK", "Cancel"}
    local choice = renoise.app():show_custom_prompt(
      tool_name, 
      content, 
      buttons
    )  
    if (choice == buttons[1]) then
      -- user pressed OK, do something  
    end
  --]]
end


--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   --name = "Main Menu:Tools:"..tool_name.."...",
   name = "Instrument Box:"..tool_name.." (All samples in instrument)",
   invoke = declick_instrument
}


renoise.tool():add_menu_entry {
   name = "Sample Navigator:"..tool_name,
   invoke = declick_sample
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
