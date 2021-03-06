
local pairs = pairs
local ipairs = ipairs
local table = table

local CTitle = game_require("view.fight.creature.CTitle")
local CStatus = game_require("view.fight.creature.CStatus")
local MultiAvatar = game_require("view.fight.creature.MultiAvatar")

local DieHandle = game_require("view.fight.handle.DieHandle")

local Shadow = game_require("view.fight.creature.Shadow")

local Creature = class("Creature",function() return display.newNode() end)

Creature.STAND_ACTION = "stand"
Creature.ATTACK_ACTION = "atk"
Creature.MOVE_ACTION = "move"
Creature.HURT_ACTION = "hurt"
Creature.DIE_ACTION = "die"
Creature.MAGIC_ACTION = "magic"
Creature.WIN_ACTION = "win"

Creature.UP = GameConst.UP
Creature.RIGHT_UP_1 = GameConst.RIGHT_UP_1
Creature.RIGHT_UP = GameConst.RIGHT_UP
Creature.RIGHT_UP_2 = GameConst.RIGHT_UP_2
Creature.RIGHT = GameConst.RIGHT
Creature.RIGHT_DOWN_1 = GameConst.RIGHT_DOWN_1
Creature.RIGHT_DOWN = GameConst.RIGHT_DOWN
Creature.RIGHT_DOWN_2 = GameConst.RIGHT_DOWN_2
Creature.DOWN = GameConst.DOWN
Creature.LEFT_DOWN_1 = GameConst.LEFT_DOWN_1
Creature.LEFT_DOWN = GameConst.LEFT_DOWN
Creature.LEFT_DOWN_2 = GameConst.LEFT_DOWN_2
Creature.LEFT = GameConst.LEFT
Creature.LEFT_UP_1 = GameConst.LEFT_UP_1
Creature.LEFT_UP = GameConst.LEFT_UP
Creature.LEFT_UP_2 = GameConst.LEFT_UP_2

Creature.BE_ATTACK = 0
Creature.BE_HURT = 1
Creature.HP_CHANGE = 2
Creature.DIE_EVENT = 3 --死亡

function Creature:ctor(info)
	-- EventProtocol.extend(self)
	self.id = FightEngine:getGlobalId()

	self.av = MultiAvatar.new("",function(d) self:updateDirection(d) end)
	self.av:retain()

	self.avContainer = display.newNode()
	self.avContainer:retain()
	self:addChild(self.avContainer,1)
	self.avContainer:addChild(self.av)

	self.cTitle = CTitle.new()
	self.cTitle:retain()

	self._skillCount = 0
	self.mx = 1
	self.my = 1

	self:init(info)

	if info.heroType == 1 then
		self.shadow = Shadow.new()
	else
		self.shadow = Shadow.new(info.res)
	end
	self.shadow:retain()
	self:addChild(self.shadow,0)

	self.av:setShadow(self.shadow)
	local nameColor
	if info.team == FightCommon.left then
		-- print("特殊ai。。。。",info.name,info.speciaAI)
		local avInfo = self.av:isExistFrame(0,GameConst.STAND_ACTION,Creature.RIGHT_UP)
		if avInfo  then
			self:setDirection(Creature.RIGHT_UP)
		else
			self:setDirection(Creature.RIGHT)
		end

		nameColor =ccc3(135,206,250)
	else
		local avInfo = self.av:isExistFrame(0,GameConst.STAND_ACTION,Creature.LEFT_DOWN)
		if avInfo then
			self:setDirection(Creature.LEFT_DOWN)
		else
			self:setDirection(Creature.LEFT)
		end
		nameColor =ccc3(255,0,0)
	end

	self.isWin = false

	self:retain()

	if FightDirector.status == FightCommon.start then
		self:start()
	end
	if info.isElite and info.name  then
		--self:setScale(1.2)
		local params = {text = info.name,size=18,color=nameColor}
		local nameText = ui.newTTFLabelWithOutline(params)
		nameText:setAnchorPoint(ccp(0.5,0))
		nameText:setContentSize(nameText:getContentSize())
		self:addChild(nameText,8)
		if self:isFly() then
			nameText:setPositionY(170)
		else
			nameText:setPositionY(60)
		end
		self._nameText = nameText
	end
end

