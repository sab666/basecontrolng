local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local text = require("Text")

local module = {}
local workspace, window, localization = table.unpack({...})

----------------------------------------------------------------------------------------------------------------

module.name = localization.moduleNameSettings
module.margin = 0
module.onTouch = function()
  window.contentContainer:removeChildren()
end

----------------------------------------------------------------------------------------------------------------

return module

