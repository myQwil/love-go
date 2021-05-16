local game = {}

local passes = 0

local function clear_history()
	for k in next,stones  do rawset(stones  ,k ,nil) end
	for k in next,history do rawset(history ,k ,nil) end
	step ,last = 0 ,0
end

local function add_to_history(b)
	step = step + 1
	history[step] =
	{	 color = stone.color
		,m = prev[stone.color]   }
	menu.btns.undo.on = true
	menu.btns.redo.on = false
	last = step

	stone = {color = not stone.color}
	passes = b and passes+1 or 0
	set_playing(passes < 2)
end

local function do_handicap(s)
	local ishandicap = (s:find('^inv') == nil)
	if ishandicap then
		board.populate(s ,black) end
	return ishandicap
end

function game.init(t)
	if not enough_args(#t ,4) then
		return end

	goversion = t[1]..' '..t[2]
	do_handicap(t[4])
	waiting = nil
end

function game.board(t)
	if not enough_args(#t ,2) then
		return end

	board.init()
	clear_history()
	do_handicap(t[2])
	waiting = nil
end

function game.new(t)
	if not enough_args(#t ,4) then
		return end

	clear_history()
	local ishandicap = do_handicap(t[3])
	if play[black] == play[white] then -- two humans or two computers
		stone.color = not ishandicap -- black is first except when using handicap
		if not play[black] then -- two computers
			genmove()
		else waiting = nil end
	else -- human vs computer
		stone.color = play[black]
		if stone.color == ishandicap then
			stone.color = not stone.color
			genmove()
		else waiting = nil end end
end

function game.human(t)
	if not enough_args(#t ,1) then
		return end

	walking = false -- we've left history mode

	if t[1] ~= '' then -- illegal move
		stones[col..row] = nil
		response = t[1]
		waiting = nil
		return end

	if row then -- player didn't skip move
		prev[stone.color] = col..row end
	add_to_history(not row)

	if not playing then
		history[step].final = true
		final_score()
	elseif play[black] and play[white] then -- two humans
		response = ''
		update()
	else genmove() end
end

function game.computer(t)
	if not enough_args(#t ,2) then
		return end

	if play[black] or play[white] then
		response = '' end
	prev[stone.color] = t[2]
	curnt[stone.color] = nil

	if t[2] == 'resign' then
		set_playing(false)
		history[step].final = true
		history[step].resign = true
	else
		add_to_history(t[2] == 'PASS')
		if not playing then
			history[step].final = true end end
	update()
end

function game.history(t)
	if not enough_args(#t ,1) then
		return end
	update()
end

function game.komi(t)
	if not enough_args(#t ,1) then
		return end
	waiting = nil
end

function game.update(t)
	if not enough_args(#t ,4) then
		return end

	for k in next,stones do rawset(stones ,k ,nil) end
	for i = 1,2 do board.populate(t[i] ,i==1) end
	captr[black] = t[3]
	captr[white] = t[4]

	if not playing then
		final_score()
	elseif walking then
		response = ''
		waiting = nil
	elseif not (play[black] or play[white]) then -- two computers
		genmove()
	else waiting = nil end
end

function game.done(t)
	if not enough_args(#t ,1) then
		return end

	response = t[1]
	waiting = nil
end

return game
