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

local threshold = 0.005
local work_on

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

local function get_trim_start(sample)
   local sample_value
   local nb_channels = sample.sample_buffer.number_of_channels
   local nb_frames = sample.sample_buffer.number_of_frames
   
   for frame_index=1,nb_frames do
      for channel_index=1,nb_channels do
	 sample_value = sample.sample_buffer:sample_data(channel_index, frame_index)
	 if math.abs(sample_value) > threshold then
	    return frame_index
	 end
      end
   end

   return 1
end

local function get_trim_end(sample)
   local sample_value
   local nb_channels = sample.sample_buffer.number_of_channels
   local nb_frames = sample.sample_buffer.number_of_frames

   for frame_index=nb_frames,1,-1 do
      for channel_index=1,nb_channels do
	 sample_value = sample.sample_buffer:sample_data(channel_index, frame_index)
	 if math.abs(sample_value) > threshold then
	    return frame_index
	 end
      end
   end

   return nb_frames
end

local function copy_sample_settings(source, target, offset)
   --target.slice_markers = source.slice_markers
   target.name = source.name
   target.panning = source.panning
   target.volume = source.volume
   target.transpose = source.transpose
   target.fine_tune = source.fine_tune
   target.beat_sync_enabled = source.beat_sync_enabled
   target.beat_sync_lines = source.beat_sync_lines
   target.interpolation_mode = source.interpolation_mode
   target.new_note_action = source.new_note_action
   target.oneshot = source.oneshot
   target.mute_group = source.mute_group
   target.autoseek = source.autoseek
   target.autofade = source.autofade
   target.loop_mode = source.loop_mode
   target.loop_release = source.loop_release
   target.loop_start = math.max(source.loop_start - offset,1)
   target.loop_end = math.min(source.loop_end - offset,target.sample_buffer.number_of_frames)
   --target.modulation_set = source.modulation_set
   target.device_chain_index = source.device_chain_index
   for i,map in pairs(renoise.song().selected_instrument.sample_mappings) do
      if map.sample == source then
	 map.sample = target
      end
   end

end

local function trim_one_sample(sample,sample_index)
   --print(sample_index)
   --if true then return end
--   local threshold = 0.005
   local trim_start, trim_end

   local bit_depth = sample.sample_buffer.bit_depth
   local sample_rate = sample.sample_buffer.sample_rate
   local nb_channels = sample.sample_buffer.number_of_channels
   local nb_frames = sample.sample_buffer.number_of_frames
   local sample_value
   local i = 1
   
   local start_time = os.clock()

   
   trim_start = get_trim_start(sample)
   trim_end = get_trim_end(sample)

   print(trim_start)
   print(trim_end)
   
   --sample.sample_buffer:prepare_sample_data_changes()
   local tmp = renoise.song().selected_instrument:insert_sample_at(1)
   tmp.sample_buffer:create_sample_data(sample_rate, bit_depth, nb_channels, trim_end-trim_start+1)
   
   for frame_index=trim_start,trim_end do
      for channel_index=1,nb_channels do
	 sample_value = sample.sample_buffer:sample_data(channel_index, frame_index)
	 tmp.sample_buffer:set_sample_data(channel_index, i, sample_value)

	 if os.clock() - start_time > .5 then
	    renoise.app():show_status('trimming...')
	    
	    coroutine.yield()
	    start_time = os.clock()
	 end

	 
      end
      i = i + 1
   end

   renoise.song().selected_instrument:swap_samples_at(1, sample_index + 1)
   copy_sample_settings(sample,tmp,trim_start-1)
   renoise.song().selected_instrument:delete_sample_at(1)
   
   --sample.sample_buffer:finalize_sample_data_changes()
   
end

local function trim_instrument()
   for sample_index, sample in pairs(renoise.song().selected_instrument.samples) do
      trim_one_sample(sample,sample_index)
   end
end

local function trim_sample()
   trim_one_sample(renoise.song().selected_sample,renoise.song().selected_sample_index)

end




local function trim()
   local start_time = os.clock()

   if work_on == 'sample' then
      trim_one_sample(renoise.song().selected_sample,renoise.song().selected_sample_index)
   else
      for sample_index, sample in pairs(renoise.song().selected_instrument.samples) do
	 trim_one_sample(sample,sample_index)
	 if os.clock() - start_time > .1 then
	    renoise.app():show_status('trimming...')
	    
	    coroutine.yield()
	    start_time = os.clock()
	 end
      end
   end
end











------------------------------------------------------------------------------
-- process stuff, needed to not hang the gui


class "ProcessSlicer"

function ProcessSlicer:__init(process_func, ...)
  assert(type(process_func) == "function", 
    "expected a function as first argument")

  self.__process_func = process_func
  self.__process_func_args = arg
  self.__process_thread = nil
end


--------------------------------------------------------------------------------
-- returns true when the current process currently is running

function ProcessSlicer:running()
  return (self.__process_thread ~= nil)
end


--------------------------------------------------------------------------------
-- start a process

function ProcessSlicer:start()
  assert(not self:running(), "process already running")
  
  self.__process_thread = coroutine.create(self.__process_func)
  
  renoise.tool().app_idle_observable:add_notifier(
    ProcessSlicer.__on_idle, self)
end


--------------------------------------------------------------------------------
-- stop a running process

function ProcessSlicer:stop()
  assert(self:running(), "process not running")

  renoise.tool().app_idle_observable:remove_notifier(
    ProcessSlicer.__on_idle, self)

  self.__process_thread = nil
end


--------------------------------------------------------------------------------

-- function that gets called from Renoise to do idle stuff. switches back 
-- into the processing function or detaches the thread

function ProcessSlicer:__on_idle()
  assert(self.__process_thread ~= nil, "ProcessSlicer internal error: "..
    "expected no idle call with no thread running")
  
  -- continue or start the process while its still active
  if (coroutine.status(self.__process_thread) == 'suspended') then
    local succeeded, error_message = coroutine.resume(
      self.__process_thread, unpack(self.__process_func_args))
    
    if (not succeeded) then
      -- stop the process on errors
      self:stop()
      -- and forward the error to the main thread
      error(error_message) 
    end
    
  -- stop when the process function completed
  elseif (coroutine.status(self.__process_thread) == 'dead') then
    self:stop()
  end
end


local slicer = ProcessSlicer(trim)


local function start_slicer()
   slicer:start()
end








--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function trim_dialog(work_on)
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
    vb:textfield {
       id = "threshold", 
       text = tostring(threshold)
    }
  } 
  
    local buttons = {"OK", "Cancel"}
    local choice = renoise.app():show_custom_prompt(
      tool_name, 
      content, 
      buttons
    )  
    if (choice == buttons[1]) then
       threshold = tonumber(vb.views.threshold.text)
       start_slicer()
       --[[
       if work_on == 'sample' then
	  trim_sample()
       else
	  trim_instrument()
       end
       --]]	  
    end

end


local function trim_dialog_sample()
   work_on = 'sample'
   trim_dialog()
end

local function trim_dialog_instrument()
   work_on = 'instrument'
   trim_dialog()
end





--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
   --name = "Main Menu:Tools:"..tool_name.."...",
   name = "Instrument Box:"..tool_name.." (All samples in instrument)",
   invoke = trim_dialog_instrument
   --invoke = trim_instrument
}


renoise.tool():add_menu_entry {
   name = "Sample Navigator:"..tool_name,
   invoke = trim_dialog_sample
   --invoke = trim_sample
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
