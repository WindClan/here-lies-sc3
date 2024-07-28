--define the settings!
settings.define("audio.left",{
	description = "Table containing network IDs of the left channel speakers",
	default = {},
	type = "table"
})
settings.define("audio.right",{
	description = "Table containing network IDs of the right channel speakers",
	default = {},
	type = "table"
})
--non speakerlib stuff
local mon = term.current()
mon.setBackgroundColor(colors.pink)
mon.clear()
local mX,mY = mon.getSize()
local main = window.create(mon,1,2,mX,mY-1)
term.redirect(main)

--speakerlib stuff
local speakerlib = require("speakerlib")
local ls = settings.get("audio.left")
local rs = settings.get("audio.right")
local url
local volume = 1

--terminal stuff
local function fakeError(msg)
	local textColor = main.getTextColor()
	main.setTextColor(colors.red)
	print(msg)
	main.setTextColor(textColor)
end


local commands = {}


function parse(command)
	local comtable = {}
	for i in string.gmatch(command, "%S+") do
		table.insert(comtable,i)
	end
	if comtable[1] == nil then
		comtable[1] = command
	end

	local toRun = comtable[1]

	if commands[toRun] then
		table.remove(comtable, 1)
		if commands[toRun].callback then
			local ok, res, msg = pcall(commands[toRun].callback, toRun, comtable)

			if ok then
				res = res or 0

				if res ~= 0 then
					fakeError("Non 0 exit code"..(msg and ": "..tostring(msg) or ""))
				else
					if msg then
						print(tostring(msg))
					end
				end
			else
				fakeError("Error: "..tostring(res))
			end
		else
			fakeError("Internal error: Command missing callback!")
		end
	elseif #toRun > 0 then
		fakeError("Command not found!")
	end
end


local function addCommand(command, callback, description)
	commands[command] = {
		command = command:lower(),
		callback = callback,
		description = description
	}
end

local function genHelp()
	local str = ""

	for k,v in pairs(commands) do
		str = str .. k .. (v.description and " - "..v.description or "") .. "\n"
	end

	return str
end

addCommand("help", function(cmd, args)
	print(genHelp())
	return 0
end, "Help")

addCommand("speaker", function(cmd, args)
	if args[1] == "add" then
		if args[2] == "left" then
			table.insert(ls,args[3])
			settings.set("audio.left",ls)
		elseif args[2] == "right" then
			table.insert(rs,args[3])
			settings.set("audio.right",rs)
		else
			return 1, "Please specify a speaker side"
		end
		settings.save()
	elseif args[1] == "resetAll" then
		ls = {}
		rs = {}
		settings.set("audio.left",ls)
		settings.set("audio.right",rs)
		settings.save()
	else
		return 1, "Invalid speaker command!"
	end
	return 0
end, "Speaker")

addCommand("meta", function(cmd, args)
	if not speakerlib.isMdiskPresent() then
		return 1, "No disk"
	end

	local meta = speakerlib.getSongMetadata()

	if meta then
		print(textutils.serialize(meta))
	else
		return 1, "Error: no meta"
	end

	return 0
end, "Get disk meta")

local cliOpen = false

--playing message things
local nowPlaying = ""
local displayString = "Now playing: "

--the main loops
function audioPlayer()
	while true do
		local success,response = pcall(function()
			if speakerlib.isMdiskPresent() then
				local meta = speakerlib.getSongMetadata()
				nowPlaying = meta.artist.." - "..meta.song.." ("..meta.year..")"
				if speakerlib.isMdiskStereo() then
					speakerlib.playDfpwmStereo("disk/left.dfpwm", "disk/right.dfpwm", ls, rs, volume)
				else
					speakerlib.playDfpwmMono("disk/left.dfpwm", volume)
				end
			elseif url then
				nowPlaying = "DFPWM url"
				speakerlib.playDfpwmMono(url,volume)
				url = nil
			end
		end)
		nowPlaying = ""
		if not success then
			sleep(5)
		end
		sleep(4/20)
	end
