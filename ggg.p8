pico-8 cartridge // http://www.pico-8.com
version 41
__lua__
--main engine functions

function _init()
	cls(0)
	gstate = 0 --0 is start, 1 is play, 2 us gameover
	t=0 --counter
	txcolor=0 --start screen text
end

function _start()
		cls(0)
--setup object arrays
	player={}
	star={}
	_setup_player(player)
	_setup_star(star)
--game parameters
	gstate = 1 --0 is start, 1 is play, 2 us gameover
	grav = 8
	--cooldown limit, jmp height limit
	jmpclim,jmplim  = 8,0
	--counter
	t = 0
end

function _update60()
	if gstate==1 then
		_update_game60()
	elseif gstate==0 then
		_update_start()
	elseif gstate==2 then
		_update_over()
	end
end

function _draw()
	if gstate==1 then
		_draw_game()
	elseif gstate==0 then
		_draw_start()
	elseif gstate==2 then
		_draw_over()
	end
end

function _update_game60()
	
	update_player()
	update_star()
	animate_player()
	animate_star()
	check_collisions()
	
	--you fell into a pit
	if player.y >= 128 then
		player.dead = true
	end
	--are we dead?
	if player.dead == true then
		cls(0)
		gstate=2 --game over
	end
	--check for ground collision
	if player.ycol then
		player.grnd = true
	else
		player.grnd = false
	end
	--t is my counter, dude
	t+=1
	if (t > 120) then
		t = 0
	end
end

function _draw_game()
	cls(12)
	map(0,0,0,64)
	spr(player.spr,player.x,player.y,1,1,player.dir)
	if star.exists or star.charging then
		spr(star.spr,star.x,star.y)
	end
	--debug vars
	debug()
end

--start/gameover screens

function _draw_start()
	cls(5)
	print("◆➡️░★★ ▒⬆️⧗⧗🅾️♪",16,64,txcolor)
	print(t)
end

function _update_start()
	if btnp(4) or btnp(5) then
		_start()
	end
	--animation on start screen
	t+=1
	if (t > 120) then
		t = 1
	end
	if t%60==0 then
		txcolor=3
	end
	if t%120==0 then
		txcolor=0
	end
end

function _draw_over()
	cls(6)
	print("●█😐░ 🅾️ˇ░➡️",16,64)
end

function _update_over()
	if btnp(4) or btnp(5) then
		gstate=0
	end
end
-->8
--player movement and actions
function update_player()

	if btn(1) then --➡️ wins! lol
		player.xsp = 1
	elseif btn(0) then
			player.xsp = -1
	else
			player.xsp = 0
	end

--check direction/flip sprite
	if player.xsp > 0 then
		player.dir = false
	elseif player.xsp < 0 then
		player.dir = true
	end
	
	--move x
	if not player.xcol then
		player.x = player.x + player.xsp
	elseif player.xcol and player.xsp != 0 then
		sfx(1) --play collision sound
	end
	
	--gravity
	if player.grnd then
		player.ysp = 0
	else
		--accel limit?
		if t%grav == 0 then
			if player.ysp < 5 then
				player.ysp+=1
			end
		end
	end
	
	--jump logic
	--cooldown on the ground
	if player.jmpcool > 0 and player.grnd then
		player.jmpcool = player.jmpcool - 1
		player.jmp = false
	end
	--first time button pressed
	if(btn(4)) and player.grnd and player.jmpcool == 0 then
		if player.jmp == false then
			player.jmpcool = jmpclim
			--play sound on jump?--
			sfx(0)
		end
		player.ysp=-1
		player.jmp=true
		player.grnd=false
		jmplim=0
	end
	--holding down the jmp button in air
	if player.jmp and btn(4) and jmplim < 10 then
		player.ysp=-2
		jmplim+=1
	else
	--no double jumping
		jmplim=99
	end

--move y
		player.y+=player.ysp

end

function update_star()
--button initially pressed
	if not star.exists then
		if btn(5) then
			if star.stup <45 then
				star.stup+=1
				star.charging = true
				star.x= player.x
				star.y= player.y-8
			elseif star.stup >= 45 then
				star.stup = 0
				star.exists = true
				star.x = player.x
				star.y = player.y-8
			end
		else
			star.stup = 0
			star.charging = false
			star.xsp = 0
			star.ysp = 0
		end
--star already exists and button held
	elseif btn(5) and star.cnt==0 and star.charging then 
		star.x = player.x
		star.y = player.y-8
--star release	
	elseif star.charging and star.cnt==0 then
		star.cnt = star.lim
		if player.dir then
			star.xsp = -2
		else
			star.xsp = 2
		end
		star.ysp = 1
		star.charging = false
	elseif star.cnt > 0 then
--star physics hack
		if star.y > 104 then
			star.ysp = -1
		end
--move star x and y
		star.x+=star.xsp
		star.y+=star.ysp
		star.cnt-=1
	else
--kill star
		star.exists = false
	end
end
-->8
--animation
function animate_player()
--state 0: idle
	if player.xsp == 0 and player.ysp == 0 and player.jmpcool == 0 then
--state 0.5: lookin' up
		if btn(2) then
			player.spr = 4
		else
			player.spr = 1
		end
