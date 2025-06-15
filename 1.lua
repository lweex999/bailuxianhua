-- @preview-file on
-- 引入 Dora 游戏引擎模块
local Dora = require("Dora") -- 加载 Dora 游戏引擎
local Node = Dora.Node -- 获取节点类
local Sprite = Dora.Sprite -- 获取精灵类
local Label = Dora.Label -- 获取标签类
local Color = Dora.Color -- 获取颜色类
local Vec2 = Dora.Vec2 -- 获取二维向量类

-- 创建主游戏节点
local Game = Node() -- 创建一个根节点，所有元素都挂载在这个节点上

-- 屏幕尺寸常量
local screenWidth = 1440
local screenHeight = 1080
local centerX = 0
local centerY = 0
local topY = screenHeight/2
local bottomY = -screenHeight/2
local rightX = screenWidth/2
local leftX = -screenWidth/2
local backpackWidth = 360 -- 背包宽度

-- 游戏状态（局部变量）
local scene, map, dialogStep, petals, whiteDeer, bellPlaced, seedPlaced,islin2
local bag, draggingItem, draggingSprite, returnBtnAdded, selectedItem
scene = 0; map = 0; bag = {}; dialogStep = 0; petals = 0; islin2 = 0;
whiteDeer = false; bellPlaced = false; returnBtnAdded = false
seedPlaced = false -- 新增：种子是否已种植
selectedItem = nil -- 当前选中的物品

-- 物品拾取状态
local shovelPicked = false
local seedPicked = false

-- 花瓣收集状态
local petal1Collected = false
local petal2Collected = false
local petal3Collected = false

-- 区域定义类
local Rect = {} -- 定义一个矩形区域类
function Rect:new(x0, y0, x1, y1) -- 创建矩形对象
  return setmetatable({x0 = x0, y0 = y0, x1 = x1, y1 = y1}, {__index = self}) -- 设置矩形的坐标和继承
end
function Rect:contains(x, y) -- 判断一个点是否在矩形内
  return x >= self.x0 and x <= self.x1 and y >= self.y0 and y <= self.y1
end

-- 定义游戏中所有交互区域 (使用Dora坐标系，原点在中心)
local zones = { -- 所有地图上的点击区域
  -- 通用区域
  bottom = Rect:new(leftX, bottomY, rightX, bottomY + 100), -- 返回上一地图的底部区域
  
  -- 场景1
  npc1 = Rect:new(-140, -270, 140, 280), -- NPC 区域 (转换后坐标)
  to2 = Rect:new(leftX, topY - 100, rightX, topY), -- 地图1到地图2的传送区域 (转换后坐标)
  pickupShovel = Rect:new(-410, -170, -321, 72), -- 铲子拾取区域 (转换后坐标)
  bellMinus3 = Rect:new(-620, -220, -460, -20), -- -3 钟区域 (转换后坐标)
  bellPlus1 = Rect:new(20, -410, 230, -150), -- +1 钟区域 (转换后坐标)
  to3 = Rect:new(-510, 130, -320, 370), -- 地图2到地图3的传送区域 (转换后坐标)
  deer = Rect:new(-421,53,70,390), -- 白鹿雕像区域
  petal3 = Rect:new(-260,-260,-70,-70), -- 新增：地图2的花瓣3区域 (转换后坐标)
  
  -- 场景2
  useShovel = Rect:new(-150, -370, 200, -82), -- 使用铲子区域 (转换后坐标)
  to5 = Rect:new(leftX, topY-100, rightX, topY), -- 地图4到地图5的传送区域 (修改为底部区域)
  to6 = Rect:new(-510, 130, -320, 370), -- 地图5到地图6的传送区域 (转换后坐标)
  petal1 = Rect:new(-320,20,-100,230), -- 花瓣1区域 (转换后坐标)
  tudui = Rect:new(-337,-326,-191,-187), -- 新增：地图5的土堆区域 (转换后坐标)
  
  -- 场景3
  seed = Rect:new(-97,-327,208,-54), -- 种子拾取区域 (转换后坐标)
  to8 = Rect:new(leftX, topY-100, rightX, topY), -- 地图7到地图8的传送区域 (修改为底部区域)
  to9 = Rect:new(-510, 130, -320, 370), -- 地图8到地图9的传送区域 (转换后坐标)
  petal2 = Rect:new(-320,20,-100,230), -- 花瓣2区域 (转换后坐标)
  plant = Rect:new(-380,-180,-180,-300), -- 种植区域 (转换后坐标)
}