function Creature:init(info)
	self.titleShowTime = 0

	self._magicList = {}

	self._originalInfo = {}
	table.merge(self._originalInfo,info) --原信息
	self._originalInfo.hp = self._originalInfo.maxHp  --血量保 持最大的

	self.cInfo = info

	self.cTitle:init(info)

	FightCache:retainAnima(info.res)  --资源
	self:setAV(info.res)


	self.cStatus = CStatus.new(self)

	self.cInfo.mSpeed = self.cInfo.speed
	self.cInfo.speed = Formula:transformSpeed(self.cInfo.mSpeed)  --换算成真正的时间
	self.cInfo.speedX = FightMap.COS * self.cInfo.speed
	self.cInfo.speedY = FightMap.SIN * self.cInfo.speed

	self.posLength = info.posLength or 1
	self.posRange = Range.new({self.posLength})

	self.atkRange = Range.new({10})  --攻击范围
	self.atkRange.atkScope = info.atkScope[1]

	self.atkRangeList = {}
	self.atkRangeList[1] = self.atkRange
	if info.atkRange_1 then
		local aRange = Range.new(info.atkRange_1)
		aRange.atkScope = info.atkScope[2]
		self.atkRangeList[2] = aRange
	end

	self.ai = info.ai
	self._curTime = 0
	self:removeTitle()
	local checkScale = function()
		local careers = { 7,8,9,10,11,12,13,14}
		if table.indexOf(careers,self.cInfo.career) >0 then
			return false
		end
		return true
	end

--	if checkScale() then
--		self:setScale(0.7)
--	end
end

function Creature:setAtkRange( range )
	self.atkRange = Range.new(range)  --攻击范围
	self.atkRange.atkScope = self.cInfo.atkScope[1]
	self.atkRangeList[1] = self.atkRange

end

function Creature:updateTitlePos(res)
	if self.cInfo then
		res = res or self.cInfo.res
		local aInfo = AnimationMgr:getAnimaInfo(res)
		local action = AnimationMgr:getActionInfo(res,Creature.STAND_ACTION.."_3")
		local size = aInfo:getFrameSize(action.startFrame)
		local height = size.height

		-- local avScale = self.avContainer:getScale()
		local offY = FightCfg:getTitleY(res)
		height = height + offY
		-- if self.cInfo.heroType == 1 then
		-- 	height = height/2
		-- end
		self.cTitle:setY(height)
	end
end

function Creature:setAV( res )
	-- FightCache:retainAnima(res)  --缓存资源
	self._curAvRes = res
	self.av:initWithResName(res)
	if self.cInfo.team == FightCommon.blue then
		self.av:addColorAv(res)
	end
	self.av:addTopAv(res)

	local aInfo = AnimationMgr:getAnimaInfo(res)
	if not aInfo then
		StatSender:sendBug("not action:" .. (res or "null ") .. (self.cInfo.id or 0))
	end
	self.av:setPosition(-aInfo.offX,-aInfo.offY)
	self:updateTitlePos(res)
end

function Creature:changeColor()
	if self.av:hasColor() then
		self.av:removeColorAv()
	else
		self.av:addColorAv(self._curAvRes)
	end
end

function Creature:addSkillCount()
	self._skillCount = self._skillCount + 1
end

function Creature:removeSkillCount()
	self._skillCount = self._skillCount - 1
end

function Creature:getSkillCount()
	return self._skillCount
end

--战斗开始
function Creature:start()
	-- self.cStatus:startPassiveSkill()
end

--每帧执行
-- 主要是在没使用技能 的时候  播放待机动作
function Creature:run(dt)

	if FightDirector.status < FightCommon.start then
		self.av:turnRun(dt)
		return false
	end

	self.cStatus:run(dt)

	if self.isWin or self:isDie() then
		return false
	end

	if self.titleShowTime > 0 then
		self.titleShowTime = self.titleShowTime - dt
		if self.titleShowTime < 0 then
			self:removeTitle()
		end
	end
	self._curTime = self._curTime + dt

	self.av:turnRun(dt)
	return true
end

function Creature:getMagicList()
	return self._magicList
end

