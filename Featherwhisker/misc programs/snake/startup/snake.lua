--FIX: makes it easy to update
shell.run("cd startup")

local mon = peripheral.wrap("top")

local coinNames = {
    ["minecraft:diamond"] = true,
    ["minecraft:emerald"] = true,
	["minecraft:netherite_ingot"] = true,
	["minecraft:nether_star"] = true
}

mon.setBackgroundColour(colours.black)
mon.clear()

mon.setTextScale(0.5)
--Width and height of screen
local w,h = mon.getSize()

local image = {{{"\32\32\32\32\32\32\32\32Drop\32a\32","000000000000000","fffbbbfffffffff"},{"\32\32\32\32\32\32\32\32Diamond","000000000000000","ffb000bffffffff"},{"\32\32\32\32\32\32\32\32to\32play","000000000000000","ff03009ffffffff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","fb300037fffffff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b00300997ffffff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b00300997f444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b09339997f444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","f7999997f44444f"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","f7999997ff444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","ffb9999ffff4fff"}},
               {{"\32\32\32\32\32\32\32\32Drop\32a\32","000000000000000","fffbbbfffffffff"},{"\32\32\32\32\32\32\32\32Diamond","000000000000000","ffb000bffffffff"},{"\32\32\32\32\32\32\32\32to\32play","000000000000000","ff03009ffffffff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","fb300037fffffff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b00300997f444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b00300997f444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","b0933999744444f"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","f7999997ff444ff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","f7999997fff4fff"},{"\32\32\32\32\32\32\32\32\32\32\32\32\32\32\32","000000000000000","ffb9999ffffffff"}}} --BIMG of the diamond advertisement

local waitScreen = {
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","",""},
	{"","\127","","","","","","","","","","","","\127",""},
	{"","\127","","S","","N","","A","","K","","E","","\127",""},
	{"","\127","","","","","","","","","","","","\127",""},
	{"","","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","I","n","s","e","r","t","","","","",""},
	{"","","","","","D","i","a","m","o","n","d","","",""}
}
local deadScreen = {
	{"","","","D","","e","","a","","d","","!","","",""},
	{"","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127","\127",""},
	{"","S","c","o","r","e",":","","","","","","","",""},
	{"","H","i","-","s","c","o","r","e",":","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""},
	{"","","","","","","","","","","","","","",""}
}
local event, side, x, y
-- Setup the screen
screen = {}
for x=1,w-2 do
    screen[x] = {}
    for y=1,h-2 do
        screen[x][y] = 0 --0 = none/ 1 = fruit/ 2 = snake
    end
end
function drawPicture(screen)
    mon.setBackgroundColour(colours.black)
	mon.setTextColor(colors.lime)
    mon.clear()
	for y=1,h do
		for x=1,w do
			mon.setCursorPos(x,y)
			mon.write(screen[y][x])
		end
	end
end
local gameSpeed = 0.25

local fruits = 0
local score = 0

local snakeposis = {}
local snake = {}

local timer = 0
local frameN = 1

local isButtonPressed = false
local lastButton

local function buttons_det(numb) --Reversed for how the new arcade works
    if isButtonPressed then
        if (x >= 1 and x <= 10) and (y >= 1 and y <= 2) then --down
            if (numb) then return 1 end
            return "down"
        end
        if (x >= 1 and x <= 2*2) and (y >= 4 and y <= 8) then --right
            if (numb) then return 2 end
            return "right"
        end
        if (x >= 13 and x <= 15) and (y >= 4 and y <= 8) then --left
            if (numb) then return 3 end
            return "left"
        end
        if (x >= 1 and x <= 10) and (y >= 9 and y <= 10) then --up
            if (numb) then return 4 end
            return "up"
        end
    else
        return nil
    end
end

local function add_fruit()
    local x = math.random(1, w-2)
    local y = math.random(1, h-2)
    repeat
        x = math.random(1, w-2)
        y = math.random(1, h-2)    
    until screen[x][y] == 0
    screen[x][y] = 1
end

local function snake_update()
    local but = buttons_det()
    if but ~= nil then
        lastButton = but
    else
        but = lastButton
    end
	if (but == "up" and lastButton == "down") or (but == "down" and lastButton == "up") or (but == "left" and lastButton == "right") or (but == "right" and lastButton == "left") then
		but = lastButton
		print("invalid!")
	end

    if but ~= nil then
        snakepos = {x = snake.x, y = snake.y}
        table.insert(snakeposis, snakepos)
        screen[snake.x][snake.y] = 2
        if but == "up" then
            snake.y = snake.y + 1
        end
        if but == "down" then
            snake.y = snake.y - 1
        end
        if but == "left" then
            snake.x = snake.x + 1
        end
        if but == "right" then
            snake.x = snake.x - 1
        end
        if snake.x>(w-2) then
            snake.x = 1
        end
        if snake.x<1 then
            snake.x = w-2
        end
        if snake.y>(h-2) then
            snake.y = 1
        end
        if snake.y<1 then
            snake.y = h-2
        end
        if screen[snake.x][snake.y] == 1 then
            score = score + 1
            add_fruit()
        end
        if screen[snake.x][snake.y] == 2 then
			local hiscore
			pcall(function()
				local scorefile = fs.open("/snakescore.dat", "r")
				hiscore = tonumber(scorefile.readAll())
				scorefile.close()
				if not hiscore then
					hiscore = 0
				end
				if score > hiscore then
					local scorefile = fs.open("/snakescore.dat", "w")
					scorefile.write(tostring(score))
					scorefile.close()
				end
			end)
			if not hiscore then
				hiscore = "Err"
			end
			drawPicture(deadScreen)
            mon.setCursorPos(9, 3)
            mon.write(tostring(score)) -- DEATH
			mon.setCursorPos(12, 4)
			mon.write(tostring(hiscore))
			if type(hiscore) ~= "string" and score>hiscore then
				mon.setCursorPos(2, 5)
				mon.write("New hi-score!")
			end
            os.sleep(5)
            turtle.select(1)
            return true
        end
        if (#snakeposis > score+3) then
            screen[snakeposis[1].x][snakeposis[1].y] = 0
            table.remove(snakeposis, 1)
        end
    end
    
    screen[snake.x][snake.y] = 2
end

local function update()
    return snake_update()
end

local function buttons_draw()
	mon.setCursorPos(8, 1)
	if lastButton ~= "up" then
		mon.write("^") --up
	end
    mon.setCursorPos(1, 5)
	if lastButton ~= "left" then
		mon.write("<") --left
	end
    mon.setCursorPos(15, 5)
	if lastButton ~= "right" then
		mon.write(">") --right
	end
    mon.setCursorPos(8, 10)
	if lastButton ~= "down" then
		mon.write("v") --down
	end
end

local function draw()
    mon.clear()
    local text = "Sc:" .. score
    mon.setCursorPos(1, 1)
    mon.write(text)
	mon.setBackgroundColor(colors.black)
	buttons_draw()
	local draw = {}
    for y=2,h-1 do
		draw[y] = {"","",""}
        for x=2,w-1 do
            if (screen[x-1][y-1] == 1) then --fruit
                --mon.setCursorPos(x, y)
				--mon.setBackgroundColour(colors.lime)
                --mon.write(" ")
				--mon.setBackgroundColour(colors.black)
				draw[y][1] = draw[y][1].." "
				draw[y][2] = draw[y][2].."5"
				draw[y][3] = draw[y][3].."5"
            end
            if (screen[x-1][y-1] == 2) then --snake
                --mon.setCursorPos(x, y)
                --mon.write("\127")
				draw[y][1] = draw[y][1].."\127"
				draw[y][2] = draw[y][2].."5"
				draw[y][3] = draw[y][3].."f"
            end
			if (screen[x-1][y-1] == 0) then
				--mon.setCursorPos(x, y)
				--mon.setBackgroundColour(colors.black)
				--mon.write(" ")
				draw[y][1] = draw[y][1].." "
				draw[y][2] = draw[y][2].."5"
				draw[y][3] = draw[y][3].."f"
			end
			mon.setCursorPos(2, y)
			mon.blit(draw[y][1],draw[y][2],draw[y][3])
        end	
    end
end

local gameState = 0

local function waitUpdate()
    sleep()
    turtle.select(1)
    turtle.suck(1)
    if turtle.getItemDetail() then
        if coinNames[turtle.getItemDetail().name] then
            gameState = 1
            turtle.dropDown()
        else
            turtle.drop()
        end
    end
end

local function waitDraw()
	drawPicture(waitScreen)
	sleep()
end

local function refresh()
    while true do
        if gameState == 1 then --Main Game
            if update() then
				break
			end
            draw()
            os.sleep(gameSpeed)
        elseif gameState == 0 then --Wait
            waitUpdate()
            waitDraw()
        end
    end
end

local function click()
    local lx = 0
    local ly = 0
    while 1 do
        event, side, x, y = os.pullEvent("monitor_touch")
        if (lx == x and ly == y) then
            isButtonPressed = false
        else
            isButtonPressed = true
        end
        lx, ly = x, y
    end
end

local function init()
    --Clear the old game stuff
	gameState = 0
	lastButton = nil
	but = nil
	fruits = 0
	score = 0
	snakeposis = {}
	snake = {}
	-- Setup the screen
	mon.clear()
    screen = {}
    for x=1,w-2 do
        screen[x] = {}
        for y=1,h-2 do
            screen[x][y] = 0 --0 = none/ 1 = fruit/ 2 = snake
        end
    end

    snake = {
        x=math.floor(w/2),
        y=math.floor(h/2)
    }

    snakeposis = {}
    side = nil
    score = 0

    add_fruit()
    add_fruit()

    parallel.waitForAny(refresh, click) --Interchange between input pullevent and refresh function
end

while true do 
	init()
	sleep()
end