-- 检查物品是否在背包
local function inBag(item) -- 判断背包里是否有指定物品
  for _, v in ipairs(bag) do if v == item then return true end end -- 遍历背包
  return false -- 如果没找到，返回 false
end

-- 初始化节点
local mapNode = Node() -- 地图节点
mapNode:addTo(Game) -- 挂载到游戏主节点
local bagNode = Node() -- 背包节点
bagNode:addTo(Game) -- 挂载到游戏主节点


local audio = require("Audio")

local bgMusic  -- 声明变量

-- 在游戏开始时播放
bgMusic = audio:play("audio/bgm.mp3", true)
-- 第二个参数 true 表示循环播放


-- local sound = audio:play("录音文件路径.mp3", true)  

-- 花瓣计数标签
local petalLabel = Label("sarasa-mono-sc-regular", 40)
petalLabel.x = leftX + 100
petalLabel.y = topY - 50
petalLabel.text = "花瓣: 0"
petalLabel.color = Color(0xffffffff) -- 使用十六进制格式设置颜色 (RGBA)
petalLabel.visible = false -- 初始不显示
petalLabel:addTo(Game)

-- 对话框
local dialogLabel = Label("sarasa-mono-sc-regular", 30)
dialogLabel.x = centerX
dialogLabel.y = centerY - 300
dialogLabel.alignment = "Center"
dialogLabel.width = 1000
dialogLabel.height = 200
dialogLabel.text = ""
dialogLabel.color = Color(0xffffffff) -- 使用十六进制格式设置颜色 (RGBA)
dialogLabel.backgroundColor = Color(0x80000000) -- 使用十六进制格式设置背景色 (RGBA)
dialogLabel.visible = false
dialogLabel:addTo(Game)

-- 清除节点
local function clearNode(parent) -- 清空指定节点的所有子节点
  parent:removeAllChildren()
end

-- 前向声明
local onMapClick, renderMap, renderBag, useItem -- 提前声明后面定义的函数

-- 显示对话框
local function showDialog(text)
  dialogLabel.text = text
  dialogLabel.visible = true
end

-- 隐藏对话框
local function hideDialog()
  dialogLabel.visible = false
end

