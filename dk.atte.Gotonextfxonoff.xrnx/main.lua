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




local function fx_device(fx)
   local device = string.sub(tostring(fx),1,1)
   if device == '1' then return 1
   elseif device == '2' then return 2
   elseif device == '3' then return 3
   elseif device == '4' then return 4
   elseif device == '5' then return 5
   elseif device == '6' then return 6
   elseif device == '7' then return 7
   elseif device == '8' then return 8
   elseif device == '9' then return 9
   elseif device == 'A' then return 10
   elseif device == 'B' then return 11
   elseif device == 'C' then return 12
   elseif device == 'D' then return 13
   elseif device == 'E' then return 14
   elseif device == 'F' then return 15
   elseif device == 'G' then return 16
   elseif device == 'H' then return 17
   elseif device == 'I' then return 18
   elseif device == 'J' then return 19
   elseif device == 'K' then return 20
   elseif device == 'L' then return 21
   elseif device == 'M' then return 22
   elseif device == 'N' then return 23
   elseif device == 'O' then return 24
   elseif device == 'P' then return 25
   elseif device == 'Q' then return 26
   elseif device == 'R' then return 27
   else return 10000
   end
end
      
   


local function line_has_device_on_off(pattern,track,line)
   if renoise.song().patterns[pattern].tracks[track].lines[line].is_empty then
      return false
   end

   local dev_count = #renoise.song().tracks[track].devices

   if dev_count<  2 then
      return false
   end
      
   for col = 1,8 do
      local fx = renoise.song().patterns[pattern].tracks[track].lines[line]:effect_column(col)
      local dev = string.sub(tostring(fx),1,1)
      local val = string.sub(tostring(fx),3)

      if (val == '01' or val == '00') and (string.sub(tostring(fx),2,2) == '0') and fx_device(dev) <= dev_count then
	 return true
      end
   end

   return false
end


local function goto(pattern,track,line)
   renoise.song().selected_sequence_index = pattern
   renoise.song().selected_line_index = line
end


local function not_found()
   if dialog and dialog.visible then
      dialog:show()
      return
   end
   
   vb = renoise.ViewBuilder()
   
   local content = vb:column {
      margin = 10,
      vb:text {
	 text = 'No device on/off found on track...'
      }
   } 
   
   
   local buttons = {"OK"}
   local choice = renoise.app():show_custom_prompt(
      tool_name, 
      content, 
      buttons
   )  
end





   

local function find_next_onoff()
   local start_track = renoise.song().selected_track_index
   local start_pattern = renoise.song().selected_pattern_index
   local start_seq = renoise.song().selected_sequence_index
   local start_line = renoise.song().selected_line_index
   local track = start_track

   -- print 'first run....'
   for pattern_seq = 1, #renoise.song().sequencer.pattern_sequence do
      local pattern = renoise.song().sequencer.pattern_sequence[pattern_seq]
      if pattern >= start_pattern then
	 for line = 1, renoise.song().patterns[pattern].number_of_lines do
	    if pattern ~= start_pattern or line > start_line then
	       if line_has_device_on_off(pattern,track,line) then
		  goto(pattern_seq,track,line)
		  return
	       end
	    end
	 end
      end
   end

   -- print 'second run....'
   for pattern_seq = 1, #renoise.song().sequencer.pattern_sequence do
      local pattern = renoise.song().sequencer.pattern_sequence[pattern_seq]
      if pattern <= start_pattern then
	 for line = 1, renoise.song().patterns[pattern].number_of_lines do
	    if pattern ~= start_pattern or line <= start_line then
	       if line_has_device_on_off(pattern,track,line) then
		  goto(pattern_seq,track,line)
		  return
	       end
	    end
	 end
      end
   end

   not_found()
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:"..tool_name.."...",
  invoke = find_next_onoff
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
