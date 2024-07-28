while true do
	if not turtle.compareUp() then
		turtle.digUp()
		turtle.up()
		turtle.placeDown()
	end
end