-- 渲染地图函数
function renderMap() -- 地图渲染
  clearNode(mapNode) -- 清除当前地图显示
  
  -- 根据场景和地图确定背景图名称
  local bgName = "di" -- 默认
  if map == 2 then
    bgName = "xian"
  elseif map == 3 or map == 6 or map == 9 then
    bgName = "dong"
  elseif map == 5 then
    -- 地图5根据种子是否种植显示不同的背景
    if seedPlaced then
      bgName = "gu1"
    else
      bgName = "gu2"
    end
  elseif map == 4 then
    bgName = "di" -- 地图4使用dong背景
  elseif map == 8 then
    bgName = "hou"
  elseif map == 7 then
    bgName = "di" -- 地图7使用dong背景
	elseif map == 10 then
	  bgName = "end"
  end
  
  local bg = Sprite("picture/" .. bgName .. ".png") -- 创建地图背景精灵
  bg.x = -180
  bg.y = 0
  bg:addTo(mapNode) -- 显示背景
  
  -- 添加背景点击事件（使用屏幕坐标）
  bg:onTapped(function(touch) 
    -- 将触摸点转换为屏幕坐标
    local screenPos = bg:convertToWorldSpace(touch.location)
    local screenX, screenY = screenPos.x, screenPos.y
    
    if selectedItem then
      useItem(screenX, screenY)
    else
      onMapClick(screenX, screenY)
    end
  end)
  
  -- 显示 NPC（场景1地图1）
  if scene == 1 and map == 1 then
    local npc = Sprite("picture/ren.png") -- 创建 NPC 精灵
    npc.x, npc.y = 0, 0 -- 设置 NPC 坐标
    npc:addTo(mapNode) -- 显示 NPC
    
    -- 添加NPC点击事件（使用屏幕坐标）
    npc:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = npc:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示铲子（场景1地图2）- 只在未拾取时显示
  if scene == 1 and map == 2 and not shovelPicked and not inBag("changzi") then
    local shovel = Sprite("picture/changzi.png") -- 创建铲子精灵
    shovel.x, shovel.y = -370, -50 -- 设置铲子坐标 (转换后)
    shovel:addTo(mapNode) -- 显示铲子
    
    -- 添加铲子点击事件（使用屏幕坐标）
    shovel:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = shovel:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示钟（场景1地图2和场景2地图5）
  if (scene == 1 and map == 2) or (scene == 2 and map == 5) then
    local bellMinus3 = Sprite("picture/-3.png") -- 创建-3钟精灵
    bellMinus3.x, bellMinus3.y = -540, -120 -- 设置钟坐标 (转换后)
    bellMinus3:addTo(mapNode) -- 显示钟
    
    bellMinus3:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = bellMinus3:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
    
    local bellPlus1 = Sprite("picture/+1.png") -- 创建+1钟精灵
    bellPlus1.x, bellPlus1.y = 135, -300 -- 设置钟坐标 (转换后)
    bellPlus1:addTo(mapNode) -- 显示钟
    
    bellPlus1:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = bellPlus1:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示白鹿雕像或白鹿（场景1地图3或场景3地图3）
  if map == 3 then
    if whiteDeer then
      local deer = Sprite("picture/bailu.png") -- 创建白鹿精灵
      deer.x, deer.y = -195, 250 -- 设置白鹿坐标
      deer:addTo(mapNode) -- 显示白鹿
      
      -- 添加白鹿点击事件（使用屏幕坐标）
      deer:onTapped(function(touch) 
        -- 将触摸点转换为屏幕坐标
        local screenPos = deer:convertToWorldSpace(touch.location)
        local screenX, screenY = screenPos.x, screenPos.y
        
        if selectedItem then
          useItem(screenX, screenY)
        else
          onMapClick(screenX, screenY)
        end
      end)
    else
      local statue = Sprite("picture/shilu.png") -- 创建白鹿雕像精灵
      statue.x, statue.y = -195,280 -- 设置雕像坐标
      statue:addTo(mapNode) -- 显示雕像
      
      -- 添加雕像点击事件（使用屏幕坐标）
      statue:onTapped(function(touch) 
        -- 将触摸点转换为屏幕坐标
        local screenPos = statue:convertToWorldSpace(touch.location)
        local screenX, screenY = screenPos.x, screenPos.y
        
        if selectedItem then
          useItem(screenX, screenY)
        else
          onMapClick(screenX, screenY)
        end
      end)
    end
  end
  
  -- 显示种子袋（场景3地图7）- 只在未拾取时显示
  if scene == 3 and map == 7 and not seedPicked and not inBag("zhong") then
    local seedBag = Sprite("picture/zhong.png") -- 创建种子袋精灵
    seedBag.x, seedBag.y = 46, -202 -- 设置种子袋坐标 (转换后)
    seedBag:addTo(mapNode) -- 显示种子袋
    
    -- 添加种子袋点击事件（使用屏幕坐标）
    seedBag:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = seedBag:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示花瓣（场景2地图6）
  if scene == 2 and map == 6 and not petal1Collected then
    local flower = Sprite("picture/flower.png") -- 创建花瓣精灵
    flower.x, flower.y = -320, 50 -- 场景2地图6的花瓣位置 (转换后)
    flower:addTo(mapNode) -- 显示花瓣
    
    -- 添加花瓣点击事件（使用屏幕坐标）
    flower:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = flower:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示花瓣（场景3地图9）
  if scene == 3 and map == 9 and not petal2Collected then
    local flower = Sprite("picture/flower.png") -- 创建花瓣精灵
    flower.x, flower.y = -320, 50 -- 场景3地图9的花瓣位置 (转换后)
    flower:addTo(mapNode) -- 显示花瓣
    
    -- 添加花瓣点击事件（使用屏幕坐标）
    flower:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = flower:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 显示第三片花瓣（场景1地图2，种子种植后）
  if scene == 1 and map == 2 and seedPlaced and not petal3Collected then
    local flower = Sprite("picture/flower.png") -- 创建花瓣精灵
    flower.x, flower.y = -250,-250 -- 地图2的花瓣位置 (转换后)
    flower:addTo(mapNode) -- 显示花瓣
    
    -- 添加花瓣点击事件（使用屏幕坐标）
    flower:onTapped(function(touch) 
      -- 将触摸点转换为屏幕坐标
      local screenPos = flower:convertToWorldSpace(touch.location)
      local screenX, screenY = screenPos.x, screenPos.y
      
      if selectedItem then
        useItem(screenX, screenY)
      else
        onMapClick(screenX, screenY)
      end
    end)
  end
  
  -- 更新花瓣计数显示
  petalLabel.text = "花瓣: " .. petals
  petalLabel.visible = true

	if map == 3 then
    if whiteDeer then
        -- 显示白鹿
        local deer = Sprite("picture/bailu.png")
        deer.x, deer.y = -195, 250
        deer:addTo(mapNode)
        
        -- 添加点击事件
        deer:onTapped(function(touch) 
            local screenPos = deer:convertToWorldSpace(touch.location)
            local screenX, screenY = screenPos.x, screenPos.y
            if selectedItem then
                useItem(screenX, screenY)
            else
                onMapClick(screenX, screenY)
            end
        end)
    else
        -- 显示雕像
        local statue = Sprite("picture/shilu.png")
        statue.x, statue.y = -195,280
        statue:addTo(mapNode)


        local function waitAndExecute(seconds, callback)
    local delayNode = Node()
    delayNode:addTo(Game)
    
    delayNode:runAction(Sequence(
        Delay(seconds),
        function()
            callback()
            delayNode:removeFromParent()
        end
    ))