--state 1: walking on flat grnd
	elseif player.xsp != 0 and player.grnd and player.jmpcool == 0 then
	--ani speed
		if t%8 == 0 then
			player.spr += 1
			--clamp animation
			if player.spr > 3 then
				player.spr = 1
			end
		end
--state 2: jmping up
	elseif player.jmp and player.ysp < 0 then
		player.spr = 4
--state 3: falling
	elseif player.jmp and player.ysp > 0 then
		player.spr = 5
--state 4: jmp recovery
	elseif player.grnd and player.jmpcool > 0 then
		player.spr = 6
	end
end

function animate_star()
--state 0: charging star up
	if star.charging and star.stup>0 then
	if star.stup == 1 then
		star.spr = 17
	end
	--ani speed
		if t%10 == 0 then
			star.spr += 1
			--clamp animation
			if star.spr > 18 then
				star.spr = 17
			end
		end
--state 1: ready to fire, flash
	elseif star.charging then
	--ani speed
		if t%30 == 0 then
			star.spr = 19
		elseif t%15 == 0 then
			star.spr = 16
		end
--state 2: star flying, static
	else
--ani speed
		if t%30 == 0 then
			star.spr = 20
		elseif t%15 == 0 then
			star.spr = 16
		end
	end
end
-->8
--object code
function _setup_player(player)
	--define player obj data
	player.x=10
	player.y=104
	player.xcol=false
	player.ycol=true
	player.xsp=0
	player.ysp=0
	player.dir=false
	player.spr=1
	player.jmp=false
	player.jmpcool=0
	player.grnd=true
	player.dead=false
end

function _setup_star(star)	
	--define star obj data
	star.x=0
	star.y=0
	star.xcel=0
	star.ycel=0
	star.xsp=0
	star.ysp=0
	star.dir=false
	star.spr=16
	star.exists=false
	star.lim=60
	star.cnt=0
	star.stup=0
	star.charging=false
end
-->8
--soundfx
function sound()
	sfx(0) --jump sound?
end
-->8
--debug
function debug()
	print("x: " .. tostr(player.x))
	print("y: " .. tostr(player.y))
	print("grnd: " .. tostr(player.grnd))
	print(mget(flr(player.x/8),ceil((player.y)/16)-1))	
	print("xcol: " .. tostr(player.xcol))
	print(player.ycol)
end
-->8
--collisions
function check_collisions()
	if player.x == 64-7 and not player.dir then
		player.xcol = true
		player.x=64-7
	else
		player.xcol = false
	end
	if player.y + player.ysp >= 104 then
		player.ycol = true
		player.y=104
	else
		player.ycol = false
	end
end
__gfx__
00000000090333000903330009033300090333000903330000000000ffccccffcccccccc55555555000000000000000000000000000000000000000000000000
06000060089bb330089bb330089bb33008973730089bbb3309033300fccccfffcccccccc55555555000000000000000000000000000000000000000000000000
0070070003bb7b7003bb7b7003bb7b7003b777703bb7777b089bb300ccccffffcccccccc5c5c5ff5000000000000000000000000000000000000000000000000
600770063bb737303bb737303bb737303bb7777033b7373b03b77730cccfffffcccccccccccfffff050505500000000000000000000000000000000000000000
060770603bbb7b733b3b7b7b3b3b7b73bb3b33b303bbbbb33bb73770ccfffffcccccccccccfffffc055555500000000000000000000000000000000000000000
007007003b3bb3b33bb3b3b33bb3b3b3333bbbb3003b33b33bbbbbb3cfffffcccccccccccfffffcc055757500000000000000000000000000000000000000000
0000000003bbbb30033bbbb6633bbbb0036bb6b306bbbbb63b3bb3b3fffffcccccccccccfffffccc055555500000000000000000000000000000000000000000
000000006633336606633360063333600663366000633660036bb630ffffccccccccccccffffcccc005005000000000000000000000000000000000000000000
000a000aaa0000aa0a00a00a00090009000700070903330000000000000000000000000000000000000000000000000000000000000000000000000000000000
a00a00a0aa0a00aaaaa00aaa9009009070070070089bb33000000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a000000a0000aa00aa0090909000707070003bbb33000000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa0000a00000aaa00000000999000007770003bbbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000
aaaaaaaa0000000000aa0aaa99999999777777773bbbbbb300000000000000000000000000000000000000000000000000000000000000000000000000000000
00aaa0000000000000aa0aaa00999000007770003b3bb3b300000000000000000000000000000000000000000000000000000000000000000000000000000000
0a0a0a00aaa0a0aa0aa00aa0090909000707070003bbbb3000000000000000000000000000000000000000000000000000000000000000000000000000000000
a00a00a0aa0000aa0a0a00a090090090700700706633336600000000000000000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000090909090909090900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0909090909090909070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0707070707070707070707070707070700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
00030000060300d0301b0401d0401b040120400c0400a040000400001004000010000000003000000000000004000050000600007000080000900009000080000600004000020000100000000001000010000100
000100000d21011210072100421001210002100520005200052000520005200052000520005200052000520005200042000420000200042000020003200032000020003200002000320004200082000420007200
00020900233502435024350243502435024350243501c350253502c350303502f3502a350143500d3500a350053500235008350383503f3503b350353502e3502a35020350153500835002350003500235000350
