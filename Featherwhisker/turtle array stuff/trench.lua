amount = 11
local l = peripheral.find("plethora:laser")
for i=1,amount do
	for i=1,40 do
		l.fire(0,90,5)
		sleep(1/20)
	end
	turtle.forward()
end