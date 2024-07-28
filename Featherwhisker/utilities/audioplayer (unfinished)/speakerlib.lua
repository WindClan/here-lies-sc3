local speakerlib = {}
local dfpwm = require("cc.audio.dfpwm")

--Speaker configuration
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

local ls = settings.get("audio.left")
local rs = settings.get("audio.right")
local function addLeftSpeaker(speaker)
	table.insert(ls,speaker)
	settings.set("audio.left",ls)
	settings.save()
end
local function addRightSpeaker(speaker)
	table.insert(rs,speaker)
	settings.set("audio.right",rs)
	settings.save()
end
local function getLeftSpeakers()
	return settings.get("audio.left")
end
local function getRightSpeakers()
	return settings.get("audio.right")
end
local function removeleftSpeaker(speaker)
	for i,v in pairs(ls) do
		if v == speaker then
			table.remove(ls,i)
			settings.set("audio.left",ls)
			settings.save()
			return true
		end
	end
	return false
end
local function removeRightSpeaker(speaker)
	for i,v in pairs(rs) do
		if v == speaker then
			table.remove(rs,i)
			settings.set("audio.right",rs)
			settings.save()
			return true
		end
	end
	return false
end
local function resetSpeakerTables()
	ls = {}
	rs = {}
	settings.set("audio.left",ls)
	settings.set("audio.right",rs)
	settings.save()
end

--Mono/Left
local buffer = nil
local function speakerFuncMono(speaker,volume)
	while not speaker.playAudio(buffer,volume) do
		os.pullEvent("speaker_audio_empty")
	end
end

local function getMonoFunctions(volume)
	local speakers = {}
	for i,v in pairs(peripheral.getNames()) do
		if peripheral.hasType(v,"speaker") then
			table.insert(speakers,function()
				speakerFuncMono(peripheral.wrap(v),volume)
			end)
		end
	end
	return speakers
end

local function setMonoBuffer(newbuffer)
	if newbuffer then
		buffer = newbuffer
	else
		error("Buffer can't be nil!")
	end
end

local function playDfpwmMono(path,volume)
	local decoder = dfpwm.make_decoder()
	local speakers = getMonoFunctions(volume)
	buffer = nil
	local chunk = ""
	local data
	if http.checkURL(path) then
		data = http.get(path, nil, true)
	else
		data = fs.open(path,"rb")
	end
	while chunk do
		chunk = data.read(0.5*1024)
		if not chunk then
			break
		end
		buffer = decoder(chunk)
		parallel.waitForAll(table.unpack(speakers))
	end
	data.close()
end




--Stereo
local buffer1 = nil

local function speakerFuncRight(speaker,volume)
	while not speaker.playAudio(buffer1,volume) do
		os.pullEvent("speaker_audio_empty")
	end
end

local function getStereoFunctions(leftSpeakers, rightSpeakers, volume)
	local speakers = {}
	local speakers1 = {}
	if leftSpeakers == nil or leftSpeakers == {} then
		leftSpeakers = ls
	end
	if rightSpeakers == nil or rightSpeakers == {} then
		rightSpeakers = rs
	end
	for i,v in pairs(leftSpeakers) do
		table.insert(speakers,function()
			speakerFuncMono(peripheral.wrap(v),volume)
		end)
		table.insert(speakers1,function()
			peripheral.wrap(v).stop()
		end)
	end
	for i,v in pairs(rightSpeakers) do
		table.insert(speakers,function()
			speakerFuncRight(peripheral.wrap(v),volume)
		end)
		table.insert(speakers1,function()
			peripheral.wrap(v).stop()
		end)
	end
	return speakers, speakers1
end

local function setStereoBuffers(leftbuffer, rightbuffer)
	if leftbuffer and rightbuffer then
		buffer = leftbuffer
		buffer1 = rightbuffer
	else
		error("Buffer can't be nil!")
	end
end

local function playDfpwmStereo(path,path1,ls,rs,volume)
	local decoder = dfpwm.make_decoder()
	local decoder1 = dfpwm.make_decoder()
	local speakers = getStereoFunctions(ls,rs,volume)
	buffer = nil
	buffer1 = nil
	local chunk = ""
	local chunk1 = ""
	local data
	local data1
	if http.checkURL(path) then
		data = http.get(path, nil, true)
		data1 = http.get(path1, nil, true)
	else
		data = fs.open(path,"rb")
		data1 = fs.open(path1,"rb")
	end
	while chunk and chunk1 do
		chunk = data.read(0.5*1024)
		chunk1 = data1.read(0.5*1024)
		if not chunk or not chunk1 then
			break
		end
		buffer = decoder(chunk)
		buffer1 = decoder1(chunk1)
		parallel.waitForAll(table.unpack(speakers))
	end
	data.close()
	data1.close()
end

--mdisk
local function isMdiskPresent()
	return fs.exists("/disk") and fs.exists("/disk/metadata.json") and fs.exists("/disk/left.dfpwm")
end
local function getSongMetadata()
	if fs.exists("/disk/metadata.json") then
		local meta1 = fs.open("/disk/metadata.json", "rb")
		local json = meta1.readAll()
		meta1.close()
		return textutils.unserializeJSON(json)
	else
		return {}
	end
end
local function isMdiskStereo()
	return fs.exists("/disk") and fs.exists("/disk/metadata.json") and fs.exists("/disk/left.dfpwm") and fs.exists("/disk/right.dfpwm")
end
local function playMdisk(ls,rs,vol)
	if isMdiskPresent() then
		if isMdiskStereo() then
			playDfpwmStereo("disk/left.dfpwm", "disk/right.dfpwm",ls,rs, vol)
		else
			playDfpwmMono("disk/left.dfpwm",vol)
		end
	else
		error("Mdisk not present!")
	end
end
--Exposed library
speakerlib.playDfpwmMono = playDfpwmMono
speakerlib.setMonoBuffer = setMonoBuffer
speakerlib.getMonoFunctions = getMonoFunctions

speakerlib.playDfpwmStereo = playDfpwmStereo
speakerlib.setStereoBuffers = setStereoBuffers
speakerlib.getStereoFunctions = getStereoFunctions

speakerlib.isMdiskPresent = isMdiskPresent
speakerlib.getSongMetadata = getSongMetadata
speakerlib.isMdiskStereo = isMdiskStereo

speakerlib.addLeftSpeaker = addLeftSpeaker
speakerlib.addRightSpeaker = addRightSpeaker
speakerlib.getLeftSpeakers = getLeftSpeakers
speakerlib.getRightSpeakers = getRightSpeakers
speakerlib.removeleftSpeaker = removeleftSpeaker
speakerlib.removeRightSpeaker = removeRightSpeaker
speakerlib.resetSpeakerTables = resetSpeakerTables

if not pcall(debug.getlocal, 4, 1) then
	local args = {...}
	if args[1] == "add" then
		if args[2] == "left" then
			addLeftSpeaker(args[3])
			error("added speaker",0)
		elseif args[2] == "right" then
			addRightSpeaker(args[3])
			error("added speaker",0)
		end
	elseif args[1] == "remove" then
		if args[2] == "left" then
			if removeleftSpeaker(args[3]) then
				error("removed speaker",0)
			else
				error("speaker not found",0)
			end
		elseif args[2] == "right" then
			if removeRightSpeaker(args[3]) then
				error("removed speaker",0)
			else
				error("speaker not found",0)
			end
		end
	elseif args[1] == "reset" then
		resetSpeakerTables()
		error("speaker config reset",0)
	else
		error("speakerlib must be called from another program!",0)
	end
end

return speakerlib
