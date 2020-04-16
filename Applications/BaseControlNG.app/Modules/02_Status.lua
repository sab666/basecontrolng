local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local text = require("Text")

local module = {}
local workspace, window, localization = table.unpack({...})

----------------------------------------------------------------------------------------------------------------

module.name = localization.moduleNameStatus
module.margin = 0
module.onTouch = function()
  window.activity(true)
  window.contentContainer:removeChildren()
  
  --local allItems = component.get("me_interface").getItemsInNetwork()
  local allItems = component.get("me_interface").getCraftables()

  GUI.alert(allItems.n)
  window.activity(false)
end

----------------------------------------------------------------------------------------------------------------

return module

