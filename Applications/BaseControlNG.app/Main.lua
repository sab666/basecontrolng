--local image = require("Image")
local screen = require("Screen")
local GUI = require("GUI")
local filesystem = require("Filesystem")
--local paths = require("Paths")
local system = require("System")
local event = require("Event")
local storage = require("Storage/Main")
local log = require("Storage/Log")

package.loaded["storage/main"] = nil -- force unload
package.loading["storage/main"] = nil
package.loaded["storage/log"] = nil -- force unload
package.loading["storage/log"] = nil

local MAIN_LOOP_DELAY = 5;

----------------------------------------------------------------------------------------------------------------

_G.logData = {}

local currentScriptDirectory = filesystem.path(system.getCurrentScript())
local modulesPath = currentScriptDirectory .. "Modules/"
local localization = system.getLocalization(currentScriptDirectory .. "Localizations/")

local workspace, window = system.addWindow(GUI.tabbedWindow(1, 1, 100, 40))

----------------------------------------------------------------------------------------------------------------

window.contentContainer = window:addChild(GUI.container(1, 4, window.width, window.height - 3))

local activityWidget = window:addChild(GUI.object(window.width - 4, 1, 4, 3))
activityWidget.hidden = true
activityWidget.position = 0
activityWidget.color1 = 0x99FF80
activityWidget.color2 = 0x00B640
activityWidget.draw = function(activityWidget)
  screen.drawText(activityWidget.x + 1, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⢀")
  screen.drawText(activityWidget.x + 2, activityWidget.y, activityWidget.position == 1 and activityWidget.color1 or activityWidget.color2, "⡀")

  screen.drawText(activityWidget.x + 3, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⠆")
  screen.drawText(activityWidget.x + 2, activityWidget.y + 1, activityWidget.position == 2 and activityWidget.color1 or activityWidget.color2, "⢈")

  screen.drawText(activityWidget.x + 1, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠈")
  screen.drawText(activityWidget.x + 2, activityWidget.y + 2, activityWidget.position == 3 and activityWidget.color1 or activityWidget.color2, "⠁")

  screen.drawText(activityWidget.x, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⠰")
  screen.drawText(activityWidget.x + 1, activityWidget.y + 1, activityWidget.position == 4 and activityWidget.color1 or activityWidget.color2, "⡁")
end

local overrideWindowDraw = window.draw
window.draw = function(...)
  if not activityWidget.hidden then
    activityWidget.position = activityWidget.position + 1
    if activityWidget.position > 4 then
      activityWidget.position = 1
    end
  end

  return overrideWindowDraw(...)
end

window.activity = function(state)
  activityWidget.hidden = not state
  window.contentContainer:draw()
end

local function loadModules()
  local modules = filesystem.list(modulesPath)
  table.sort(modules, function(a, b)
    return a < b
  end)

  for i = 1, #modules do
    if filesystem.extension(modules[i]) == ".lua" then
      local result, reason = loadfile(modulesPath .. modules[i])
      if result then
        local success, result = pcall(result, workspace, window, localization)
        if success then
          window.tabBar:addItem(result.name).onTouch = function()
            result.onTouch()
            workspace:draw()
          end
        else
          error("Failed to call loaded module \"" .. tostring(modules[i]) .. "\": " .. tostring(reason))
        end
      else
        error("Failed to load module \"" .. tostring(modules[i]) .. "\": " .. tostring(reason))
      end
    end
  end
end

local function saveConfig()
  filesystem.writeTable(currentScriptDirectory .. "config", _G.BaseConfig)
  return _G.BaseConfig
end

local function loadConfig()
  if not filesystem.exists(currentScriptDirectory .. "config") then
    os.copyfile(currentScriptDirectory .. "config.dist", currentScriptDirectory .. "config")
  end
  _G.BaseConfig = filesystem.readTable(currentScriptDirectory .. "config")
end

window.onResize = function(width, height)
  window.tabBar.width = width
  window.backgroundPanel.width = width
  window.backgroundPanel.height = height - 3
  window.contentContainer.width = width
  window.contentContainer.height = window.backgroundPanel.height
  window.tabBar:getItem(window.tabBar.selectedItem).onTouch()
end

function mainLoop()
  for item, stack in pairs(_G.BaseConfig) do
    local mod, name, damage = item:match("([^:]+):([^:]+):([^:]+)")
    local full_name = mod .. ":" .. name
    local stack_item = { name = full_name, damage = tonumber(damage) }
    local toCraft = tonumber(stack.total)

    local itemStack = storage.getItemsInNetwork(stack_item)[1]
    if toCraft > itemStack.size then
      if not storage.isCrafting(item) and not storage.isBusy() then
        if stack.emitRed then
          component.redstone.setWirelessFrequency(tonumber(stack.emitFreq))
          if not component.redstone.getWirelessOutput() then
            log.debug("[%] Emit wireless on signal for " .. itemStack.label .. "(" .. stack.emitFreq .. ")")
            component.redstone.setWirelessOutput(true)
          end
        end
        local amount = toCraft - itemStack.size
        log.info("[+] Crafting " .. itemStack.label .. " (" .. amount .. ")")
        storage.craft(item, amount)
      end
    else
      -- make sure wirestone signal is set
      if stack.emitRed then
        component.redstone.setWirelessFrequency(tonumber(stack.emitFreqOff))
        if not component.redstone.getWirelessOutput() then
          log.debug("[%] Emit wireless off signal for " .. itemStack.label .. "(" .. stack.emitFreqOff .. ")")
          component.redstone.setWirelessOutput(true)
        end
      end
    end
  end
  console.debug('Done with main loop, sleeping for ' .. MAIN_LOOP_DELAY .. ' seconds...')
  os.sleep(MAIN_LOOP_DELAY)
end

-- Cancel all events before close
window.actionButtons.close.onTouch = function()
  if _G.craftTimer then
    event.removeHandler(_G.craftTimer)
  end
  if _G.outputTimer then
    event.removeHandler(_G.outputTimer)
  end
  storage.stop()
  _G.logData = nil
  window:remove()
end

----------------------------------------------------------------------------------------------------------------

loadConfig()
storage.init()
loadModules()
_G.craftTimer = event.addHandler(mainLoop, 0, math.huge)
window:resize(window.width, window.height)
