--
--[[--
 弹道 轨迹 的 magic
]]

local TrackMagic = class("TrackMagic",Magic)
local TEST_MAGIC = 0
function TrackMagic:start()
	self.speed = Formula:transformSpeed(self.info.speed or 300)--

	if self.info.speedA then
		self.speedA = self.info.speedA[1]/1000
		self.speedAStartTime = self.info.speedA[2]
		self.speedATime = self.info.speedA[3]
	end

	if self.magicEf then
		self.magicEf:setScaleX(1)
	end

	self.totalTime = 9999999999

	local curX,curY = self:getPosition()
	local targetX, targetY = self:_getTargetPos()
	local r = math.atan2( targetY-curY, targetX - curX)
	r = -180*r/math.pi
	self:_setRotation(r)

	Magic.start(self)
end

function TrackMagic:run(dt)
	if TEST_MAGIC == self.magicId then
		print("TrackMagic____run___",TEST_MAGIC)
	end
	if Magic.run(self,dt) == false then
		if TEST_MAGIC == self.magicId then
			print("TrackMagic____run___2结束了？？",TEST_MAGIC)
		end
		--print("结束了？？")
		return
	end

	if self.speedAStartTime and self.curTime >= self.speedAStartTime then
		if self.speedATime > 0 then
			self.speedATime = self.speedATime - dt

			self.speed = self.speed + dt*self.speedA
		end
	end

	local curX,curY = self:getPosition()

	local targetX, targetY = self:_getTargetPos()

	--print("magic..",dt)

	local nextX,nextY,r = Formula:getNextPos(curX,curY,targetX,targetY,self.speed,dt)  --计算出 时间间隔 所能到达的点
	--print("飞行速度。。",curX,curY,targetX,targetY,self.speed,dt,nextX,nextY)
	if TEST_MAGIC == self.magicId then
		print("TrackMagic____run___111",curX,curY,targetX,targetY,self.speed,dt)
	end
	--print("目标位置？？",targetX,targetY,curX,curY,nextX,nextY )
	if  math.abs(targetX - nextX) + math.abs(nextY - targetY) < 3 then
--	if nextX == targetX and    then  --移动到目标了
		if TEST_MAGIC == self.magicId then
			local curX,curY = self:getPosition()
			print("TrackMagic____run___333333")
		end
		-- if not self.target:isDie() then
			self:_checkHitKeyFrame(self.target)
		-- end
		-- print("这里。。。。。",self.curTime,self.totalTime,self.loop,self.curLoop)
		self:_magicEnd()  --先移除自己的魔法特效
	else
		r = -180*r/math.pi
		self:_setRotation(r)
		self:setPosition(nextX,nextY)   --移动位置
	end

	if TEST_MAGIC == self.magicId then
		local curX,curY = self:getPosition()
		print("TrackMagic____run___222",curX,curY)
	end
end

function TrackMagic:_checkHitKeyFrame(target )
	local keyframeList = self.info["keyframe"]
	if keyframeList then
		local frameTypeList = self.info["keyType"]
		for i,frame in ipairs(keyframeList) do
			-- print("击中了。。。。",self.magicId,frame,frameTypeList[i],self.info["keyMagic"] and self.info["keyMagic"][i] )
			if frame == -1 then  --  -1表示在  打中人的时候
				local frameType = frameTypeList[i]
				if frameType == Skill.MAGIC_KEY_FRAME then
					-- print("击中了。。。。",frame,frameType,self.info["keyMagic"] and self.info["keyMagic"][i] )
					self:_keyFrameHanlder(i,target,true) --播放一个魔法特效
				elseif frameType == Skill.ATTACK_KEY_FRAME then  --检测攻击到的
					if self:canHitTarget(target) then
						self:_checkHitTarget(i)
					end
				end
			end
		end
	end
end

function TrackMagic:setDirection( direction )

end

function TrackMagic:getDirection()
	return Creature.RIGHT
end

function TrackMagic:_getDirection(creature,target)
	return Creature.RIGHT
end

function TrackMagic:_setRotation( r )
	if self.info.transform == 1 then
		return
	end
	if r > 0 then
		if r < 90 then
			self.direction = Creature.RIGHT_DOWN
		else
			self.direction = Creature.LEFT_DOWN
		end
	elseif r > -90 then
		self.direction = Creature.RIGHT_UP
	else
		self.direction = Creature.LEFT_UP
	end
	-- self.info.transform = 3
	if self.info.transform == 2 then
		-- self:setRotation(r - 90)
		-- print("角度",r,self.direction,Creature.RIGHT_UP)
		if self.direction == Creature.RIGHT_DOWN then
			self:setScaleX(-1)
			self:setScaleY(1)
			self:setRotation(0)
		elseif self.direction == Creature.LEFT_UP then
			self:setScale(1)
			self:setRotation(135)
		elseif self.direction == Creature.RIGHT_UP then
			self:setScaleX(1)
			self:setScaleY(-1)
			self:setRotation(135)
		else
			self:setScale(1)
			self:setRotation(0)
		end
	elseif self.info.transform == 3 then
		print("方向。。。。。",self.direction)
		if self.direction == Creature.RIGHT_DOWN then
			-- self:setScaleX(-1)
			self:setScaleY(-1)
			self:setScaleX(1)
			self:setRotation(r)
		elseif self.direction == Creature.LEFT_UP then
			self:setRotation(r)
			self:setScaleY(-1)
			self:setScaleX(1)
		elseif self.direction == Creature.RIGHT_UP then
			self:setRotation(r)
			self:setScale(1)
		else
			self:setScaleY(-1)
			self:setScaleX(1)
			self:setRotation(r)
		end

	else
		self:setRotation(r)
		if self.light then
			local _,_,x,y = self.info.light[1],self.info.light[2],self.info.light[3],self.info.light[4]
			if (y and y ~= 0) then
				y = y - y*math.abs(r)/90
				self.light:setPositionY(y)
			end
		end
	end
end

function TrackMagic:_getTargetPos()
	-- if not self.target then
	-- 	print("no target ",self.magicId,self.skillId,self.creature.cInfo.name)
	-- end
	local targetX, targetY = self.target:getTruePosition()
	-- local offsetX ,offsetY = self:getOffset()
	-- targetX = targetX + offsetX
	-- local tx,ty = self.target.cTitle:getPosition()
	-- targetY = targetY + ty/2
	return targetX,targetY
end

return TrackMagic