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
local DataStorage = require("datastorage")
local LuaSettings = require("luasettings")
local IconButton = require("ui/widget/iconbutton")

local TodoApplication = WidgetContainer:extend({
    name = "todo",
    todos = {},
    current_frame = nil,
    settings_file = DataStorage:getSettingsDir() .. "/todos.lua",
})

function TodoApplication:init()
    self.ui.menu:registerToMainMenu(self)
    self:loadSaved()
end

function TodoApplication:addExitButton()
    local star_width = Screen:scaleBySize(25)
    local ellipsis_button_width = Screen:scaleBySize(34)
    return IconButton:new{
        icon = "exit",
        width = star_width,
        height = star_width,
        padding = math.floor((ellipsis_button_width - star_width)/2) + Size.padding.button,
        callback = function()
            self:loadSaved()
            self:remover()
        end,
    }
end

function TodoApplication:remover()
    self.current_frame:free()
    UiManager:close(self.current_frame)
    UiManager:setDirty(nil, "full")
end


function TodoApplication:loadSaved()
    logger.warn("Loading todos from settings")
    local settings = LuaSettings:open(self.settings_file)
    local saved_todos = settings:readSetting("todos")

    if saved_todos and #saved_todos > 0 then
        self.todos = saved_todos
    else
        self.todos = {
            { text = "Sample Todo", checked = false },
        }
    end
end

function TodoApplication:saveTodos()
    local settings = LuaSettings:open(self.settings_file)
    settings:saveSetting("todos", self.todos)
    settings:flush()
end

function TodoApplication:createTodoItem(todo, index)
    local check_button = CheckButton:new{
        checked = todo.checked,
        callback = function()
            self.todos[index].checked = not self.todos[index].checked
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
        self:free()
        self.current_frame:free()
        UiManager:close(self)
        UiManager:close(self.current_frame)
        self.current_frame = nil
    end
    self:showItems()
end

function TodoApplication:showItems()
    local margin_span = HorizontalSpan:new{ width = Size.padding.large }
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
        table.insert(todo_list, 1, self:createTodoItem(todo, index))
    end

    -- Add delete button
    local remove_completed_button = Button:new{
        text = _("Remove completed"),
        callback = function()
            local new_todos = {}
            for _, todo in ipairs(self.todos) do
                if not todo.checked then
                    table.insert(new_todos, todo)
                end
            end
            self.todos = new_todos
            self:saveTodos()
            self:refreshUI()
        end,
    }

    self.current_frame = FrameContainer:new{
        background = Blitbuffer.COLOR_WHITE,
        bordersize = 0,
        padding = Screen:scaleBySize(10),
        dimen = Screen:getSize(),
        VerticalGroup:new{
            -- align = "left",
            HorizontalGroup:new{
                margin_span,
                Button:new{
                    text = _("Add Todo"),
                    callback = function()
                        local InputDialog = require("ui/widget/inputdialog")
                        local input_dialog
                        input_dialog = InputDialog:new{
                            title = _("New Todo"),
                            input = "",
                            input_hint = _("Enter todo text"),
                            description = _("Please enter the todo item text."),
                            buttons = {
                                {
                                    {
                                        text = _("Cancel"),
                                        id = "close",
                                        callback = function()
                                            UiManager:close(input_dialog)
                                        end,
                                    },
                                    {
                                        text = _("Save"),
                                        is_enter_default = true,
                                        callback = function()
                                            local new_text = input_dialog:getInputText()
                                            if new_text and new_text ~= "" then
                                                table.insert(self.todos, { text = new_text, checked = false })
                                                self:saveTodos()
                                                self:refreshUI()
                                            else
                                                logger.warn("Empty todo not added.")
                                            end
                                            UiManager:close(input_dialog)
                                        end,
                                    },
                                }
                            },
                        }
                        UiManager:show(input_dialog)
                        input_dialog:onShowKeyboard()
                    end,
                },
                margin_span,
                remove_completed_button,
                margin_span,
                self:addExitButton(),
                margin_span
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
    UiManager:setDirty(todo_list, "ui");
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
