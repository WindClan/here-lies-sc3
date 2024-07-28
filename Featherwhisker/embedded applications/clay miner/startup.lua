while true do
	turtle.select(3)
	if turtle.compare() then
		turtle.select(1)
		turtle.dig()
		turtle.dropUp()
	end
	sleep()
end