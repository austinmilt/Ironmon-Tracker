SetupScreen = {
	Colors = {
		text = "Lower box text",
		highlight = "Intermediate text",
		border = "Lower box border",
		boxFill = "Lower box background",
	},
	Tabs = {
		General = {
			index = 1,
			tabKey = "General",
			resourceKey = "TabGeneral",
		},
		Carousel = {
			index = 2,
			tabKey = "Carousel",
			resourceKey = "TabCarousel",
		},
	},
	currentTab = 1,
	changeIconInSeconds = 3, -- Number of seconds
}
local SCREEN = SetupScreen
local TAB_HEIGHT = 12

SCREEN.Buttons = {
	ChoosePortrait = {
		type = Constants.ButtonTypes.NO_BORDER,
		getText = function(self)
			local iconset = Options.getIconSet()
			return string.format("%s:  %s", Resources.SetupScreen.PokemonIconSetLabel, iconset.name)
		end,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 2, Constants.SCREEN.MARGIN + 24, 65, 11 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
	},
	PortraitAuthor = {
		type = Constants.ButtonTypes.NO_BORDER,
		getText = function(self)
			local iconset = Options.getIconSet()
			return string.format("%s:  %s", Resources.SetupScreen.PokemonIconSetAuthor, iconset.author)
		end,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 2, Constants.SCREEN.MARGIN + 34, 65, 11 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
	},
	PokemonIcon = {
		type = Constants.ButtonTypes.POKEMON_ICON,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 52, Constants.SCREEN.MARGIN + 39, 32, 32 },
		pokemonID = 1,
		getIconId = function(self)
			local animType = Options["Allow sprites to walk"] and SpriteData.Types.Walk or SpriteData.Types.Idle
			return self.pokemonID, animType
		end,
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
		randomize = function(self)
			self.pokemonID = Utils.randomPokemonID()
			self.timeLastChanged = os.time()
		end,
		onClick = function(self)
			self:randomize()
			Program.redraw(true)
		end
	},
	CycleIconForward = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.RIGHT_ARROW,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 94, Constants.SCREEN.MARGIN + 54, 10, 10, },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
		onClick = function(self)
			local currIndex = tonumber(Options["Pokemon icon set"]) or 1
			local nextSet = tostring((currIndex % #Options.IconSetMap) + 1)
			SCREEN.Buttons.PokemonIcon.timeLastChanged = os.time()
			Options.addUpdateSetting("Pokemon icon set", nextSet)
			if Options.getIconSet().isAnimated then
				SpriteData.changeIconSet(nextSet)
			end
			Program.redraw(true)
		end
	},
	CycleIconBackward = {
		type = Constants.ButtonTypes.PIXELIMAGE,
		image = Constants.PixelImages.LEFT_ARROW,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 34, Constants.SCREEN.MARGIN + 54, 10, 10, },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
		onClick = function(self)
			local currIndex = tonumber(Options["Pokemon icon set"]) or 1
			local prevSet = tostring((currIndex - 2 ) % #Options.IconSetMap + 1)
			SCREEN.Buttons.PokemonIcon.timeLastChanged = os.time()
			Options.addUpdateSetting("Pokemon icon set", prevSet)
			if Options.getIconSet().isAnimated then
				SpriteData.changeIconSet(prevSet)
			end

			Program.redraw(true)
		end
	},
	OptionAllowSpritesToWalk = {
		type = Constants.ButtonTypes.CHECKBOX,
		optionKey = "Allow sprites to walk",
		getText = function(self) return Resources.SetupScreen.OptionAllowSpritesToWalk end,
		clickableArea = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4, Constants.SCREEN.MARGIN + 67, 33, 8 },
		box = {	Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4, Constants.SCREEN.MARGIN + 67, 8, 8 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General and Options.getIconSet().isAnimated end,
		toggleState = true,
		updateSelf = function(self) self.toggleState = (Options[self.optionKey] == true) end,
		onClick = function(self)
			self.toggleState = Options.toggleSetting(self.optionKey)
			SCREEN.Buttons.PokemonIcon.timeLastChanged = os.time()
			if not Options[self.optionKey] then
				SpriteData.changeAllActiveIcons(SpriteData.DefaultType)
			end
			Program.redraw(true)
		end
	},
	EnableCarousel = {
		type = Constants.ButtonTypes.CHECKBOX,
		optionKey = "Allow carousel rotation",
		getText = function(self) return " " .. Resources.SetupScreen.OptionAllowCarouselRotation end,
		clickableArea = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4, Constants.SCREEN.MARGIN + 26, Constants.SCREEN.RIGHT_GAP - 12, 8 },
		box = {	Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4, Constants.SCREEN.MARGIN + 26, 8, 8 },
		toggleState = true,
		updateSelf = function(self) self.toggleState = (Options[self.optionKey] == true) end,
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.Carousel end,
		onClick = function(self)
			self.toggleState = Options.toggleSetting(self.optionKey)
			Program.redraw(true)
		end
	},
	EditControls = {
		type = Constants.ButtonTypes.FULL_BORDER,
		getText = function(self) return Resources.SetupScreen.ButtonEditControls end,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4, Constants.SCREEN.MARGIN + 135, 38, 11 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
		onClick = function() SCREEN.openEditControlsWindow() end
	},
	ManageData = {
		type = Constants.ButtonTypes.FULL_BORDER,
		getText = function(self) return Resources.SetupScreen.ButtonManageData end,
		box = { Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 47, Constants.SCREEN.MARGIN + 135, 60, 11 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
		onClick = function() Program.changeScreenView(TrackedDataScreen) end
	},
	Back = Drawing.createUIElementBackButton(function()
		SCREEN.currentTab = SCREEN.Tabs.General
		Program.changeScreenView(NavigationMenu)
	end),
}