end
        -- 添加点击事件
        statue:onTapped(function(touch) 
            local screenPos = statue:convertToWorldSpace(touch.location)
            local screenX, screenY = screenPos.x, screenPos.y
            
            -- 当有3片花瓣时点击雕像
            if petals >= 3 then
								audio:play("audio/dll.wav")
                whiteDeer = true -- 将雕像变为白鹿
								renderMap() -- 重新渲染以显示白鹿
								dialogLabel.x = centerX - 200  -- 水平居中
								dialogLabel.y = centerY - 100  -- 垂直位置向上移动100像素
								showDialog("人类，谢谢你唤醒了我，为了感谢你，我将净化城市周围的灾难！（恭喜游戏通关！）")
            else
                if selectedItem then
                    useItem(screenX, screenY)
                else
                    onMapClick(screenX, screenY)
                end
            end
        end)
    end
end
end

-- 渲染背包函数
function renderBag() -- 背包渲染
  clearNode(bagNode) -- 清空背包节点
  returnBtnAdded = false -- 重置返回按钮状态
  
  -- 背包背景
  local bagBg = Sprite("picture/ui.png") -- 创建背包背景精灵
  if bagBg then
    bagBg.x = rightX - backpackWidth/2
    bagBg.y = centerY
    bagBg:addTo(bagNode) -- 添加背景到背包节点
  else
    print("背包背景图片加载失败: picture/ui.png")
  end
  
  local rowH = screenHeight / 4 -- 每个背包格子的高度
  
  -- 返回按钮（当第一个铃铛被放置时显示）
  if bellPlaced and not inBag("lin1")  then
    local returnBtn = Sprite("picture/fanhui.png") -- 创建返回按钮精灵
    if returnBtn then
      returnBtn.x = rightX - backpackWidth/2
      returnBtn.y = topY - rowH/2 -- 第一个位置
      returnBtn:addTo(bagNode) -- 添加到背包节点
      
      returnBtn:onTapped(function() -- 返回按钮点击事件
        scene = 1
        map = 2
        bellPlaced = false
        table.insert(bag, "lin1") -- 取回第一个铃铛
        selectedItem = nil -- 取消任何选中的物品
        renderMap() -- 重新渲染地图
        renderBag() -- 重新渲染背包
      end)
      
      returnBtnAdded = true
    else
      print("返回按钮图片加载失败: picture/fanhui.png")
    end
  end

  -- 计算背包物品起始位置（如果有返回按钮，则从第二格开始）
  local startIndex = returnBtnAdded and 1 or 0
  
  for i, item in ipairs(bag) do -- 遍历背包里的物品
    local imgPath = "picture/" .. item .. ".png"
    local spr = Sprite(imgPath) -- 创建背包物品精灵
    
    if spr then
      spr.x = rightX - backpackWidth/2 -- 设置物品 X 坐标（靠右）
      -- 如果有返回按钮，物品位置向下偏移一格
      spr.y = topY - (i + startIndex - 0.5) * rowH -- 设置物品 Y 坐标（竖排间隔）
      spr:addTo(bagNode) -- 添加到背包节点
      
      -- 添加点击事件（选择/取消选择物品）
      spr:onTapped(function()
        if selectedItem == item then
          -- 如果点击的是已选中的物品，则取消选择
          selectedItem = nil
          renderBag() -- 重新渲染背包以更新状态
        else
          -- 否则选择该物品
          selectedItem = item
          renderBag() -- 重新渲染背包以更新状态
        end
      end)
      
      -- 如果这是选中的物品，添加"使用中"标签
      if selectedItem == item then
        local usingLabel = Label("sarasa-mono-sc-regular", 25)
        usingLabel.text = "使用中"
        usingLabel.color = Color(0xff0000ff) -- 红色
        usingLabel.x = spr.x
        usingLabel.y = spr.y - 40 -- 放在物品下方
        usingLabel:addTo(bagNode)
      end
    else
      print("创建背包物品精灵失败: " .. imgPath)
    end
  end
