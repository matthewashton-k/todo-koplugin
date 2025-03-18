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
    todos = {},
    current_frame = nil,
})

function TodoApplication:init()
    self.ui.menu:registerToMainMenu(self)
    self:loadSaved()
end

function TodoApplication:loadSaved()
    self.todos = {
        { text = "Sample Todo", checked = false },
        { text = "Sample Todo2", checked = false }
    }
    logger.warn("Loaded todos: " .. #self.todos .. " items")
end

function TodoApplication:saveTodos()
    logger.warn("Saving todos (total: " .. #self.todos .. ")")
end

function TodoApplication:createTodoItem(todo, index)
    logger.warn("Creating todo item #" .. index .. " with checked=" .. tostring(todo.checked))
    local check_button = CheckButton:new{
        checked = todo.checked,
        callback = function()
            logger.warn("Checkbox clicked for item #" .. index)
            self.todos[index].checked = not self.todos[index].checked
            logger.warn("New checked state for #" .. index .. ": " .. tostring(self.todos[index].checked))
            self:saveTodos()
            self:refreshUI() -- Refresh UI after state change
        end,
        width = Screen:scaleBySize(30),
    }

    local text_widget = TextWidget:new{
        text = todo.text,
        face = Font:getFace("smallinfofont"),
    }

    return HorizontalGroup:new{
        check_button,
        HorizontalSpan:new{ width = Screen:scaleBySize(10) },
        text_widget,
    }
end

function TodoApplication:refreshUI()
    if self.current_frame then
        UiManager:close(self.current_frame)
        self.current_frame = nil
    end
    self:showItems()
end

function TodoApplication:showItems()
    logger.warn("Showing todo list UI")
    local screen_width = Screen:getWidth()
    local screen_height = Screen:getHeight()
    if self.current_frame then
        UiManager:close(self.current_frame)
    end

    local todo_list = VerticalGroup:new{
        align = "left",
        id = "todo_list",
    }
    for index, todo in ipairs(self.todos) do
        table.insert(todo_list, self:createTodoItem(todo, index))
    end

    self.current_frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = Screen:scaleBySize(10),
        dimen = Screen:getSize(),
        VerticalGroup:new{
            align = "left",
            Button:new{
                text = _("Add Todo"),
                callback = function()
                    logger.warn("Add Todo button clicked")
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

    UiManager:show(self.current_frame)
    logger.warn("UI refresh completed")
end

function TodoApplication:addToMainMenu(menu_items)
    menu_items.todo = {
        text = _("Todo App"),
        callback = function()
            logger.warn("Todo menu item clicked")
            self:showItems()
        end
    }
end

return TodoApplication