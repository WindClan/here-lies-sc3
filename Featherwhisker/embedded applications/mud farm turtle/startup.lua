while true do
	turtle.select(3)
	if turtle.compare() then
		turtle.select(1)
		turtle.dig()
		turtle.dropUp()
	end
	turtle.select(2)
	if turtle.compare() then
		turtle.select(1)
		turtle.dig()
		turtle.dropDown()
	end
	sleep()
end