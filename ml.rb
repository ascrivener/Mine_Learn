class Board
	attr_accessor :board, :height, :width
	def initialize(height, width, num_bombs)		
		@height = height
		@width = width
		@board = Array.new(height) {Array.new(width,nil)}
		@num_bombs = num_bombs
		@dirs = [[-1,-1],[-1,0],[-1,1],[0,-1],[0,1],[1,-1],[1,0],[1,1]]

		(0..@height-1).each do |i|
			(0..@width-1).each do |j|
				@board[i][j] = Tile.new
			end
		end

		n = 0
		while (n < @num_bombs)
			i = (0..(@height-1)).to_a.sample
			j =	(0..(@width-1)).to_a.sample
			if (!@board[i][j].has_bomb)
				@board[i][j].has_bomb = true
				n=n+1
			end
		end

		(0..@height-1).each do |i|
			(0..@width-1).each do |j|
				if @board[i][j].has_bomb
					@board[i][j].number = -1
				else
					count = 0
					@dirs.each do |d_i,d_j|
						t_i = i+d_i
						t_j = j+d_j
						if (inbounds(t_i,t_j))
							if (@board[t_i][t_j].has_bomb)
								count = count+1
							end
						end
					end
					@board[i][j].number = count
				end
			end
		end
	end
	def mark(i,j)
		if (@board[i][j].flipped)
			puts "already flipped!"
		elsif (@board[i][j].marked)
			@board[i][j].marked = false
		else
			@board[i][j].marked = true
		end
	end
	def flip(i,j)
		if (@board[i][j].has_bomb)
			puts "BOOM"
		elsif (@board[i][j].flipped)
			puts "already flipped!"
		else
			@board[i][j].flipped = true
			update_confs(i,j)
			# if (@board[i][j].number == 0)
			# 	clear(i,j)
			# end
		end
	end
	def clear(i,j)
		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && !@board[t_i][t_j].flipped)
				flip(t_i,t_j)
				if (@board[t_i][t_j].number == 0)
					clear(t_i,t_j)
				end
			end
		end
	end
	def inbounds(i,j)
		return (i >=0 && i < @height && j >= 0 && j < @width)
	end
	def update_confs(i,j)
		new_safe_tiles = []

		gen_confs(i,j)

		

		# if (!@board[i][j].known_safe)
		# 	new_safe_tiles << [i,j]
		# 	@board[i][j].known_safe = true
		# end



		# if (confs.size == 1)
		# 	safe_list = tiles - confs[0]
		# 	safe_list.each do |x,y|
		# 		@board[x][y].known_safe = true
		# 		# !!!! make sure it is known what causes [x,y] to be safe! somehow
		# 	end
		# 	confs[0].each do |x,y|
		# 		@board[x][y].known_bomb = true
		# 		#!!!!! make sure blah blah blah to be bomb! blah blah blah
		# 	end
		# 	new_safe_tiles.concat(safe_list)
		# end

		# doSomething(new_safe_tiles)

		puts "confs after deleting: #{@board[i][j].confs.inspect}"
	end

	def gen_confs(i,j)
		cur_unknown_tiles = []
		confs = []
		known_bomb_count = 0

		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && !@board[t_i][t_j].known_safe)
				cur_unknown_tiles << [t_i,t_j]
			end
			if (inbounds(t_i,t_j) && @board[t_i][t_j].known_bomb)
				cur_unknown_tiles.delete([t_i,t_j])
				known_bomb_count += 1
			end
		end

		list = Chooser.new(cur_unknown_tiles.size,@board[i][j].number-known_bomb_count).confs

		list.each do |c_list|
			a=[]
			c_list.each_with_index do |elm,k|
				if (elm == 1)
					a << cur_unknown_tiles[k]
				end
			end
			confs << a
		end

		@board[i][j].confs = confs

		puts "confs before deleting for #{i}, #{j}: #{confs}"

		queue = [[i,j]]
		explored_tiles = [[i,j]]

		while (queue[0] != [])
			puts "propogating #{queue[0]}"
			lists = propogate(queue.delete_at(0),explored_tiles)
			queue << lists[0]
			explored_tiles << lists[1]
		end

		# return confs
	end
	
	def propogate(cur_tile,explored_tiles)
		affected_tiles = []
		get_unknown_tiles(cur_tile[0],cur_tile[1]).each do |i,j|
			@dirs.each do |d_i,d_j|
				t_i = i+d_i
				t_j = j+d_j

				if (inbounds(t_i,t_j) && @board[t_i][t_j].flipped && !affected_tiles.include?([t_i,t_j]) && !explored_tiles.include?([t_i,t_j]))
					affected_tiles << [t_i,t_j]
				end
			end
		end

		unknown_tiles = get_unknown_tiles(cur_tile[0],cur_tile[1])
		last_tiles = []
		confs = @board[cur_tile[0]][cur_tile[1]].confs

		affected_tiles.each do |i,j|
			affected_unknown_tiles = get_unknown_tiles(i,j)

			possible_confs = Set.new

			flag2 = false
			
			confs.each do |conf1|
				flag = false
				@board[i][j].confs.each do |conf2|
					if ((conf1 & affected_unknown_tiles).to_set == conf2.to_set)
						possible_confs.add(conf2)
						flag = true
					end
				end
				if !flag
					flag2 = true
					@board[cur_tile[0]][cur_tile[1]].confs.delete(conf1)
					puts "deleting #{conf1}"
				end
			end

			if flag2
				puts "confs: #{@board[cur_tile[0]][cur_tile[1]].confs}"
				@board[cur_tile[0]][cur_tile[1]].confs.inject{|r,e| r & e}.each do |x,y|
					@board[x][y].known_bomb = true
					remove_from_confs(cur_tile[0],cur_tile[1],[x,y])
				end
				(unknown_tiles - @board[cur_tile[0]][cur_tile[1]].confs.inject{|r,e| r & e}).each do |x,y|
					@board[x][y].known_safe = true
					remove_from_confs(cur_tile[0],cur_tile[1],[x,y])
				end
			end

			if @board[i][j].confs.to_set == possible_confs
				last_tiles << [i,j]
			else
				@board[i][j].confs = possible_confs.to_a
				@board[i][j].confs.inject{|r,e| r & e}.each do |x,y|
					@board[x][y].known_bomb = true
					remove_from_confs(cur_tile[0],cur_tile[1],[x,y])
				end
				(affected_unknown_tiles - @board[i][j].confs.inject{|r,e| r & e}).each do |x,y|
					@board[x][y].known_safe = true
					remove_from_confs(cur_tile[0],cur_tile[1],[x,y])
				end
			end
		end

		return [affected_tiles-last_tiles,affected_tiles]
	end

	def remove_from_confs(i,j,tile)
		@board[i][j].confs.each do |c|
			c.delete([tile[0],tile[1]])
		end
	end

	def get_unknown_tiles(i,j)
		unknown_tiles = []
		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j
			if (inbounds(t_i,t_j) && !@board[t_i][t_j].known_safe && !@board[t_i][t_j].known_bomb)
				unknown_tiles << [t_i,t_j]
			end
		end
		return unknown_tiles
	end

	def get_adj_tiles(i,j)
		a = []
		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j
			if (inbounds(t_i,t_j) && !@board[t_i][t_j].flipped)
				a << [t_i,t_j]
			end
		end
		return a
	end

	def out(final=false)
		print "\n   "
		(0..(@width-1)).each do |i|
			print "#{i} "
		end
		print "\n\n"
		(0..(@height-1)).each do |i|
			(0..(@width-1)).each do |j|
				if j == 0
					print "#{i}  "
				end
				print "#{@board[i][j].out(final)} "
			end
			puts
		end
		puts
	end
