/**
 * Baradé's Idle Icon System
 *
 * Simple system which allows you to add custom idle icons with numbers for specific players only.
 */
library IdleIconSystem initializer Init

	globals
			/**
			 * The interval in which the groups of idle unit type icons are updated.
			 */
			constant real IDLE_ICON_SYSTEM_UPDATE_INTERVAL = 0.02
			/**
			 * The timeout until the stored last selected unit of an idle unit type icon group is cleared and the selecting will start from the beginning.
			 * Note that this timer starts when the player stops clicking on the idle unit type icon.
			 */
			constant real IDLE_ICON_SYSTEM_DESELECT_TIMEOUT = 3.0
			/**
			 * The idle unit type icon is hidden if this value is true and the group of idle units becomes empty. Otherwise it is still shown with the number 0.
			 */
			constant boolean IDLE_ICON_SYSTEM_HIDE_ON_ZERO = true
			
			constant real IDLE_ICON_SYSTEM_Y = 0.188
			constant real IDLE_ICON_SYSTEM_START_X = 0.028
			constant real IDLE_ICON_SYSTEM_WIDTH = 0.042
			constant real IDLE_ICON_SYSTEM_ICON_SIZE = 0.038
			constant string IDLE_ICON_SYSTEM_TOC_FILE = "war3mapimported\\BoxedText.toc"
	endglobals


	globals
		private hashtable whichHashTable = InitHashtable()
	endglobals

	function GetIdleWorkerFrame takes nothing returns framehandle
		// Children of "ConsoleUI"/ORIGIN_FRAME_SIMPLE_UI_PARENT
		/*
		 [7] Idle worker Button Container
			[0] Button
				[0] Charges Box (created with the first idle worker)
		*/
		return BlzGetOriginFrame(ORIGIN_FRAME_SIMPLE_UI_PARENT, 7)
	endfunction
	
	function GetIdleWorkerFrameButton takes nothing returns framehandle
		return BlzFrameGetChild(GetIdleWorkerFrame(), 0)
	endfunction
	
	function GetIdleWorkerFrameChargeBox takes nothing returns framehandle
		return BlzFrameGetChild(GetIdleWorkerFrameButton(), 0)
	endfunction
	
	function SetIdleWorkerFrameTexture takes string texture returns nothing
		call BlzFrameSetTexture(GetIdleWorkerFrame(), texture, 0, false)
	endfunction
	
	private keyword IdleIcon
	
	function GetTriggerIdleIcon takes nothing returns IdleIcon
		return LoadIntegerBJ(0, GetHandleId(GetTriggeringTrigger()), whichHashTable)
	endfunction
	
	function interface IdleIconTriggerAction takes IdleIcon idleIcon returns nothing

	private struct IdleIcon
		private static integer counter = 0
		
		private string texture
		private IdleIconTriggerAction triggerAction
		private framehandle iconButton
		private framehandle buttonIconFrame
		private framehandle chargesTextFrame
		private framehandle tooltipFrameBackGround
		private trigger clickTrigger = null
		private integer number
		
		private static method triggerActionClick takes nothing returns nothing
			local thistype this = GetTriggerIdleIcon()
			//call BJDebugMsg("Click action!")
			call this.triggerAction.execute(this)
		endmethod
		
		/**
		 * Apparently, when hiding the framehandle the event does not work anymore, so we have to recreate the whole trigger.
		 */
		private method updateClickTrigger takes nothing returns nothing
			call BlzFrameSetEnable(chargesTextFrame, false)
			call BlzFrameSetEnable(iconButton, true)
			call BlzFrameSetEnable(buttonIconFrame, true)
			
			if (this.clickTrigger == null) then
				// create the trigger handling the Button Clicking	
				set this.clickTrigger = CreateTrigger()
				// register the Click event
				call BlzTriggerRegisterFrameEvent(clickTrigger, iconButton, FRAMEEVENT_CONTROL_CLICK)
				// this happens when the button is clicked
				call TriggerAddAction(clickTrigger, function thistype.triggerActionClick)
				call SaveIntegerBJ(this, 0, GetHandleId(clickTrigger), whichHashTable)
			endif
		endmethod
		
		private method updateTextures takes nothing returns nothing
			if (number > 0 or not IDLE_ICON_SYSTEM_HIDE_ON_ZERO) then
				call BlzFrameSetTexture(buttonIconFrame, this.texture, 0, false)
				call BlzFrameSetText(this.chargesTextFrame, I2S(number))
				call BlzFrameSetVisible(iconButton, true)
				call BlzFrameSetVisible(chargesTextFrame, true)
				call BlzFrameSetVisible(buttonIconFrame, true)
			else
				call BlzFrameSetVisible(iconButton, false)
				call BlzFrameSetVisible(buttonIconFrame, false)
				call BlzFrameSetVisible(chargesTextFrame, false)
			endif
		endmethod
		
		public method setNumber takes integer number returns nothing
			set this.number = number
			call this.updateTextures()
			call this.updateClickTrigger()
		endmethod
		
		public method showForPlayerOnly takes player whichPlayer returns nothing
			local string tex = this.texture
			if (GetLocalPlayer() == whichPlayer) then
				call this.updateTextures()
			else
				call BlzFrameSetVisible(iconButton, false)
				call BlzFrameSetVisible(buttonIconFrame, false)
				call BlzFrameSetVisible(chargesTextFrame, false)
			endif
			call this.updateClickTrigger()
		endmethod
		
		public method showForForceOnly takes force whichForce returns nothing
			local string tex = this.texture
			if (IsPlayerInForce(GetLocalPlayer(), whichForce)) then
				call this.updateTextures()
			else
				call BlzFrameSetVisible(iconButton, false)
				call BlzFrameSetVisible(buttonIconFrame, false)
				call BlzFrameSetVisible(chargesTextFrame, false)
			endif
			call this.updateClickTrigger()
		endmethod
		
		public method setPos takes real x, real y returns nothing
			call BlzFrameSetAbsPoint(iconButton, FRAMEPOINT_CENTER, x, y)
		endmethod
		
		public static method create takes string texture, IdleIconTriggerAction triggerAction, string tooltip returns thistype
			local thistype this = thistype.allocate()

			set thistype.counter = thistype.counter + 1

			set this.texture = texture
			set this.triggerAction = triggerAction

			set this.iconButton = BlzCreateFrameByType("BUTTON", "MyIconButton" + I2S(this), BlzGetOriginFrame(ORIGIN_FRAME_GAME_UI, 0), "CommandButtonTemplate", this)
			// create a BACKDROP for Button which displays the Texture
			set this.buttonIconFrame = BlzCreateFrameByType("BACKDROP", "MyIconButtonIcon" + I2S(this), iconButton, "", this)
			// buttonIcon will mimic buttonFrame in size and position
			call BlzFrameSetAllPoints(buttonIconFrame, iconButton)
			// place the Button to the left center of the Screen
			call BlzFrameSetAbsPoint(iconButton, FRAMEPOINT_CENTER, IDLE_ICON_SYSTEM_START_X + (counter * IDLE_ICON_SYSTEM_WIDTH), IDLE_ICON_SYSTEM_Y)
			// set the Button's Size
			call BlzFrameSetSize(iconButton, IDLE_ICON_SYSTEM_ICON_SIZE, IDLE_ICON_SYSTEM_ICON_SIZE)
			// set the texture
			call BlzFrameSetTexture(buttonIconFrame, texture, 0, false)

			call this.updateClickTrigger()

			// Add charges text
			// TODO Create as child frame
			// TODO add black background
			set this.chargesTextFrame = BlzCreateFrameByType("TEXT", "MyIconText" + I2S(this), this.iconButton, "", this)
			call BlzFrameSetPoint(chargesTextFrame, FRAMEPOINT_CENTER, this.iconButton, FRAMEPOINT_BOTTOMRIGHT, -0.005, 0.005)
			call BlzFrameSetEnable(chargesTextFrame, false)
			call BlzFrameSetText(chargesTextFrame, "0")
			call BlzFrameSetScale(chargesTextFrame, 1.0)

			// tooltip
			set this.tooltipFrameBackGround = BlzCreateFrame("BoxedText", iconButton, 0, this)
			call BlzFrameSetAbsPoint(tooltipFrameBackGround, FRAMEPOINT_CENTER, 0.2, 0.3)
			call BlzFrameSetSize(tooltipFrameBackGround, 0.15, 0.08)
			call BlzFrameSetText(BlzGetFrameByName("BoxedTextValue", this), tooltip) // BoxedText has a child showing the text, set that childs Text.
			call BlzFrameSetText(BlzGetFrameByName("BoxedTextTitle", this), tooltip) // BoxedText has a child showing the Title-text, set that childs Text.
			call BlzFrameSetTooltip(buttonIconFrame, tooltipFrameBackGround)

			return this
		endmethod
		
		public method onDestroy takes nothing returns nothing
			call FlushChildHashtable(whichHashTable, GetHandleId(clickTrigger))
			call DestroyTrigger(clickTrigger)
			
			call BlzDestroyFrame(iconButton)
			call BlzDestroyFrame(chargesTextFrame)
			call BlzDestroyFrame(tooltipFrameBackGround)
		endmethod
	endstruct


	function AddIdleIcon takes string texture, IdleIconTriggerAction triggerAction, string tooltip returns IdleIcon
		return IdleIcon.create(texture, triggerAction, tooltip)
	endfunction
	
	function SetIdleIconNumber takes IdleIcon idleIcon, integer number returns nothing
		call idleIcon.setNumber(number)
	endfunction
	
	function ShowIdleIconForPlayerOnly takes IdleIcon idleIcon, player whichPlayer returns nothing
		call idleIcon.showForPlayerOnly(whichPlayer)
	endfunction
	
	function ShowIdleIconForForceOnly takes IdleIcon idleIcon, force whichForce returns nothing
		call idleIcon.showForForceOnly(whichForce)
	endfunction
	
	function SetIdleIconPosition takes IdleIcon idleIcon, real x, real y returns nothing
		call idleIcon.setPos(x, y)
	endfunction
	
	function RemoveIdleIcon takes IdleIcon idleIcon returns nothing
		call idleIcon.destroy()
	endfunction
	
	private struct IdleUnitTypeIcon extends IdleIcon
		private static integer array playerCounter[30]
	
		private player owner
		private trigger hotkeyTrigger
		private group whichGroup = CreateGroup()
		private boolexpr unitTypeFilter = null
		private unit selected = null
		private timer selectedClearTimer = CreateTimer()
		private timer updateTimer = CreateTimer()
		
		private static method timerFunctionUpdate takes nothing returns nothing
			local thistype this = thistype(LoadIntegerBJ(0, GetHandleId(GetExpiredTimer()), whichHashTable))
			call GroupClear(this.whichGroup)
			call GroupEnumUnitsOfPlayer(this.whichGroup, this.owner, this.unitTypeFilter)
			call this.setNumber(CountUnitsInGroup(this.whichGroup))
			call this.showForPlayerOnly(this.owner)
			
			//call BJDebugMsg("Updating group " + I2S(this) + " with " + I2S(CountUnitsInGroup(this.whichGroup)) + " units!")
			
			if (this.selected != null and not IsUnitInGroup(this.selected, this.whichGroup)) then
				set this.selected = null
			endif
		endmethod
		
		private static method timerFunctionClearSelected takes nothing returns nothing
			local thistype this = thistype(LoadIntegerBJ(0, GetHandleId(GetExpiredTimer()), whichHashTable))
			set this.selected = null
			//call BJDebugMsg("Clear selected unit")
		endmethod
		
		private static method triggerActionClickButton takes thistype this returns nothing
			local boolean found = false
			local boolean flag2 = false
			local group copy = CreateGroup()
			local unit first = null
			local unit next = null
			
			call PauseTimer(selectedClearTimer)
			
			call GroupAddGroup(this.whichGroup, copy)
			
			if (selected != null) then
				loop
					set first = FirstOfGroup(copy)
					call GroupRemoveUnit(copy, first)
					exitwhen (first == null or next != null)
					if (first == selected) then
						set found = true
					elseif (found and next == null) then
						set next = first
						//call BJDebugMsg("Set next unit based on the selected")
					endif
				endloop
			endif
			
			call GroupClear(copy)
			call DestroyGroup(copy)
			set copy = null
			
			if (next == null) then
				set next = FirstOfGroup(this.whichGroup)
			endif
			
			if (next != null) then
				set this.selected = next
				call SelectUnitForPlayerSingle(next, this.owner)
				call PanCameraToTimedForPlayer(this.owner, GetUnitX(next), GetUnitY(next), 0 )
				call TimerStart(selectedClearTimer, IDLE_ICON_SYSTEM_DESELECT_TIMEOUT, false, function thistype.timerFunctionClearSelected)
			endif
		endmethod
		
		private static method triggerActionClickButtonEx takes nothing returns nothing
			call thistype.triggerActionClickButton(GetTriggerIdleIcon())
		endmethod
		
		public static method create takes player owner, string texture, boolexpr unitTypeFilter, oskeytype key, string tooltip returns thistype
			local thistype this = thistype.allocate(texture, thistype.triggerActionClickButton, tooltip)
			set this.owner = owner
			set this.unitTypeFilter = unitTypeFilter
			call SaveIntegerBJ(this, 0, GetHandleId(this.selectedClearTimer), whichHashTable)
			call SaveIntegerBJ(this, 0, GetHandleId(this.updateTimer), whichHashTable)
			
			set this.hotkeyTrigger = CreateTrigger()
			
			if (key != null) then
				call BlzTriggerRegisterPlayerKeyEvent(this.hotkeyTrigger, this.owner, key, 0, true)
			endif
			
			call TriggerAddAction(this.hotkeyTrigger, function thistype.triggerActionClickButtonEx)
			call SaveIntegerBJ(this, 0, GetHandleId(this.hotkeyTrigger), whichHashTable)
			
			call TimerStart(updateTimer, IDLE_ICON_SYSTEM_UPDATE_INTERVAL, true, function thistype.timerFunctionUpdate)
			
			set thistype.playerCounter[GetPlayerId(owner)] = thistype.playerCounter[GetPlayerId(owner)] + 1
			
			call SetIdleIconPosition(this, IDLE_ICON_SYSTEM_START_X + (thistype.playerCounter[GetPlayerId(owner)] * IDLE_ICON_SYSTEM_WIDTH), IDLE_ICON_SYSTEM_Y)
			
			call this.showForPlayerOnly(owner)
			
			return this
		endmethod
		
		public method onDestroy takes nothing returns nothing
			call FlushChildHashtable(whichHashTable, GetHandleId(updateTimer))
			call PauseTimer(updateTimer)
			call DestroyTimer(updateTimer)
			
			call FlushChildHashtable(whichHashTable, GetHandleId(updateTimer))
			call PauseTimer(selectedClearTimer)
			call DestroyTimer(selectedClearTimer)
			
			call FlushChildHashtable(whichHashTable, GetHandleId(hotkeyTrigger))
			call DestroyTrigger(hotkeyTrigger)
			
			call GroupClear(whichGroup)
			call DestroyGroup(whichGroup)
		endmethod
		
	endstruct
	
	function AddIdleUnitTypeIcon takes player owner, string texture, code unitTypeFilter, oskeytype key, string tooltip returns IdleUnitTypeIcon
		return IdleUnitTypeIcon.create(owner, texture, Filter(unitTypeFilter), key, tooltip)
	endfunction
	
	function RemoveIdleUnitTypeIcon takes IdleUnitTypeIcon idleIcon returns nothing
		call idleIcon.destroy()
	endfunction
	
	private function Init takes nothing returns nothing
		call BlzLoadTOCFile(IDLE_ICON_SYSTEM_TOC_FILE)
	endfunction

endlibrary