end

-- 使用物品逻辑
function useItem(x, y)
  if not selectedItem then return end -- 没有选中的物品直接返回
  
  -- 场景1地图2：将第一个铃铛放到-3钟上
  if selectedItem == "lin1" and scene == 1 and map == 2 and zones.bellMinus3:contains(x, y) then
    -- 移除第一个铃铛
    for i, item in ipairs(bag) do
      if item == "lin1" then
        table.remove(bag, i)
        break
      end
    end
    
    audio:play("audio/lind.wav")
    -- 进入场景2地图5
    scene = 2
    map = 5
    bellPlaced = true -- 标记第一个铃铛已放置
    selectedItem = nil -- 使用后取消选中
    renderMap() -- 重新渲染地图
    renderBag() -- 重新渲染背包
  end
  if selectedItem == "lin1" and scene == 1 and map == 2 and zones.bellMinus3:contains(x, y) then
    -- 移除第一个铃铛
    for i, item in ipairs(bag) do
      if item == "lin1" then
        table.remove(bag, i)
        break
      end
    end
    
    audio:play("audio/lind.wav")
    -- 进入场景2地图5
    scene = 2
    map = 5
    bellPlaced = true -- 标记第一个铃铛已放置
    selectedItem = nil -- 使用后取消选中
    renderMap() -- 重新渲染地图
    renderBag() -- 重新渲染背包
  end
  if selectedItem == "lin1" and islin2 == 1 and scene == 1 and map == 2 and zones.bellPlus1:contains(x, y) then
    -- 移除第一个铃铛
    for i, item in ipairs(bag) do
      if item == "lin1" then
        table.remove(bag, i)
        break
      end
    end
		
    audio:play("audio/lind.wav")
    -- 进入场景3地图8
    scene = 3
    map = 8
		bellPlaced = true
    selectedItem = nil -- 使用后取消选中
    renderMap() -- 重新渲染地图
    renderBag() -- 重新渲染背包
  end

  -- 场景2地图5：将第一个铃铛放到+1钟上
  if selectedItem == "lin2" and scene == 2 and map == 5 and zones.bellPlus1:contains(x, y) then
    -- 移除第一个铃铛
    for i, item in ipairs(bag) do
      if item == "lin2" then
        table.remove(bag, i)
        break
      end
    end
		renderBag()
    islin2 = 1;
		
    audio:play("audio/lind.wav")
  end

  -- 场景2地图4：使用铲子
  if selectedItem == "changzi" and scene == 2 and map == 4 and zones.useShovel:contains(x, y) then
    -- 移除铲子
    for i, item in ipairs(bag) do
      if item == "changzi" then
        table.remove(bag, i)
        break
      end
    end
    audio:play("audio/tu.mp3")
    -- 添加第二个铃铛
    table.insert(bag, "lin2")
    selectedItem = nil -- 使用后取消选中
    renderBag() -- 重新渲染背包
  end
  
  -- 场景2地图5：在土堆种植种子
  if selectedItem == "zhong" and scene == 2 and map == 5 and zones.tudui:contains(x, y) then
    -- 移除种子袋
    for i, item in ipairs(bag) do
      if item == "zhong" then
        table.remove(bag, i)
        break
      end
    end
    
    seedPlaced = true -- 标记种子已种植
    selectedItem = nil -- 使用后取消选中
    
    -- 切换到gu2背景
    renderMap() -- 重新渲染地图
    renderBag() -- 重新渲染背包
  end
