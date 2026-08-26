-- put user settings here
-- this module will be loaded after everything else when the application starts
-- it will be automatically reloaded when saved

local core = require "core"
local keymap = require "core.keymap"
local config = require "core.config"
local style = require "core.style"

------------------------------ Themes ----------------------------------------

-- light theme:
core.reload_module( "colors.summer" )

--------------------------- Key bindings -------------------------------------

-- key binding:
-- keymap.add { ["ctrl+escape"] = "core:quit" }

-- pass 'true' for second parameter to overwrite an existing binding
-- keymap.add({ ["ctrl+pageup"] = "root:switch-to-previous-tab" }, true)
-- keymap.add({ ["ctrl+pagedown"] = "root:switch-to-next-tab" }, true)
keymap.add({ ["f1"] = "core:find-command" }, true)
keymap.add({ ["f4"] = "find-replace:repeat-find" }, true)
keymap.add({ ["f3"] = "find-replace:previous-find" }, true)
keymap.add({ ["alt+up"] = "doc:create-cursor-previous-line" }, true)
keymap.add({ ["alt+down"] = "doc:create-cursor-next-line" }, true)

------------------------------- Fonts ----------------------------------------

-- customize fonts:
style.font = renderer.font.load(DATADIR .. "/fonts/FiraSans-Regular.ttf", 24 * SCALE, {antialiasing="grayscale"})
style.code_font = renderer.font.load(DATADIR .. "/fonts/JetBrainsMono-Regular.ttf", 24 * SCALE, {antialiasing="grayscale"})
--
-- DATADIR is the location of the installed Lite XL Lua code, default color
-- schemes and fonts.
-- USERDIR is the location of the Lite XL configuration directory.
--
-- font names used by lite:
-- style.font          : user interface
-- style.big_font      : big text in welcome screen
-- style.icon_font     : icons
-- style.icon_big_font : toolbar icons
-- style.code_font     : code
--
-- the function to load the font accept a 3rd optional argument like:
--
-- {antialiasing="grayscale", hinting="full", bold=true, italic=true, underline=true, smoothing=true, strikethrough=true}
--
-- possible values are:
-- antialiasing: grayscale, subpixel
-- hinting: none, slight, full
-- bold: true, false
-- italic: true, false
-- underline: true, false
-- smoothing: true, false
-- strikethrough: true, false

------------------------------ Plugins ----------------------------------------

-- disable plugin loading setting config entries:

-- disable plugin detectindent, otherwise it is enabled by default:
-- config.plugins.detectindent = false

---------------------------- Miscellaneous -------------------------------------

-- modify list of files to ignore when indexing the project:
-- config.ignore_files = {
--   -- folders
--   "^%.svn/",        "^%.git/",   "^%.hg/",        "^CVS/", "^%.Trash/", "^%.Trash%-.*/",
--   "^node_modules/", "^%.cache/", "^__pycache__/",
--   -- files
--   "%.pyc$",         "%.pyo$",       "%.exe$",        "%.dll$",   "%.obj$", "%.o$",
--   "%.a$",           "%.lib$",       "%.so$",         "%.dylib$", "%.ncb$", "%.sdf$",
--   "%.suo$",         "%.pdb$",       "%.idb$",        "%.class$", "%.psd$", "%.db$",
--   "^desktop%.ini$", "^%.DS_Store$", "^%.directory$",
-- }

--------------------------- Project scanning suppression --------------------

-- Lite XL scans the project directory on startup. We don't want that.
-- Setting max_project_files to a tiny number stops it cold.
config.max_project_files = 30

-- Word wrap for prose: see plugins/prose_wrap.lua


--------------------------- Caret --------------------
config.blink_period = 0.2
