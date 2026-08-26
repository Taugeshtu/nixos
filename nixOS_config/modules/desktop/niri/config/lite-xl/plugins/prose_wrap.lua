-- mod-version:3
-- Automatically enables soft word-wrap for prose file types.
-- Relies on the built-in linewrapping plugin.

local core    = require "core"
local config  = require "core.config"
local DocView = require "core.docview"
local LineWrapping = require "plugins.linewrapping"

config.plugins.linewrapping.mode   = "word"
config.plugins.linewrapping.guide  = false
config.plugins.linewrapping.indent = false

local prose_extensions = { md=true, txt=true, markdown=true, rst=true, org=true }

local _dv_new = DocView.new
function DocView:new(doc)
  _dv_new(self, doc)
  if doc and doc.filename then
    local ext = doc.filename:match("%.([^%.]+)$") or ""
    if prose_extensions[ext:lower()] then
      local view = self
      core.add_thread(function()
        view.wrapping_enabled = true
        LineWrapping.update_docview_breaks(view)
      end)
    end
  end
end