function SetupScreen.initialize()
	SCREEN.currentTab = SCREEN.Tabs.General
	SCREEN.createTabs()
	SCREEN.createButtons()

	for _, button in pairs(SCREEN.Buttons) do
		if button.textColor == nil then
			button.textColor = SCREEN.Colors.text
		end
		if button.boxColors == nil then
			button.boxColors = { SCREEN.Colors.border, SCREEN.Colors.boxFill }
		end
	end

	SCREEN.Buttons.PokemonIcon:randomize()

	local abraGif = FileManager.buildImagePath(FileManager.Folders.AnimatedPokemon, "abra", FileManager.Extensions.ANIMATED_POKEMON)
	local animatedBtnOption = SCREEN.Buttons["Animated Pokemon popout"]
	if not FileManager.fileExists(abraGif) and animatedBtnOption ~= nil then
		animatedBtnOption.disabled = true
	end
end

function SetupScreen.refreshButtons()
	for _, button in pairs(SCREEN.Buttons) do
		if button.updateSelf ~= nil then
			button:updateSelf()
		end
	end
end

function SetupScreen.createTabs()
	local startX = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN
	local startY = Constants.SCREEN.MARGIN + 10
	local tabPadding = 6

	for _, tab in ipairs(Utils.getSortedList(SCREEN.Tabs)) do
		local tabText = Resources.SetupScreen[tab.resourceKey]
		local tabWidth = (tabPadding * 2) + Utils.calcWordPixelLength(tabText)
		SCREEN.Buttons["Tab" .. tab.tabKey] = {
			type = Constants.ButtonTypes.NO_BORDER,
			getText = function(self) return tabText end,
			tab = SCREEN.Tabs[tab.tabKey],
			isSelected = false,
			box = {	startX, startY, tabWidth, TAB_HEIGHT },
			updateSelf = function(self)
				self.isSelected = (self.tab == SCREEN.currentTab)
				self.textColor = self.isSelected and SCREEN.Colors.highlight or SCREEN.Colors.text
			end,
			draw = function(self, shadowcolor)
				local x, y = self.box[1], self.box[2]
				local w, h = self.box[3], self.box[4]
				local color = Theme.COLORS[self.boxColors[1]]
				local bgColor = Theme.COLORS[self.boxColors[2]]
				gui.drawRectangle(x + 1, y + 1, w - 1, h - 2, bgColor, bgColor) -- Box fill
				if not self.isSelected then
					gui.drawRectangle(x + 1, y + 1, w - 1, h - 2, Drawing.ColorEffects.DARKEN, Drawing.ColorEffects.DARKEN)
				end
				gui.drawLine(x + 1, y, x + w - 1, y, color) -- Top edge
				gui.drawLine(x, y + 1, x, y + h - 1, color) -- Left edge
				gui.drawLine(x + w, y + 1, x + w, y + h - 1, color) -- Right edge
				if self.isSelected then
					gui.drawLine(x + 1, y + h, x + w - 1, y + h, bgColor) -- Remove bottom edge
				end
				local centeredOffsetX = Utils.getCenteredTextX(self:getText(), w) - 2
				Drawing.drawText(x + centeredOffsetX, y, self:getText(), Theme.COLORS[self.textColor], shadowcolor)
			end,
			onClick = function(self)
				SCREEN.currentTab = self.tab
				SCREEN.refreshButtons()
				Program.redraw(true)
			end,
		}
		startX = startX + tabWidth
	end