end

-- 地图点击逻辑
function onMapClick(x, y)
  -- 打印点击坐标到控制台
  print("点击位置: (" .. x .. ", " .. y .. ")")
  
  -- 场景1地图1：NPC对话
  if scene == 1 and map == 1 and zones.npc1:contains(x, y) then
    dialogStep = dialogStep + 1 -- 对话推进
    dialogLabel.x = centerX - 100  -- 水平居中
		dialogLabel.y = centerY - 100 --
    if dialogStep == 1 then
      showDialog("古人：郭璞大人，最近城池边上又出现了瘟疫，人民也是饥寒交迫，建城困难啊")
		elseif dialogStep == 2 then
    showDialog("古人：据说用三片花瓣来祭祀石洞里的鹿神像会出现祥瑞，希望可以解救我们吧")
    elseif dialogStep == 3 then
      showDialog("古人：我还在我脚底下的坑里发现了一个铃铛，和一张纸，这莫非是远古的遗物？")
    elseif dialogStep == 4 then
      showDialog("古人：上面写着，这个铃铛可以通过在座钟上敲响来改变时间线")
    elseif dialogStep == 5 then
      showDialog("古人：时间线分为3,6,9,对应过去现在和未来，而我们正处于5这个时段，")
    elseif dialogStep == 6 then
      showDialog("古人：上面还写着不同时间线的铃铛之力可以相互叠加，不知该如何使用")
    elseif dialogStep == 7 then
      hideDialog()
      if not inBag("lin1") then
        table.insert(bag, "lin1") -- 添加第一个铃铛到背包
        renderBag() -- 重新渲染背包
      end
    end
  end
  
  -- 地图切换逻辑
  if map == 1 and zones.to2:contains(x, y) then 
    map = 2 -- 地图1 -> 地图2
  elseif map == 2 and zones.bottom:contains(x, y) then 
    map = 1 -- 地图2 -> 地图1
  elseif map == 2 and zones.to3:contains(x, y) then 
    map = 3 -- 地图2 -> 地图3
  elseif map == 3 and zones.bottom:contains(x, y) then 
    map = 2 -- 地图3 -> 地图2
  end
  
  -- 场景2地图切换
  if scene == 2 then
    if map == 5 and zones.bottom:contains(x, y) then 
      map = 4 -- 地图5 -> 地图4 (使用底部区域)
    elseif map == 4 and zones.to5:contains(x, y) then 
      map = 5 -- 地图4 -> 地图5 (使用to5区域)
    elseif map == 5 and zones.to6:contains(x, y) then 
      map = 6 -- 地图5 -> 地图6
    elseif map == 6 and zones.bottom:contains(x, y) then 
      map = 5 -- 地图6 -> 地图5
    end
  end
  
  -- 场景3地图切换
  if scene == 3 then
    if map == 8 and zones.bottom:contains(x, y) then 
      map = 7 -- 地图8 -> 地图7 (使用底部区域)
    elseif map == 7 and zones.to8:contains(x, y) then 
      map = 8 -- 地图7 -> 地图8 (使用to8区域)
    elseif map == 8 and zones.to9:contains(x, y) then 
      map = 9 -- 地图8 -> 地图9
    elseif map == 9 and zones.bottom:contains(x, y) then 
      map = 8 -- 地图9 -> 地图8
    end
  end
  
  -- 拾取铲子（场景1地图2）- 标记为已拾取
  if scene == 1 and map == 2 and zones.pickupShovel:contains(x, y) and not inBag("changzi") and not shovelPicked then
    table.insert(bag, "changzi") -- 添加铲子到背包
    shovelPicked = true -- 标记铲子已拾取
    renderBag() -- 重新渲染背包
  end
  
  -- 拾取种子袋（场景3地图7）- 标记为已拾取
  if scene == 3 and map == 7 and zones.seed:contains(x, y) and not inBag("zhong") and not seedPicked then
    table.insert(bag, "zhong") -- 添加种子袋到背包
    seedPicked = true -- 标记种子袋已拾取
    renderBag() -- 重新渲染背包
  end
  
  -- 拾取花瓣1（场景2地图6）
  if scene == 2 and map == 6 and zones.petal1:contains(x, y) and not petal1Collected then
    petal1Collected = true
    petals = petals + 1
    renderMap() -- 重新渲染地图使花瓣消失
  end
  
  -- 拾取花瓣2（场景3地图9）
  if scene == 3 and map == 9 and zones.petal2:contains(x, y) and not petal2Collected then
    petal2Collected = true
    petals = petals + 1
    renderMap() -- 重新渲染地图使花瓣消失
  end
  
  -- 拾取花瓣3（场景1地图2）
  if scene == 1 and map == 2 and seedPlaced and zones.petal3:contains(x, y) and not petal3Collected then
    petal3Collected = true
    petals = petals + 1
    renderMap() -- 重新渲染地图使花瓣消失
  end
  
 
  
  renderMap() -- 重新渲染地图
