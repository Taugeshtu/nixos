-- mod-version:3
-- Forked from system treeview.lua.
-- Stripped to: hidden by default, empty item list (no directory scanning from UI side),
-- commands preserved so nothing crashes. Will be repurposed for wikilink navigation later.
-- Project root auto-detection: walks up from cwd (or first opened file) looking for .git.

local core = require "core"
local common = require "core.common"
local command = require "core.command"
local config = require "core.config"
local keymap = require "core.keymap"
local style = require "core.style"
local View = require "core.view"
local ContextMenu = require "core.contextmenu"
local RootView = require "core.rootview"
local CommandView = require "core.commandview"

config.plugins.treeview = common.merge({
  size = 200 * SCALE
}, config.plugins.treeview)


local TreeView = View:extend()

function TreeView:__tostring() return "TreeView" end

function TreeView:new()
  TreeView.super.new(self)
  self.scrollable = true
  self.visible = false   -- hidden by default
  self.init_size = true
  self.target_size = config.plugins.treeview.size
  self.selected_item = nil
  self.hovered_item = nil
end

function TreeView:set_target_size(axis, value)
  if axis == "x" then
    self.target_size = value
    return true
  end
end

function TreeView:get_name() return nil end

function TreeView:get_item_height()
  return style.font:get_height() + style.padding.y
end

-- Empty iterator — no files, no scanning, no cache.
function TreeView:each_item()
  return coroutine.wrap(function() end)
end

function TreeView:set_selection(selection)
  self.selected_item = selection
end

function TreeView:update()
  local dest = self.visible and self.target_size or 0
  if self.init_size then
    self.size.x = dest
    self.init_size = false
  else
    self:move_towards(self.size, "x", dest, nil, "treeview")
  end
  TreeView.super.update(self)
end

function TreeView:get_scrollable_size()
  return 0
end

function TreeView:draw()
  if not self.visible then return end
  self:draw_background(style.background2)
  if self.project_root then
    local name = common.basename(self.project_root)
    local x = self.position.x + style.padding.x
    local y = self.position.y + style.padding.y
    renderer.draw_text(style.font, name, x, y, style.accent)
  end
end


-- Walk up from start_path until we find a directory containing .git.
-- Returns that directory, or nil if we hit the filesystem root without finding one.
local function find_project_root(start_path)
  local path = start_path
  while true do
    if system.get_file_info(path .. PATHSEP .. ".git") then
      return path
    end
    local parent = common.dirname(path)
    if not parent or parent == path then return nil end   -- filesystem root, give up
    path = parent
  end
end

-- init: create the split (zero-width since visible=false)
local view = TreeView()
local node = core.root_view:get_active_node()
view.node = node:split("left", view, {x = true}, true)

-- Try to resolve a project root from any available path hints.
-- Returns the root path on success, nil otherwise.
local function try_resolve_root()
  local candidates = {}
  if core.project_dir then candidates[#candidates+1] = core.project_dir end
  for _, doc in ipairs(core.docs or {}) do
    if doc.abs_filename then
      candidates[#candidates+1] = common.dirname(doc.abs_filename)
    end
  end
  for _, path in ipairs(candidates) do
    local found = find_project_root(path)
    if found then return found end
  end
  return nil
end

-- Attempt 1: right now (plugins load before docs are opened, so this may miss).
view.project_root = try_resolve_root()

-- Attempt 2: after startup settles — docs will be open by then.
core.add_thread(function()
  if not view.project_root then
    view.project_root = try_resolve_root()
  end
  if view.project_root then
    core.log("treeview: project root → %s", view.project_root)
  else
    core.log("treeview: no .git found, project root unset")
  end
end)

-- Attempt 3: hook future doc opens (e.g. user opens a new file mid-session).
local orig_open_doc = core.open_doc
function core.open_doc(filename, ...)
  local result = orig_open_doc(filename, ...)
  if not view.project_root and filename then
    local dir = common.dirname(filename)
    if dir then
      view.project_root = find_project_root(dir)
    end
  end
  return result
end

-- Context menu (stub — no items)
local menu = ContextMenu()

local on_view_mouse_pressed = RootView.on_view_mouse_pressed
local on_mouse_moved = RootView.on_mouse_moved
local root_view_update = RootView.update
local root_view_draw = RootView.draw

function RootView:on_mouse_moved(...)
  if menu:on_mouse_moved(...) then return end
  on_mouse_moved(self, ...)
end

function RootView.on_view_mouse_pressed(button, x, y, clicks)
  local handled = menu:on_mouse_pressed(button, x, y, clicks)
  return handled or on_view_mouse_pressed(button, x, y, clicks)
end

function RootView:update(...)
  root_view_update(self, ...)
  menu:update()
end

function RootView:draw(...)
  root_view_draw(self, ...)
  menu:draw()
end

local previous_view = nil

command.add(nil, {
  ["treeview:toggle"] = function()
    view.visible = not view.visible
  end,

  ["treeview:toggle-focus"] = function()
    if not core.active_view:is(TreeView) then
      if core.active_view:is(CommandView) then
        previous_view = core.last_active_view
      else
        previous_view = core.active_view
      end
      core.set_active_view(view)
    else
      core.set_active_view(
        previous_view or core.root_view:get_primary_node().active_view
      )
    end
  end,
})

-- Stub remaining commands so existing keybindings don't error
command.add(function() return core.active_view:extends(TreeView) end, {
  ["treeview:next"]     = function() end,
  ["treeview:previous"] = function() end,
  ["treeview:open"]     = function() end,
  ["treeview:deselect"] = function() end,
  ["treeview:select"]   = function() end,
  ["treeview:select-and-open"] = function() end,
  ["treeview:collapse"] = function() end,
  ["treeview:expand"]   = function() end,
  ["treeview:delete"]   = function() end,
  ["treeview:rename"]   = function() end,
  ["treeview:new-file"] = function() end,
  ["treeview:new-folder"] = function() end,
  ["treeview:open-in-system"] = function() end,
})

keymap.add {
  ["ctrl+\\"] = "treeview:toggle",
}

view.contextmenu = menu
return view
