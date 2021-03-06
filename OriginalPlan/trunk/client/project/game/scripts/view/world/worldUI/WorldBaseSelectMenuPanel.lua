local WorldBaseSelectMenuPanel = class("WorldBaseSelectMenuPanel", function() return display.newNode() end)

game_require("math.MathUtil")

function WorldBaseSelectMenuPanel:ctor(priority, map)
	--! WorldMap
	self._map = map
    self.uiNode = UINode.new(priority - 1, true)
    self.uiNode:setUI("world_base_select_menu")
    self:addChild(self.uiNode)
    self._priority = priority-1
	self:setAnchorPoint(ccp(0,0))
	self.name = self.uiNode:getNodeByName("name")
	self.pos = self.uiNode:getNodeByName("pos")
	self.btnAttack = self.uiNode:getNodeByName("attack_btn")
	self.btnAttack:addEventListener(Event.MOUSE_CLICK, {self,self.clickAttack})
	self.btnSpy = self.uiNode:getNodeByName("spy_on_btn")
	self.btnSpy:addEventListener(Event.MOUSE_CLICK, {self,self.clickSpy})
	self.btnClamour = self.uiNode:getNodeByName("clamour_btn")
	self.btnInfo = self.uiNode:getNodeByName("info_btn")
    self:retain()
end

function WorldBaseSelectMenuPanel:clickAttack(event)
	NotifyCenter:dispatchEvent({name=Notify.WORLD_UNSELECT_CLICK})
	NotifyCenter:dispatchEvent({name=Notify.ADD_MARCH,destBlockPos=self.blockPos,srcBlockPos={x=114,y=111}})
end

function WorldBaseSelectMenuPanel:clickSpy(event)
	if math.random(1,100) > 50 then
		floatText("侦查成功，进入对方主城")
		NotifyCenter:dispatchEvent({name=Notify.WORLD_UNSELECT_CLICK})
		NotifyCenter:dispatchEvent({name=Notify.ENTER_TOWN})
	else
		floatText("侦查失败")
	end
end

function WorldBaseSelectMenuPanel:getBlockPos()
	return self.blockPos
end

function WorldBaseSelectMenuPanel:showInfo( blockPos, mapNodePos )
    -- body
    self.blockPos = blockPos
    self._posX = blockPos.x
    self._posY = blockPos.y
    self:setPosition(mapNodePos)
    self.data = WorldMapModel:getAllElemInfoAt( blockPos )
	dump(self.data)
	self.name:setText(self.data.base.data.worldPlayerInfo.name)
	local pos = self.data.base.data.worldPos
	self.pos:setText(string.format("x:%.0f,y:%.0f",pos.x,pos.y))
	if self.data.base.data.worldPlayerInfo.relationShip == 2 then
		self.btnSpy:setEnable(false)
		self.btnSpy:setVisible(false)
		self.btnClamour:setEnable(false)
		self.btnClamour:setVisible(false)
		self.btnAttack:setEnable(false)
		self.btnAttack:setVisible(false)
	else
		self.btnSpy:setEnable(true)
		self.btnSpy:setVisible(true)
		self.btnClamour:setEnable(true)
		self.btnClamour:setVisible(true)
		self.btnAttack:setEnable(true)
		self.btnAttack:setVisible(true)
	end
end

function WorldBaseSelectMenuPanel:dispose()
	self.btnAttack:removeEventListener(Event.MOUSE_CLICK,{self,self.clickAttack})
	self.btnSpy:removeEventListener(Event.MOUSE_CLICK,{self,self.clickSpy})
    self.uiNode:dispose()
    self:release()
end

function WorldBaseSelectMenuPanel:updateInfo( mapNodePos )
    -- body
    self:setPosition(mapNodePos)
end

function WorldBaseSelectMenuPanel:dispose()

end

return WorldBaseSelectMenuPanel
