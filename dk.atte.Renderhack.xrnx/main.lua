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
   self:add_property("Name", "RenderHack")
   self:add_property("Id", "Unknown Id")
end

local manifest = RenoiseScriptingTool()
local ok,err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value

hack_file = '/home/atte/renderHack'
local bits = 24
local out_dir = '/home/atte/'
local hz = 44100

--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

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
end

local function render_hack()
   renoise.song():render(out_dir, render_post)
end

local function render_post()
   os.remove(hack_file)
   -- close renoise
end  

local function hack()
   local in_file = io.open(hack_file, "r");
   local line
   local match

   local out_file = string.gsub(renoise.song().file_name,'.xrns','.wav')

   if(in_file)then
      --[[
      while (true) do
   line = in_file:read();
   if(not line) then
      break;
   end
   match = string.find(line,'=')
   if(match) then
      local value = string.sub(line,match+1)
      local var = string.sub(line,0,match-1)
      if(var == 'hz')then
         hz = value;
         elseif(var == 'out_dir')then
         --out_dir = value;
         elseif(var == 'bits')then
         bits = value
      end
   end
      end
      --]]
      renoise.song():render(out_file, render_post)
   end
end


local function delete_hack()
   os.remove(hack_file)
end



renoise.tool().app_new_document_observable:add_notifier(function()
                  hack()
end)
