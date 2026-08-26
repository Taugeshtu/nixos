-- mod-version:3
local core = require "core"
local config = require "core.config"
local common = require "core.common"
local style = require "core.style"
local DocView = require "core.docview"

config.plugins.motiontrail = common.merge({
  enabled = true,
  steps = 100,
  trail_frames = 4,
  -- The config specification used by the settings gui
  config_spec = {
    name = "Motion Trail",
    {
      label = "Enabled",
      description = "Disable or enable the caret motion trail effect.",
      path = "enabled",
      type = "toggle",
      default = true
    },
    {
      label = "Steps",
      description = "Amount of trail steps to generate on caret movement.",
      path = "steps",
      type = "number",
      default = 50,
      min = 10,
      max = 100
    },
    {
      label = "Trail Frames",
      description = "How many frames each trail segment lingers. Higher values leave more simultaneous ghost trails.",
      path = "trail_frames",
      type = "number",
      default = 1,
      min = 1,
      max = 20
    },
  }
}, config.plugins.motiontrail)

local cc_installed = pcall(require, 'plugins.custom_caret')
local cc_conf = config.plugins.custom_caret

local function get_caret_size(dv, i)
  local line, col = dv.doc:get_selection_idx(i)
  local chw = dv:get_font():get_width(dv.doc:get_char(line, col))
  local w = style.caret_width
  local h = dv:get_line_height()

  if cc_installed then
    local cc_shape = cc_conf.shape
    if cc_shape == "underline" or dv.doc.overwrite then
      w = chw
      h = style.caret_width * 2
    elseif cc_shape ==  "block" then
      w = chw
    end
  end

  return w, h
end

local caret_idx, caret_amt = 1, 0

local dv_update = DocView.update
function DocView:update()
  self.last_pos = self.last_pos or {}
  self.last_view = self.last_view or {}
  self.last_doc_pos = self.last_doc_pos or {}
  self.trail_segments = self.trail_segments or {}
  caret_idx = caret_idx or 1
  self.draws = 0  -- reset so blink-off frames don't accumulate and suppress the trail

  -- Clean up state for carets that no longer exist
  caret_amt = caret_amt and math.max(caret_amt, caret_idx) or 0
  for ri = caret_idx, caret_amt - 1 do
    self.last_pos[ri] = nil
    self.last_view[ri] = nil
    self.last_doc_pos[ri] = nil
    self.trail_segments[ri] = nil
  end
  caret_amt = caret_idx
  caret_idx = 1
  dv_update(self)
end

local dv_draw = DocView.draw
function DocView:draw()
  self.draws = self.draws and self.draws + 1 or 1
  return dv_draw(self)
end

local dv_draw_caret = DocView.draw_caret
function DocView:draw_caret(x, y)
  if not config.plugins.motiontrail.enabled or self ~= core.active_view then
    dv_draw_caret(self, x, y)
    return
  end

  self.last_pos[caret_idx] = self.last_pos[caret_idx] or {}
  self.last_doc_pos[caret_idx] = self.last_doc_pos[caret_idx] or {}
  self.trail_segments[caret_idx] = self.trail_segments[caret_idx] or {}
  local line, col = self.doc:get_selection_idx(caret_idx)

  if (self.draws or 0) <= 1 then
    local lsx, lsy = self.last_pos[caret_idx][1] or x, self.last_pos[caret_idx][2] or y
    local lsl, lsc = self.last_doc_pos[caret_idx][1], self.last_doc_pos[caret_idx][2]
    local w, h = get_caret_size(self, caret_idx)

    -- On cursor move, push a new segment
    if (lsl ~= line or lsc ~= col) and self.last_view[caret_idx] == self then
      table.insert(self.trail_segments[caret_idx], {
        x1 = lsx, y1 = lsy, x2 = x, y2 = y,
        frames = config.plugins.motiontrail.trail_frames
      })
    end

    -- Draw all active segments, fading by remaining lifetime
    local base_color = (cc_installed and cc_conf.custom_color) and cc_conf.caret_color or style.caret
    local trail_frames = config.plugins.motiontrail.trail_frames
    local segments = self.trail_segments[caret_idx]
    local i = 1
    while i <= #segments do
      local seg = segments[i]
      local alpha = math.floor((base_color[4] or 255) * seg.frames / trail_frames)
      local color = { base_color[1], base_color[2], base_color[3], alpha }

      local lx = seg.x2
      for t = 0, 1, 1 / config.plugins.motiontrail.steps do
        local ix = common.lerp(seg.x2, seg.x1, t)
        local iy = common.lerp(seg.y2, seg.y1, t)
        if cc_installed and cc_conf.shape == "underline" or self.doc.overwrite then
          iy = iy + self:get_line_height()
        end
        local iw = math.max(w, math.ceil(math.abs(ix - lx)))
        renderer.draw_rect(ix, iy, iw, h, color)
        lx = ix
      end

      seg.frames = seg.frames - 1
      if seg.frames <= 0 then
        table.remove(segments, i)
      else
        i = i + 1
      end
    end

    if #segments > 0 then core.redraw = true end
  end

  self.last_pos[caret_idx][1], self.last_pos[caret_idx][2], self.last_view[caret_idx] = x, y, self
  self.last_doc_pos[caret_idx][1], self.last_doc_pos[caret_idx][2] = line, col
  caret_idx = caret_idx + 1
  self.draws = 0
  dv_draw_caret(self, x, y)
end
