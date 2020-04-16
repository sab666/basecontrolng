local GUI = require("GUI")
local screen = require("Screen")
local image = require("Image")
local paths = require("Paths")
local text = require("Text")
local event = require("event")
local filesystem = require("Filesystem")
local system = require("System")
local storage = require("Storage/Main")
local log = require("Storage/Log")

local module = {}
local workspace, window, localization = table.unpack({...})
local currentScriptDirectory = filesystem.path(system.getCurrentScript())

----------------------------------------------------------------------------------------------------------------

module.name = localization.moduleNameOverview
module.margin = 0
module.onTouch = function()
  window.activity(true)
  window.contentContainer:removeChildren()
 
  local craftPanel = window.contentContainer:addChild(GUI.panel(1,1,1,1, 0xE1E1E1))
  local mainLayout = window.contentContainer:addChild(GUI.layout(1,1, window.contentContainer.width, window.contentContainer.height, 3, 1))
  mainLayout.showGrid = false
  mainLayout:setColumnWidth(1, GUI.SIZE_POLICY_RELATIVE, 0.3)
  mainLayout:setColumnWidth(2, GUI.SIZE_POLICY_ABSOLUTE, 2)
  mainLayout:setColumnWidth(3, GUI.SIZE_POLICY_RELATIVE, 0.7)
  mainLayout:setFitting(1,1, true, true)
  mainLayout:setFitting(2,1, true, false)
  mainLayout:setSpacing(2,1, 0)
  mainLayout:setAlignment(2,1, GUI.ALIGNMENT_HORIZONTAL_LEFT, GUI.ALIGNMENT_VERTICAL_CENTER)
  mainLayout:setFitting(3,1, true, true)
  
  local treeLayout = mainLayout:setPosition(1,1, mainLayout:addChild(GUI.layout(1,1,1,1,1,2)))
  treeLayout.showGrid = false
  treeLayout:setRowHeight(1, GUI.SIZE_POLICY_RELATIVE, 1.0) -- 0.6
  --treeLayout:setRowHeight(2, GUI.SIZE_POLICY_RELATIVE, 0.1)
  treeLayout:setRowHeight(2, GUI.SIZE_POLICY_ABSOLUTE, 3)
  treeLayout:setFitting(1,1, true, true)
  treeLayout:setFitting(1,2, true, true)
  local resizer = mainLayout:setPosition(2,1, mainLayout:addChild(GUI.resizer((treeLayout.localX + treeLayout.width) - 2, treeLayout.localY + math.floor(treeLayout.height / 2), 1, 4, 0xAAAAAA, 0x0)))

  local tree = treeLayout:setPosition(1,1, treeLayout:addChild(GUI.tree(1,1,1,1, 0xE1E1E1, 0x3C3C3C, 0x3C3C3C, 0xAAAAAA, 0x3C3C3C, 0xFFFFFF,  0xBBBBBB, 0xAAAAAA, 0xC3C3C3, 0x444444, GUI.IO_MODE_BOTH, GUI.IO_MODE_FILE)))
  local searchTree = treeLayout:setPosition(1,2, treeLayout:addChild(GUI.input(1,1,1,1, 0x444444, 0x666666, 0x888888, 0x444444, 0x262626, nil, "Search")))
  searchTree.onInputFinished = function()
    tree.onItemExpanded()
  end

  local function dump(o)
    if type(o) == 'table' then
      local s = '{ '
      for k,v in pairs(o) do
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v) .. ","
      end
      return s .. '} '
    else
      return tostring(o)
    end
  end
  




  -- Items
  local itemsLayout = mainLayout:setPosition(3,1, mainLayout:addChild(GUI.layout(1,1,1,1,1,2)))
  itemsLayout.showGrid = false
  itemsLayout:setRowHeight(1, GUI.SIZE_POLICY_RELATIVE, 0.6) -- 0.6
  itemsLayout:setRowHeight(2, GUI.SIZE_POLICY_RELATIVE, 0.4)
  itemsLayout:setFitting(1,1, true, false, 6, 0)
  itemsLayout:setFitting(1,2, true, true, 0, 0)
  itemsLayout:setAlignment(1,2, GUI.ALIGNMENT_HORIZONTAL_CENTER, GUI.ALIGNMENT_VERTICAL_BOTTOM)

  local itemLabel   = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.label(1,1,1,1, 0x3C3C3C, "")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER,GUI.ALIGNMENT_VERTICAL_TOP))
  local infoLabel   = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.label(1,1,1,1, 0x3C3C3C, "Nothing selected")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_CENTER,GUI.ALIGNMENT_VERTICAL_TOP))
  local totalLabel  = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.label(1,1,1,1, 0x3C3C3C, "Available: 0")):setAlignment(GUI.ALIGNMENT_HORIZONTAL_LEFT,GUI.ALIGNMENT_VERTICAL_BOTTOM))
  local itemEnabled = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.switchAndLabel(2,2,25,8, 0x66DB80, 0x1D1D1D, 0x666666, 0x999999, "Enabled", false)))
  local totalCreate = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "Total")))
  local itemIdle    = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.switchAndLabel(2,2,25,8, 0x66DB80, 0x1D1D1D, 0x666666, 0x999999, "Only while Idle", false)))
  local emitRed     = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.switchAndLabel(2,2,25,8, 0x66DB80, 0x1D1D1D, 0x666666, 0x999999, "Emit wireless redstone at total", false)))

  
  local emitLayout  = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.layout(1,1,1,1,2,1)))
  emitLayout:setFitting(1,1, true, false, 6, 0)
  emitLayout:setFitting(2,1, true, false, 6, 0)
  emitLayout:setDirection(1,1, GUI.DIRECTION_HORIZONTAL)
  emitLayout:setDirection(2,1, GUI.DIRECTION_HORIZONTAL)
  local emitFreq    = emitLayout:setPosition(1,1, emitLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "On Frequency")))
  local emitFreqOff = emitLayout:setPosition(2,1, emitLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "Off Frequency")))
  emitFreq.hidden   = true
  emitFreqOff.hidden   = true

  --itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.input(1,1,1,3, 0xFFFFFF, 0x666666, 0x888888, 0xFFFFFF, 0x262626, nil, "Threshold")))
  local itemSubmit   = itemsLayout:setPosition(1,1, itemsLayout:addChild(GUI.button(1,1,1,1,0x3C3C3C, 0xFFFFFF, 0x0, 0xFFFFFF, "Save")))

  local outputTextBox= itemsLayout:setPosition(1,2, itemsLayout:addChild(GUI.textBox(1,1,1,1, 0x000000, 0x888888,{}, 1, 0,0)))
  outputTextBox.lines = {}

  totalCreate.validator = function (text)
    return tonumber(text) ~= nil
  end

  workspace:draw()
  local allCraftable = {}

  loading = coroutine.create(function()
    local items = storage.getCraftables()
    for i,item in ipairs(items) do
      window.contentContainer:draw()
      local mod,name = item.name:match("([^:]+):([^:]+)")
      local item_name = item.name .. ":" .. item.damage
      if not allCraftable[mod] then
        allCraftable[item_name] = {}
      end
      allCraftable[item_name] = {
        name=item.name,
        mod=mod,
        label=item.label,
        damage=tonumber(item.damage),
        full_item_name=item_name
      }
    end
    return allCraftable
  end)

  local function updateTree()
    local function updateRecursively(t, definitionName, offset)
      local list = {}
      for key in pairs(t) do
        table.insert(list, key)
      end

      local i, expandables = 1, {}
      while i <= #list do
        if type(t[list[i]]) == "table" then
          table.insert(expandables, list[i])
          table.remove(list, i)
        else
          i = i + 1
        end
      end

      table.sort(expandables, function(a, b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)
      table.sort(list, function(a, b) return unicode.lower(tostring(a)) < unicode.lower(tostring(b)) end)

      for i = 1, #expandables do
        local definition = definitionName .. expandables[i] .. "."

        tree:addItem(
          tostring(expandables[i]),
          definition,
          offset,
          true
        )                 

        if tree.expandedItems[definition] then
          updateRecursively(t[expandables[i]], definition, offset + 2) 
        end               
      end         

      for i = 1, #list do 
        tree:addItem(     
          tostring(list[i]),      
          { key=list[i], value=t[list[i]]},
          offset,                 
          false                   
        )                 
      end         
    end

    local craftable = {}
    for i,item in pairs(allCraftable) do
      local label = item.label
      -- Mark Actives with *
      if _G.BaseConfig[item.full_item_name] then
        label = "* "..label
      end

      if (#searchTree.text == 0 or string.match(string.lower(label), string.lower(searchTree.text))) then
        if not craftable[item.mod] then
          craftable[item.mod] = {}
        end
        craftable[item.mod][label] = item.full_item_name
      end
    end

    tree.items = {}
    updateRecursively(craftable, "", 1)
  end

  tree.onItemExpanded = function()
    updateTree()
  end

  resizer.onResize = function(dragWidth, dragHeight)
    local newWidth = treeLayout.width + dragWidth
    if newWidth <= 15 then
      newWidth = 15
    end
    mainLayout:setColumnWidth(1, GUI.SIZE_POLICY_ABSOLUTE, newWidth)
    treeLayout.width = newWidth
    resizer.localX = resizer.localX + dragWidth
    mainLayout:setColumnWidth(3, GUI.SIZE_POLICY_ABSOLUTE, mainLayout.width - treeLayout.width - 2)
    mainLayout:update()
  end

  tree.onItemSelected = function()
    window.activity(true)
    local selected_item = tostring(tree.selectedItem.value)
    infoLabel.text = selected_item

    local mod,item,damage = selected_item:match("([^:]+):([^:]+):([^:]+)")
    local name = mod .. ":".. item
    local stack_item = {name=name, damage=tonumber(damage)}
    local itemStack = storage.getItemsInNetwork(stack_item)[1]
    local total = { size=itemStack.size }
    if total == nil then total={ size=0 } end
    totalLabel.text = "Available: " .. total.size
    itemLabel.text = itemStack.label

    -- Saving settings
    if _G.BaseConfig[infoLabel.text] then
      itemEnabled.switch:setState(true)
      totalCreate.text = _G.BaseConfig[infoLabel.text]["total"]
      itemIdle.switch:setState(_G.BaseConfig[infoLabel.text]["idle"])
      emitRed.switch:setState(_G.BaseConfig[infoLabel.text]["emitRed"])
      if _G.BaseConfig[infoLabel.text]["emitRed"] == true then
        emitFreq.text = _G.BaseConfig[infoLabel.text]["emitFreq"]
        emitFreqOff.text = _G.BaseConfig[infoLabel.text]["emitFreqOff"]
        emitFreq.enabled = true
        emitFreq.hidden = false
        emitFreqOff.enabled = true
        emitFreqOff.hidden = false
        emitRed.switch:setState(true)
      end
    else
      itemEnabled.switch:setState(false)
      totalCreate.text = ""
      itemIdle.switch:setState(false)
      emitRed.switch:setState(false)
      emitFreq.text = ""
      emitFreqOff.text = ""
      emitFreq.hidden = true
      emitFreqOff.hidden = true
    end

    itemEnabled.switch.disabled = false
    if itemEnabled.switch.state == true then

      totalCreate.disabled = false
      itemIdle.switch.disabled = false
      emitRed.switch.disabled = false
      emitFreq.enabled = false
      emitFreqOff.enabled = false
      itemSubmit.disabled = false
    else
      totalCreate.disabled = true
      itemIdle.switch.disabled = true
      emitRed.switch.disabled = true
      emitFreq.enabled = true
      emitFreqOff.enabled = true
      itemSubmit.disabled = true
    end

    window.activity(false)
  end

  itemEnabled.switch.onStateChanged = function(switch)
    if switch.state == true then
      totalCreate.disabled = false
      itemIdle.switch.disabled = false
      itemSubmit.disabled = false
      emitRed.switch.disabled = false
      emitFreq.disabled = false
      emitFreqOff.disabled = false
    else
      totalCreate.disabled = true
      itemIdle.switch.disabled = true
      emitRed.switch.disabled = true
      emitFreq.disabled = true
      emitFreqOff.disabled = true

      -- Disable save button only if the item is not saved yet
      if not _G.BaseConfig[infoLabel.text] then
        itemSubmit.disabled = true
      end
    end
  end

  emitRed.switch.onStateChanged = function(switch)
    if switch.state == true then
      emitFreq.hidden = false
      emitFreq.disabled = false
      emitFreqOff.hidden = false
      emitFreqOff.disabled = false
    else
      emitFreq.hidden = true
      emitFreq.disabled = true
      emitFreqOff.hidden = true
      emitFreqOff.disabled = true
    end
  end

  itemSubmit.onTouch = function()

    if itemEnabled.switch.state then
      _G.BaseConfig[infoLabel.text] = {
        total=totalCreate.text,
        idle=itemIdle.switch.state,
        emitRed=emitRed.switch.state,
        emitFreq=emitFreq.text,
        emitFreqOff=emitFreqOff.text
      }

      log.msg({text="Saved Item " .. infoLabel.text .. " (" ..totalCreate.text .. ")", color = 0x008800})
      filesystem.writeTable(currentScriptDirectory .. "/../config", _G.BaseConfig)
    else
      if _G.BaseConfig[infoLabel.text] then
        log.msg({text="Removed Item " .. infoLabel.text, color = 0x880000})
        _G.BaseConfig[infoLabel.text] = nil
        totalCreate.text = ""
        itemIdle.switch:setState(false)
        filesystem.writeTable(currentScriptDirectory .. "/../config", _G.BaseConfig)
      end
    end
  end

  if _G.outputTimer then
    event.removeHandler(_G.outputTimer)
  end

  _G.outputTimer = event.addHandler(function()
    outputTextBox.lines = {}
    for i = 1, #_G.logData do
      table.insert(outputTextBox.lines, _G.logData[i])
    end
    --_G.logData = {}
    -- Scroll down
    if #outputTextBox.lines > outputTextBox.height then 
      outputTextBox.currentLine = #outputTextBox.lines-outputTextBox.height+1
    end
    --outputTextBox:draw()
  end, 1, math.huge)

  coroutine.resume(loading)
  repeat
    workspace:draw()
  until coroutine.status(loading) == "dead"

  updateTree() 
  window.activity(false)
  workspace:draw()
end

----------------------------------------------------------------------------------------------------------------

return module