end

function discEjectHandler()
	while true do
		os.pullEvent("disk_eject")
		nowPlaying = ""
	end
end


function ui()
	_ = fs.open("/theme.json", "r")
	local theme = textutils.unserializeJSON(_.readAll())
	_.close()

	local ctrlHeld = false

	parallel.waitForAny(function()
		while true do
			parallel.waitForAny(function()
				if not cliOpen then
					term.setCursorBlink(false)
					term.setTextColor(colors.black)
					term.setBackgroundColor(colors.pink)

					local w,h = term.getSize()

					while true do
						local meta = speakerlib.getSongMetadata()

						local function writeAt(y, text)
							term.setBackgroundColor(colors[theme[y]])
							term.setCursorPos(1,y)
							term.write(text)
						end

						local function writeCentered(y, text)
							term.setBackgroundColor(colors[theme[y]])
							term.setCursorPos(w/2-math.floor(#text/2+0.5),y)
							term.write(text)
						end

						for i=1,h do
							writeAt(i, (" "):rep(w))
						end

						if speakerlib.isMdiskPresent() then
							writeCentered(4, tostring(meta.artist).." - "..tostring(meta.song))
							writeCentered(5, tostring(meta.album))
							writeCentered(6, tostring(meta.year))
						else
							writeCentered(4, "nothing :(")
						end

						sleep(0.1)
					end
				else
					term.setTextColor(colors.white)
					term.setBackgroundColor(colors.black)
					term.clear()
					term.setCursorPos(1,1)

					while true do
						term.write("> ")
						local command = read()
						parse(command)
						sleep()
					end
				end
				sleep()
			end, function()
				local prev = cliOpen
				while true do
					if prev ~= cliOpen then return end
					sleep()
				end
			end, function()
				local w,h = mon.getSize()
				local function writeCentered(y, text)
					mon.setCursorPos(w/2-math.floor(#text/2+0.5),y)
					mon.write(text)
				end
				local function writeAt(y, text)
					mon.setCursorPos(1,y)
					mon.write(text)
				end

				while true do
					local px, py = mon.getCursorPos()
					local text = #nowPlaying > 0 or "nothing :("
					mon.setCursorPos(1,1)
					mon.setTextColor(colors.black)
					mon.setBackgroundColor(colors.white)

					local meta = speakerlib.getSongMetadata()

					-- im sorry
					writeAt(1, (" "):rep(w))
					writeCentered(
						1,
						displayString..(speakerlib.isMdiskPresent() and (meta and (tostring(meta.artist).." - "..tostring(meta.song)) or "nothing") or "nothing")
					)
					mon.setCursorPos(px, py)

					sleep(0.1)
				end
			end)
			sleep()
		end
	end, function()
		while true do
			local ev, key = os.pullEvent()
			if ev == "key" then
				if key == keys.leftCtrl then
					ctrlHeld = true
				elseif key == keys.q and ctrlHeld then
					cliOpen = not cliOpen
				end
			elseif ev == "key_up" then
				if key == keys.leftCtrl then
					ctrlHeld = false
				end
			end
		end
	end)
end

function terminal()
	local currentCommand = ""
	term.clear()
	term.setCursorPos(1,1)

	while true do
		--[[local event, key = os.pullEvent()
		if event =="key" then
			if key == keys.backspace then
				currentCommand = string.sub(currentCommand,1,#currentCommand-1)
				local x,y = term.getCursorPos()
				term.setCursorPos(x-1,y)
				term.write(" ")
				term.setCursorPos(x-1,y)
			elseif key == keys.enter then
				print("")
				parse(currentCommand)
				currentCommand = ""
				print(">")
			else
				currentCommand = currentCommand..key
				term.write(keys.getName(key))
			end
		end]]
		term.write("> ")
		local command = read()
		parse(command)
		sleep()
	end
end

parallel.waitForAny(ui,discEjectHandler,audioPlayer)