end

function SetupScreen.createButtons()
	-- TAB: GENERAL
	local startX = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4
	local startY = Constants.SCREEN.MARGIN + 78

	local optionKeyMap = {
		{"Show Team View", "OptionShowTeamView", },
		{"Right justified numbers", "OptionRightJustifiedNumbers", },
		{"Show nicknames", "OptionShowNicknames", },
		{"Track PC Heals", "OptionTrackPCHeals", },
		{"PC heals count downward", "OptionPCHealsCountDown", },
	}

	for _, optionTuple in ipairs(optionKeyMap) do
		SCREEN.Buttons[optionTuple[1]] = {
			type = Constants.ButtonTypes.CHECKBOX,
			optionKey = optionTuple[1],
			getText = function(self) return Resources.SetupScreen[optionTuple[2]] end,
			clickableArea = { startX, startY, Constants.SCREEN.RIGHT_GAP - 12, 8 },
			box = {	startX, startY, 8, 8 },
			toggleState = Options[optionTuple[1]],
			updateSelf = function(self) self.toggleState = (Options[self.optionKey] == true) end,
			isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.General end,
			onClick = function(self)
				self.toggleState = Options.toggleSetting(self.optionKey)
				-- If PC Heal tracking switched, invert the count
				if self.optionKey == "PC heals count downward" then
					Tracker.Data.centerHeals = math.max(10 - Tracker.Data.centerHeals, 0)
				end
				Program.redraw(true)
				if self.optionKey == "Show Team View" then
					TeamViewArea.refreshDisplayPadding()
					TeamViewArea.buildOutPartyScreen()
					Program.Frames.waitToDraw = 1 -- required to redraw after the redraw
				end
			end
		}
		startY = startY + Constants.SCREEN.LINESPACING
	end

	-- TAB: CAROUSEL
	startX = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN + 4
	startY = Constants.SCREEN.MARGIN + 40

	local headerText = string.format("%s:", Resources.SetupScreen.LabelInfoToShow)
	SCREEN.Buttons.CarouselInfoHeader = {
		type = Constants.ButtonTypes.NO_BORDER,
		getText = function(self) return headerText end,
		box = {	startX - 2, startY, Utils.calcWordPixelLength(headerText) + 5, 11 },
		isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.Carousel end,
		draw = function(self, shadowcolor) Drawing.drawUnderline(self) end,
	}
	startY = startY + Constants.SCREEN.LINESPACING + 4

	local carouselKeyMap = {
		{"Badges", "CarouselBadges", },
		{"Notes", "CarouselNotes", },
		{"RouteInfo", "CarouselRouteInfo", },
		{"Trainers", "CarouselTrainers", },
		{"LastAttack", "CarouselLastAttack", },
		{"Pedometer", "CarouselPedometer", },
	}

	local function saveCarouselSettings()
		local carouselItems = {}
		for _, tuple in ipairs(carouselKeyMap) do
			if SCREEN.Buttons["Carousel" .. tuple[1]].toggleState then
				table.insert(carouselItems, tuple[1])
			end
		end
		Options["CarouselItems"] = table.concat(carouselItems, ",")
		Main.SaveSettings(true)
	end

	for _, tuple in ipairs(carouselKeyMap) do
		SCREEN.Buttons["Carousel" .. tuple[1]] = {
			type = Constants.ButtonTypes.CHECKBOX,
			optionKey = tuple[1],
			getText = function(self) return " " .. Resources.SetupScreen[tuple[2]] end,
			clickableArea = { startX, startY, Constants.SCREEN.RIGHT_GAP - 12, 8 },
			box = {	startX, startY, 8, 8 },
			toggleState = Utils.containsText(Options["CarouselItems"], tuple[1]),
			updateSelf = function(self)
				self.toggleState = Utils.containsText(Options["CarouselItems"], tuple[1])
			end,
			isVisible = function(self) return SCREEN.currentTab == SCREEN.Tabs.Carousel end,
			onClick = function(self)
				self.toggleState = not self.toggleState
				saveCarouselSettings()
				Program.redraw(true)
			end
		}
		startY = startY + Constants.SCREEN.LINESPACING
	end
end

