--Poster printer array software
--Configuration
local paperSlot = 1
local inkSlot = 2
local printSlot = 3
local maxInk = 100000
local paperChestType = "minecraft:chest" --You can change these if you want
local printChestType = "sc-goodies:iron_chest"
local inkChestType = "sc-goodies:diamond_chest"
local emptyChestType = "sc-goodies:gold_chest"

--Functions
function printPage(name, dat) --The thing that actually sends data to the printer
	peripheral.call(name, "reset")
	if dat["label"] then
		peripheral.call(name, "setLabel", dat["label"])
	end
	if dat["tooltip"] then
		peripheral.call(name, "setTooltip", dat["tooltip"])
	end
	peripheral.call(name, "blitPalette", dat["palette"])
	peripheral.call(name, "blitPixels", 1, 1, dat["pixels"])
	sleep()
	return peripheral.call(name, "commit", 1)
end

local function main(file,count,list) --The program
	--Setup the peripherals
	local printers = {} --All found printer names

	local chest1 = peripheral.find(printChestType) --Finished print chest (extract from slot 3)
	local chest2 = peripheral.find(paperChestType) --Paper chest (insert into slot 1)
	local chest3 = peripheral.find(inkChestType) --Ink cartridges (insert into slot 2 then put back in chest 4)
	local chest4 = peripheral.find(emptyChestType) --Empty cartridges
	if not chest1 or not chest2 or not chest3 or not chest4 then
		error("Missing one of the required chests!",0)
	end

	for _,v in pairs(peripheral.getNames()) do
		if peripheral.hasType(v, "poster_printer")  then
			table.insert(printers,v)
		end
		sleep()
	end
	print("Found "..#printers.." poster printers")
	if #printers == 0 then
		error("No valid print storage found!")
	end

	--Prepare for printing
	local json = nil
	if http.checkURL(file) then
		if not list then
			local dat,fail = http.get(file)
			if dat then
				json = dat.readAll()
				dat.close()
			else
				error(fail,0)
			end
		else
			local dat,fail = http.get(file)
			if dat then
				json = ""
				local list = textutils.unserialiseJSON(dat.readAll())
				dat.close()
				for i,v in pairs(list[2]) do
					local dat1, fail = http.get(list[1]..v)
					if dat1 then
						json = json..dat1.readAll()
						dat1.close()
					else
						print(fail,list[1]..v)
						error("",0)
					end
					print("Downloaded part "..i)
					sleep()
				end
			else
				error(fail,0)
			end
		end
	else
		local file = fs.open(file,"r")
		json = file.readAll()
		file.close()
	end
	sleep()
	local data = textutils.unserialiseJSON(json)
	sleep()
	local pageTable = {}
	for i=1,count do
		if not data["pages"] then
			table.insert(pageTable,data)
		else
			for _,v in pairs(data["pages"]) do
				table.insert(pageTable,v)
				sleep()
			end
		end
		sleep()
	end

	--do the printing stuff
	local done = false
	local doprint = false
	local function sendLoop()
		local index = 1
		local index1 = 0
		while true do
			for _,v in pairs(printers) do
				if index > #pageTable then
					return
				end
				if index-1 >= index1 + #printers then
					while not doprint do
						sleep()
					end
					doprint = false
					index1 = index - 1
				end
				printPage(v,pageTable[index])
				index = index + 1
				sleep()
			end
		end
	end
	local function timerLoop()
		local finished = 0
		while true do
			if finished >= #pageTable then
				print("Done, finishing up poster collection")
				sleep(3)
				done = true
				return
			end
			os.pullEvent("poster_printer_complete")
			finished = finished + 1
			if finished % #printers == 0 then
				doprint = true
			end
		end
	end
	local function refillLoop()
		while not done do
			for _,v in pairs(printers) do
				local list = peripheral.call(v,"list")
				if list[printSlot] then
					chest1.pullItems(v,printSlot)
					sleep()
				end
				if peripheral.call(v,"getInkLevel") <= maxInk/4 then
					for i,_ in pairs(chest3.list()) do --Quick way to get first slot with items
						if list[inkSlot] then
							chest4.pullItems(v,inkSlot)
						end
						chest3.pushItems(v,i,1,inkSlot)
						break
					end
				end
				if not list[paperSlot] or list[paperSlot]["count"] < 32 then
					for i,_ in pairs(chest2.list()) do -- YOURFRIEND: This was iterating through chest3 for some reason, while it should've been
							-- iterating through chest2 instead. Fixed!
						chest2.pushItems(v,i,64,paperSlot)
						break
					end
				end
			end
		end
	end
	parallel.waitForAll(sendLoop,timerLoop,refillLoop)
end

--Run
local args = {...} --Program's arguments
if #args == 0 or (#args > 2 and args[3] ~= "split") then
	error("Usage: print <file> <count>", 0)
end
local file = args[1]
local count = args[2]
if not count then
	count = 1
end
main(args[1],args[2],args[3])