end

class Tile
	attr_accessor :flipped, :marked, :has_bomb, :number, :confs, :known_safe, :known_bomb
	def initialize(has_bomb=false)
		@flipped = false
		@marked = false
		@has_bomb = has_bomb
		@number = -1
		@confs = nil
		@known_safe = false
		@known_bomb = false
	end
	def out(final=false)
		if @flipped
			@number
		elsif @marked
			"?"
		elsif final && @has_bomb
			"B"
		else
			"X"
		end
	end
end

class Chooser
	attr_accessor :confs
	def initialize(n,k)
		@a = Array.new(n+1){Array.new(k+1,nil)}
		gen_confs(n,k)
		#puts a[n][k].inspect
		@confs = @a[n][k]
		remove_instance_variable(:@a)
	end
	def gen_confs(n,k)
		arr = @a[n][k]
		if (arr)
			# puts "already exists"
			return arr
		elsif (k==0)
			@a[n][k] = [[0]*n]
			# puts "k is 0, made into #{a[n][k]}"
			return @a[n][k]
		elsif (n==k)
			@a[n][k] = [[1]*n]
			# puts "n = k, made into #{a[n][k]}"
			return @a[n][k]
		else
			@a[n][k] = gen_confs(n-1,k-1).map{|x| x + [1]} + gen_confs(n-1,k).map{|x| x + [0]}
			# puts "made into #{a[n][k]}"
			return @a[n][k]
		end

	end
end

class Game
	def initialize(height=10, width=10, num_bombs=10)
		@height = height
		@width = width
		@num_bombs = num_bombs
		play
	end
	def play
		m = Board.new(@height,@width,@num_bombs)

		while(true)
			i = gets.chomp.to_i
			j = gets.chomp.to_i
			m.flip(i,j)
			if (m.board[i][j].has_bomb)
				m.out(true)
				break
			end


			m.out
		end
	end
end

require 'set'
Game.new(10,10,10)