function SetupScreen.openEditControlsWindow()
	local form = Utils.createBizhawkForm(Resources.SetupScreen.PromptEditControllerTitle, 445, 215)

	forms.label(form, Resources.SetupScreen.PromptEditControllerDesc, 39, 10, 410, 20)

	local controlKeyMap = {
		{"Load next seed", "PromptEditControllerLoadNext", },
		{"Toggle view", "PromptEditControllerToggleView", },
		{"Cycle through stats", "PromptEditControllerCycleStats", },
		{"Mark stat", "PromptEditControllerMarkStat", },
	}

	local inputTextboxes = {}
	local offsetX = 90
	local offsetY = 35

	for i, controlTuple in ipairs(controlKeyMap) do
		local controlLabel = string.format("%s:", Resources.SetupScreen[controlTuple[2]])
		forms.label(form, controlLabel, offsetX, offsetY, 105, 20)
		inputTextboxes[i] = forms.textbox(form, Options.CONTROLS[controlTuple[1]], 140, 21, nil, offsetX + 110, offsetY - 2)
		offsetY = offsetY + 24
	end

	-- Buttons
	local saveCloseLabel = string.format("%s && %s", Resources.AllScreens.Save, Resources.AllScreens.Close)
	forms.button(form, saveCloseLabel, function()
		for i, controlTuple in ipairs(controlKeyMap) do
			local controlCombination = Utils.formatControls(forms.gettext(inputTextboxes[i] or ""))
			if not Utils.isNilOrEmpty(controlCombination) then
				Options.CONTROLS[controlTuple[1]] = controlCombination
			end
		end
		Main.SaveSettings(true)
		Program.redraw(true)

		Utils.closeBizhawkForm(form)
	end, 45, offsetY + 5, 105, 25)

	forms.button(form, Resources.SetupScreen.PromptEditControllerResetDefault, function()
		for i, controlTuple in ipairs(controlKeyMap) do
			local default = Options.Defaults.CONTROLS[controlTuple[1]]
			forms.settext(inputTextboxes[i], default or "")
		end
	end, 175, offsetY + 5, 120, 25)

	forms.button(form, Resources.AllScreens.Cancel, function()
		Utils.closeBizhawkForm(form)
	end, 320, offsetY + 5, 75, 25)
end

-- USER INPUT FUNCTIONS
function SetupScreen.checkInput(xmouse, ymouse)
	Input.checkButtonsClicked(xmouse, ymouse, SCREEN.Buttons)
end

-- DRAWING FUNCTIONS
function SetupScreen.drawScreen()
	local canvas = {
		x = Constants.SCREEN.WIDTH + Constants.SCREEN.MARGIN,
		y = Constants.SCREEN.MARGIN + 10,
		width = Constants.SCREEN.RIGHT_GAP - (Constants.SCREEN.MARGIN * 2),
		height = Constants.SCREEN.HEIGHT - (Constants.SCREEN.MARGIN * 2) - 10,
		text = Theme.COLORS[SCREEN.Colors.text],
		border = Theme.COLORS[SCREEN.Colors.border],
		fill = Theme.COLORS[SCREEN.Colors.boxFill],
		shadow = Utils.calcShadowColor(Theme.COLORS[SCREEN.Colors.boxFill]),
	}

	Drawing.drawBackgroundAndMargins()
	gui.defaultTextBackground(Theme.COLORS[SCREEN.Colors.boxFill])

	-- Draw header text
	local headerShadow = Utils.calcShadowColor(Theme.COLORS["Main background"])
	Drawing.drawText(canvas.x, Constants.SCREEN.MARGIN - 2, Utils.toUpperUTF8(Resources.SetupScreen.Title), Theme.COLORS["Header text"], headerShadow)

	-- Draw canvas box
	gui.defaultTextBackground(canvas.fill)
	gui.drawRectangle(canvas.x, canvas.y + TAB_HEIGHT, canvas.width, canvas.height - TAB_HEIGHT, canvas.border, canvas.fill)
	-- Draw bottom edge for the window tab bars
	gui.drawLine(canvas.x, canvas.y + TAB_HEIGHT, canvas.x + canvas.width, canvas.y + TAB_HEIGHT, canvas.border)

	-- Draw all buttons
	for _, button in pairs(SCREEN.Buttons) do
		if button ~= SCREEN.Buttons.PokemonIcon then
			Drawing.drawButton(button, canvas.shadow)
		end
	end
	-- Draw last so it appears over any other buttons
	Drawing.drawButton(SCREEN.Buttons.PokemonIcon, canvas.shadow)

	-- Randomize the pokemon shown every 'changeIconInSeconds'
	if os.time() >= SCREEN.Buttons.PokemonIcon.timeLastChanged + SCREEN.changeIconInSeconds then
		SCREEN.Buttons.PokemonIcon:randomize()
	end
end