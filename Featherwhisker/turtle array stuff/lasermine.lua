local laser = peripheral.find("plethora:laser")
while true do
	turtle.dig()
	for i=1,20 do
		laser.fire(0,-90,5)
		sleep(0.25)
	end
	turtle.forward()
end