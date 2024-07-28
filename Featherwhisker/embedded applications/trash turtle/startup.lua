
for i=16, 1, -1 do
    turtle.select(i)
    turtle.drop(64)
end

while true do
    repeat
        sleep()
    until turtle.suckUp()
    repeat sleep() until turtle.drop()
end
