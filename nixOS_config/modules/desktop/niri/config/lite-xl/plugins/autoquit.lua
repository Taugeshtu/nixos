-- mod-version:3
-- Automatically quit when the last document is closed.
local core = require "core"
local Doc  = require "core.doc"

local on_close = Doc.on_close
Doc.on_close = function(self)
  on_close(self)
  if #core.docs == 0 then
    core.quit(true)  -- force: unsaved-change checks already happened before the close
  end
end