end

-- ==== 开始界面 ====
local startBg = Sprite("picture/menu.png") -- 创建开始界面背景
startBg.x = centerX
startBg.y = centerY
startBg:addTo(Game)

-- 开始按钮
local startBtn = Sprite("picture/gamestart.png") -- 创建开始按钮
startBtn.x = centerX
startBtn.y = centerY
startBtn:addTo(Game) -- 挂载按钮到主节点

-- 按钮标签
local btnLabel = Label("sarasa-mono-sc-regular", 40)
btnLabel.x = centerX
btnLabel.y = centerY
btnLabel.text = "开始游戏"
btnLabel.color = Color(0x000000ff) -- 使用十六进制格式设置颜色 (RGBA)
btnLabel.alignment = "Center"
btnLabel:addTo(Game)

-- 开始按钮点击事件
startBtn:onTapped(function() 
  -- 移除开始界面元素
  startBg:removeFromParent()
  startBtn:removeFromParent()
  btnLabel:removeFromParent()
  
  -- 初始化游戏状态
  scene, map = 1, 1 -- 进入场景1地图1
  dialogStep = 0
  petals = 0
  whiteDeer = false
  bellPlaced = false
  seedPlaced = false -- 重置种子种植状态
  bag = {}
  selectedItem = nil -- 重置选中的物品
  
  -- 重置物品拾取状态
  shovelPicked = false
  seedPicked = false
  
  -- 重置花瓣收集状态
  petal1Collected = false
  petal2Collected = false
  petal3Collected = false
  
  -- 渲染游戏内容
  renderMap()
  renderBag()
end)

return Game -- 返回游戏节点