function Creature:addMagic( magic,addIndex )
	local x,y = 0,0
	if addIndex == -1 then
		self:addChild(magic,0)
	else
		self:addChild(magic,11)
	end
	magic:retain()
	self._magicList[#self._magicList + 1] = magic
end

function Creature:reAddMagic(magic,addIndex)
	if addIndex == -1 then
		magic:setZOrder(0)
	else
		magic:setZOrder(11)
	end
end

function Creature:removeMagic( magic,addIndex )
	for i,mg in ipairs(self._magicList) do
		if magic == mg then
			table.remove(self._magicList,i)
			break
		end
	end
	magic:removeFromParent()
	magic:release()
end

--改变属性
function Creature:changeValue(tType,value,source,skill,eParams)

	if self.isWin or self:isDie() then
		return
	end
		if tType == HeroConst.HP then  --血量变化
			--不用这个了
			-- value = self:getBuffEffectValue(value,skill.effect)  --计算一下buff 的加成

			-- return self:hpChange(value,source,skill,eParams)
		elseif tType == HeroConst.MAXHP then  --max hp变化
			local rate = self.cInfo.hp/self.cInfo.maxHp
			self.cInfo.maxHp = self.cInfo.maxHp + value
			if self.cInfo.maxHp < 0 then  --最低0
				self.cInfo.maxHp = 0
			end
			local oldHp = self.cInfo.hp
			self.cInfo.hp = math.ceil(rate*self.cInfo.maxHp)
			self.cTitle:setBlood(self.cInfo.hp,self.cInfo.maxHp,true)
			FightTrigger:dispatchEvent({name=FightTrigger.CREATURE_CHANGE_HP,creature=self,value=self.cInfo.hp-oldHp,curHp=self.cInfo.hp,maxHp=self.cInfo.maxHp})

		elseif tType == HeroConst.SPEED then  --改变速度
			self.cInfo.mSpeed = self.cInfo.mSpeed + value
			if self.cInfo.mSpeed < 100 then  --移动速度 最低300
				self.cInfo.mSpeed = 100
			end
			self.cInfo.speed = Formula:transformSpeed(self.cInfo.mSpeed)  --换算成真正的时间
			-- print("改变速度。。。。",self.cInfo.speed,value,self.cInfo.mSpeed,FightMap.COS,FightMap.SIN)
			self.cInfo.speedX = FightMap.COS * self.cInfo.speed
			self.cInfo.speedY = FightMap.SIN * self.cInfo.speed
		elseif tType == HeroConst.ATKCD then
			self.cInfo[tType] = self.cInfo[tType] + value
			if self.cInfo[tType] < 500 then  --攻击速度 最低500
				self.cInfo[tType] = 500
			end
		elseif self.cInfo[tType] then  --其他数值变化
			if self.cInfo[tType] < 0 then  --属性最小是 0
				self.cInfo[tType] = 0
			end
			self.cInfo[tType] = self.cInfo[tType] + value
		end
end

function Creature:changeHP(value,hurtParams,skill,force,source)
	-- print(debug.traceback())
	if (self:isDie() or FightDirector.status > FightCommon.start) and not force then  --强制的改变血量 复活技能才行
		return 0  --不能改变血量了
	end
	if self.isWin and value < 0 then  --已经赢了
		return 0
	end
	value = math.floor(value)
	if value == 0 and skill and skill.effect == FightCfg.ASSIST then
		return 0
	end
	if self.cInfo.hp <=0 then
		return
	else
		if not self._isLockHp then
			if value < -self.cInfo.hp then
				value = -self.cInfo.hp
			end
			local oldHp = self.cInfo.hp
			self.cInfo.hp = self.cInfo.hp + value
			if self.cInfo.hp > self.cInfo.maxHp then
				self.cInfo.hp = self.cInfo.maxHp
			end
			value = self.cInfo.hp-oldHp
		end
	end

	--self:_checkAddHurtMagic()

	self.cTitle:setBlood(self.cInfo.hp,self.cInfo.maxHp)
	-- self:dispatchEvent({name=Creature.HP_CHANGE,creature=self,value=value})
	FightTrigger:dispatchEvent({name=FightTrigger.CREATURE_CHANGE_HP,creature=self,source = source,value=value,curHp=self.cInfo.hp,maxHp=self.cInfo.maxHp})
	self:_showTitle()

	return value
end

function Creature:setMaxHp( maxHp )
	self.cInfo.maxHp = maxHp
end

function Creature:setHp(hp)
	self.cInfo.hp = hp
	self.cTitle:setBlood(self.cInfo.hp,self.cInfo.maxHp)
	self:_showTitle()
end

function Creature:_showTitle(time)
	if not self.cTitle:getParent() then
		self:addChild(self.cTitle,10)
	end
	self.titleShowTime = time or 5000  --显示5秒
end

function Creature:removeTitle()
	self.cTitle:removeFromParent()
end

function Creature:isFly()
	return false
end

function Creature:getOriginalValue( tType )
	return self._originalInfo[tType]
end

function Creature:updateDirection(direction)
	self:setMagicDirection(direction)
end

--设置朝向
function Creature:setDirection( direction)
	self.av:setDirection(direction)
end

function Creature:setMagicDirection(direction)
	if Formula:isBaseDirection(direction) then
		for i,magic in ipairs(self._magicList) do
			if magic.getDirectionType and magic:getDirectionType() ~= 1 then
				magic:setDirection(direction)
			end
		end
	end
end

function Creature:isAtkFaceto(d)
	return self:getAtkDirection() == d
end

function Creature:getDirection()
	return self.av:getDirection()
end

function Creature:getTruePosition()
	return self:getPosition()
end

function Creature:getAtkPosition()
	return self:getPosition()
end

--直接显示某一动作的某一帧
function Creature:showAnimateFrame( frame,action,direction)
	if direction then
		self:setDirection(direction)
	end
	if not self._curAvRes or self._curAvRes == "" then
		return false
	end

	self.av:showAnimateFrame(frame,action,direction)
	return true
end

function Creature:getAnimationInfo( action )
	return AnimationMgr:getActionInfo(self._curAvRes,action .."_3")
end

function Creature:turnAtkDirection(d)
	self:turnDirection(d)
end

function Creature:turnDirection(d,delyTime)
	self.av:turnDirection(d,delyTime)
end

function Creature:getTurnDirection()
	return self.av:getTurnDirection()
end

function Creature:isTurning()
	return self.av:isTurnIng()
end

function Creature:getAtkDirection()
	return self:getDirection()
end

function Creature:getAtkRate(weapon)
	if weapon == FightCfg.MAIN_ATTACK then
		return self.cInfo.atkRate
	else
		return self.cInfo.atkRate_1
	end
	return nil
end

function Creature:getAtkValue(weapon)
	if weapon == FightCfg.MAIN_ATTACK then
		return self.cInfo.main_atk
	else
		return self.cInfo.minor_atk
	end
end

function Creature:getHpRate(  )
	return self.cInfo.hp/self.cInfo.maxHp
end

function Creature:_checkAddHurtMagic()
	local rate = self:getHpRate()
	local mId
	if rate < 0.25 then
		mId = 9
	elseif rate < 0.5 then
		mId = 8
	end
	if self._hurtMagicId then
		local magic = FightEngine:getMagicById(self._hurtMagicId)
		if magic and magic.magicId ~= mId then
			FightEngine:removeMagicById(self._hurtMagicId)
			self._hurtMagicId = nil
		end
	end
	if self._hurtMagicId == nil and mId then
		local magic = FightEngine:createMagic(self, mId,nil,nil,nil,nil,self)
		if magic then
			self._hurtMagicId = magic.gId
		end
	end
end

function Creature:removeHurtMagic()
	if self._hurtMagicId then
		FightEngine:removeMagicById(self._hurtMagicId)
		self._hurtMagic = nil
	end
end


function Creature:checkDie(value)
	return self.cStatus:checkDie(value)
end

--是否死亡
function Creature:isDie()
	if self.cInfo.hp <= 0 then
		return true
	else
		return false
	end
end

--直接死亡
function Creature:die(killer,dType)
	local value = -self.cInfo.hp
	self.cInfo.hp = 0
	-- self:dispatchEvent({name=Creature.HP_CHANGE,creature=self,value=value})
	FightTrigger:dispatchEvent({name=FightTrigger.CREATURE_CHANGE_HP,creature=self,value=value,curHp=self.cInfo.hp,maxHp=self.cInfo.maxHp})
	self.cTitle:setBlood(self.cInfo.hp,self.cInfo.maxHp)
	self:dieHandle(killer,dType)
end

function Creature:dieHandle(killer,dType)
	if self._nameText then
		self._nameText:removeFromParent()
		self._nameText = nil
	end
	local handle = DieHandle.new(self,killer,dType)
	local itme = nil
	handle:start()
end

function Creature:setDieEnd()
	self.av:clear()
	self.cTitle:removeFromParent()
	self.shadow:removeFromParent()
	self._curAvRes = ""
end

function Creature:win()
	FightEngine:removeCreatureBuff(self)
	self.isWin = true
end

--weapon   :  1 or 2  主  副武器
function Creature:getAtkRangeByWeapon(weapon)
	return self.atkRangeList[weapon]
end

function Creature:getAtkScope(weapon)
	return self.cInfo.atkScope[weapon]
end

-- 添加buff
function Creature:addBuff(buff)
	self.cStatus:addBuff(buff)
end

--移除buff
function Creature:removeBuff( buff )
	self.cStatus:removeBuff(buff)
end

function Creature:getBuffList()
	return self.cStatus:getBuffList()
end

--能否受击
function Creature:canBeHit(skillInfo)
--	if self.beIgnored then
--		return false
--	end

	if not skillInfo then
		return true
	else
		return self.cStatus:canBeHit(skillInfo)
	end
end

--是否免疫buff
function Creature:immuneBuff( buffId )
	return self.cStatus:immuneBuff(buffId)
end

--能否被搜索到
function Creature:canBeSearch(source,atkScope)

	if self.beIgnored and source.cInfo.scope ~= FightCfg.FLY then
		return false
	end

	if self:isDie() then
		return false
	end
	atkScope = source.atkRange.atkScope

	if not Formula:isScopeContain(atkScope,self.cInfo.scope)  then
		return false
	end

	if source:isInIgnore(self) then
		return false
	end

	return self.cStatus:canBeSearch(source)
end

--能否被搜索到
function Creature:canBeSearchEx(source,atkScope)
	if self.beIgnored then
		return false
	end
	if self:isDie() then
		return false
	elseif source.isPlayer then
		return true
	end
	atkScope = source.atkRange.atkScope
	if not Formula:isScopeContain(atkScope,self.cInfo.scope)  then
		return false
	end
	return self.cStatus:canBeSearch(source)
end

function Creature:isInIgnore(target)
	if self.cInfo.ignore then
		if table.indexOf(self.cInfo.ignore,target.cInfo.career) > 0 then
			return true
		end
	end
	return false
end

--能否搜索目标   恐惧
function Creature:canSearch()
	return self.cStatus:canSearch()
end

--能否移动
function Creature:canMove()
	return not self.forbidMove  and self.cStatus:canMove() and self.cInfo.mSpeed > 0
end

--能否被眩晕 控制 打断等
function Creature:canBeBreak(  )
	return self.cStatus:canBeBreak()
end

--能否使用技能
function Creature:canUseSkill( info )
	if not self.cInfo.skillTurn then
		return false
	else
		return self.cStatus:canUseSkill(info)
	end
end

--能否使用技能
function Creature:canMainSkill(  )
	return self.cInfo.skillTurn ~= nil and self.cInfo.skills ~= nil
end

function Creature:getTeamList(team)
	return self.cStatus:getTeamList(team)
end

--获取技能目标列表
function Creature:getMagicTarget( magic,targetType )
	return self.cStatus:getMagicTarget(magic,targetType)
end

--对别人造成伤害 或者 加血 增加或者减少作用
function Creature:getBuffEffectValue( value,effect )
	return self.cStatus:getBuffEffectValue(value,effect)
end

--被别人伤害 或者 被加血 作用
function Creature:getBuffFilterValue( value,effect )
	return self.cStatus:getBuffFilterValue(value,effect)
end

--被谁打到了
function Creature:beHurt( value,creature)
	-- self.cStatus:beHurt(value,creature,skill)

end

function Creature:getBuffById(id)
	return self.cStatus:getBuffById(id)
end

function Creature:setColor(color)
	self.av:setColor(color)
	self.shadow:setColor(color)
end

function Creature:setLockHp(flag)
	self._isLockHp = flag
end

function Creature:dispose()
	self.cStatus:dispose()
	self.cStatus = nil
	self.avContainer:release()
	self.av:release()
	self.cTitle:dispose()
	self.cTitle:release()
	self.shadow:release()

	self.avContainer = nil

	self.cInfo = nil
	self._originalInfo = nil
	self:removeFromParent()
	print("--销毁creature",self:retainCount())

	-- self:removeAllEventListeners()
	self:release()
end

--是否是第几梯队的城墙BOSS
function Creature:isCityWallBoss( echelonIndex )
		if  self.cInfo.echelonType
			and self.cInfo.cityWallBoss
			and self.cInfo.echelonType == echelonIndex
			and self:isCityWall() then
			return true
		end
	return false
end

function Creature:isHasBlock( )
	if self:isCityWall() or self:isMilitaryBase() or self:isDefensetower() then
		return true
	end
	return false
end

function Creature:isCityWall()
	if not self.cInfo.echelonType then
		return false
	end
	local index = self.cInfo.echelonType%10
	return index == 0
end

function Creature:isMilitaryBase()
	if not self.cInfo.echelonType then
		return false
	end
	return self.cInfo.echelonType == 0
end

function Creature:isDefensetower()
	if not self.cInfo.echelonType then
		return false
	end
	local index = self.cInfo.echelonType%10
	return index == 1
end

return Creature