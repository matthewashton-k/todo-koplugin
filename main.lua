local UiManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local CheckButton = require("ui/widget/checkbutton")
local FrameContainer = require("ui/widget/container/framecontainer")
local ScrollableContainer = require("ui/widget/container/scrollablecontainer")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local VerticalGroup = require("ui/widget/verticalgroup")
local TextWidget = require("ui/widget/textwidget")
local Button = require("ui/widget/button")
local Screen = require("device").screen
local Font = require("ui/font")
local Blitbuffer = require("ffi/blitbuffer")
local Geom = require("ui/geometry")
local Size = require("ui/size")
local logger = require("logger")
local _ = require("gettext")

local TodoApplication = WidgetContainer:extend({
    name = "todo",
    todos = {}, -- Data store for todo items
})

function TodoApplication:init()
    self.ui.menu:registerToMainMenu(self)
    self:loadSaved()
end

function TodoApplication:loadSaved()
    -- TODO: Implement file loading
    self.todos = {
        { text = "Sample Todo", checked = false },
        { text = "Sample Todo2", checked = false }
    }
end

function TodoApplication:saveTodos()
    logger.warn("saved todo")
    -- TODO: Implement file saving
end

function TodoApplication:createTodoItem(todo, index)
    local check_button = CheckButton:new{
        checked = todo.checked,
        callback = function()
            self.todos[index].checked = not self.todos[index].checked
            self:saveTodos()
        end,
        width = Screen:scaleBySize(30),
    }
    
    local text_widget = TextWidget:new{
        text = todo.text,
        face = Font:getFace("smallinfofont"),
    }
    
    return HorizontalGroup:new{
        check_button,
        HorizontalSpan:new{ width = Screen:scaleBySize(10 )},
        text_widget,
    }
end

function TodoApplication:showItems()
    local screen_width = Screen:getWidth()
    local screen_height = Screen:getHeight()
    local todo_list = VerticalGroup:new{
        align = "left",
        id = "todo_list",
    }

    for index, todo in ipairs(self.todos) do
        table.insert(todo_list, self:createTodoItem(todo, index))
    end

    -- Main container with background
    local frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        -- radius = Size.radius.window,
        bordersize = 0,
        padding = Screen:scaleBySize(10),
        dimen = Screen:getSize(),
        VerticalGroup:new{
            align = "left",
            Button:new{
                text = _("Add Todo"),
                callback = function()
                    -- TODO: Implement add functionality
                    logger.warn("new todo")
                end,
            },
            ScrollableContainer:new{
                dimen = Geom:new{
                    w = screen_width,
                    h = screen_height - Screen:scaleBySize(50)
                },
                todo_list
            },
        }
    }

    UiManager:show(frame)
end

function TodoApplication:addToMainMenu(menu_items)
    menu_items.todo = {
        text = _("Todo App"),
        callback = function()
            self:showItems()
        end
    }
end

return TodoApplication