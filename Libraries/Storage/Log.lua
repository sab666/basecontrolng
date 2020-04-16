local log = {}
local colors = {
  darkred=0x880000,
  green=0x008800,
  orange=0xFF9900,
  blue=0x45B6FE
}

function log.msg(msg)
  -- crude way to limit memory usage
  if _G.logData == nil then
    _G.logData = {}
  end
  if #_G.logData > 50 then
    _G.logData = {}
  end
  table.insert(_G.logData, msg)
end

function log.info(msg)
  log.msg({text=msg, color=colors['green']})
end

function log.warning(msg)
  log.msg({text=msg, color=colors['orange']})
end

function log.error(msg)
  log.msg({text=msg, color=colors['darkred']})
end

function log.debug(msg)
  log.msg({text=msg, color=colors['blue']})
end

return log
