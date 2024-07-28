--HTTPJukeboxV3
--Made by Featherwhisker
local t = peripheral.find("monitor")
local s = peripheral.find("speaker")
local queue = {}
local trusted = require("trusted")
local current = ""
local requester = ""
local dfpwm = require("cc.audio.dfpwm")
local skip = 0
local votes = {}
function chat()
     while true do
        local event, user, command, args = os.pullEvent("command")
        if command == "queue"  then
            if #args <= 0 then
                chatbox.tell(user, "You need to give an audio URL!", "Jukebox")
            else
                chatbox.tell(user,"Received!","Jukebox")
                table.insert(queue,{args[1], user})
            end
        elseif command == "clearqueue" then
           if trusted[string.lower(user)] then
               queue = {}
               current = ""
               requester = ""
           end
       elseif command == "skipsong" then
            if not votes[user] then
                chatbox.tell(user,"Vote received!", "Jukebox")
                votes[user] = true
                skip = skip + 1
                if skip >= math.floor((#chatbox.getPlayers())*(1/3)) then
                    skip = 0
                    votes = {}
                    current = ""
                end
            else
                chatbox.tell(user, "You already voted to skip this song!", "Jukebox")
            end
        end
    end
end
function music()
    while true do
        if #queue ~= 0 then
            current = queue[1][1]
            requester = queue[1][2]
            table.remove(queue,1)
            local data = http.get("https://cc.alexdevs.me/dfpwm?url="..current, nil, true)
            if data then
                print("Playing "..current)
                local decoder = dfpwm.make_decoder()
                while true do
                    if current == "" then
                        break
                    end
                    local chunk = data.read(16 * 1024)
                    if not chunk then
                        break
                    end

                    local buffer = decoder(chunk)
                    while not s.playAudio(buffer) do
                        os.pullEvent("speaker_audio_empty")
                    end
                end
               current = ""
               requester = ""
            end
        end
        sleep()
    end
end
function monitor()
    term.clear()
    term.setCursorPos(1,1)
    t.setBackgroundColor(colors.black)
	t.setTextColor(colors.lime)
    t.setTextScale(0.5)
    t.clear()
    while true do
       t.clear()
       t.setCursorPos(1,1)
       t.write("HTTP Jukebox v3")
       t.setCursorPos(1,2)
       t.write("\\queue {song}")
       t.setCursorPos(1,3)
       t.write("\\skipsong")
       t.setCursorPos(1,4)
       if current ~= "" then
           t.write("Requested by:")
           t.setCursorPos(1,5)
           t.write(requester)
       else
           t.write("Queue empty!")
       end
       os.sleep()
    end
end
parallel.waitForAll(music,chat,monitor)
