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
			if (@board[i][j].number == 0)
				clear(i,j)
			end
		end
	end
	def clear(i,j)
		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && !@board[t_i][t_j].flipped)
				# puts "flipping #{[t_i,t_j]}"
				flip(t_i,t_j)
			end
		end
	end
	def inbounds(i,j)
		return (i >=0 && i < @height && j >= 0 && j < @width)
	end

	def update_confs(i,j)
		cur_unknown_tiles = []
		confs = []
		known_bomb_count = 0
		known_bombs = []

		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && !@board[t_i][t_j].known_safe)
				cur_unknown_tiles << [t_i,t_j]
			end
			if (inbounds(t_i,t_j) && @board[t_i][t_j].known_bomb)
				cur_unknown_tiles.delete([t_i,t_j])
				known_bombs << [t_i,t_j]
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
			if (known_bombs != [])
				a.concat(known_bombs)
			end
			if a != []
				confs << a
			end
		end

		@board[i][j].confs = confs

		#puts "confs for #{[i,j]}: #{confs}"

		#puts "*********PHASE 1*************"

		# queue_additions = []

		if !@board[i][j].known_safe
			@board[i][j].known_safe = true
			#puts "#{[i,j]} known to be safe!"
			@dirs.each do |d_i,d_j|
				t_i = i+d_i
				t_j = j+d_j
				if inbounds(t_i,t_j) && @board[t_i][t_j].flipped
					@board[t_i][t_j].confs.each do |conf|
						if conf.include?([i,j])
							@board[t_i][t_j].confs.delete(conf)
							#puts "deleting #{conf} from #{[t_i,t_j]}"
							if @board[t_i][t_j].confs.size == 1
								get_unknown_tiles(t_i,t_j).each do |x,y|
									if (!@board[x][y].known_bomb)
										@board[x][y].known_bomb = true

										puts "#{[x,y]} known to be bomb!"
									end
								end
							end
						end
					end
				end
			end
		end

		t_confs = Array.new(@board[i][j].confs)

		get_affected_tiles(i,j,[[i,j]]).each do |x,y|
			t_confs.each do |c1|
				if (@board[x][y].confs.size > 0)
					intersection = c1 & get_unknown_tiles(x,y)
					#puts "intersecting #{c1} and #{get_unknown_tiles(x,y)}"
					#puts "intersection = #{intersection}"
					flag = false
					@board[x][y].confs.each do |c2|
						if (intersection.to_set == (c2 & get_unknown_tiles(i,j)).to_set)
							flag = true
							#puts "#{c1} is possible"
						end
					end
					if (!flag)
						@board[i][j].confs.delete(c1)
						#puts "deleting #{c1} from #{[i,j]}"
					end
				end
			end
		end

		#puts "new confs for #{[i,j]}: #{@board[i][j].confs}"
		

		if @board[i][j].confs.size == 0
			get_unknown_tiles(i,j).each do |x,y|
				if (!@board[x][y].known_safe)
					@board[x][y].known_safe = true
					puts "[#{x},#{y}] known to be safe!"
				end
				#remove_from_confs(x,y)
			end
		else
			@board[i][j].confs.inject{|r,e| r & e}.each do |x,y|
				if (!@board[x][y].known_bomb)
					@board[x][y].known_bomb = true
					puts "[#{x},#{y}] known to be bomb!"
				end
				#remove_from_confs(x,y) #!!!!! no
			end
			(@board[i][j].confs.map{|x| get_unknown_tiles(i,j) - x}.inject{|r,e| r & e}).each do |x,y|
				if (!@board[x][y].known_safe)
					@board[x][y].known_safe = true
					puts "[#{x},#{y}] known to be safe!"
				end
				#remove_from_confs(x,y)
			end
		end

		#puts "*********END OF PHASE 1*************"

		#puts "***********PHASE 2***************"


		queue = [[i,j]]
		explored_tiles = []

		while (queue.size > 0)
			cur_tile = queue.delete_at(0)
			explored_tiles.concat([cur_tile])
			new_tiles = propogate(cur_tile,explored_tiles)
			if (new_tiles != [])
				queue.concat(new_tiles)
			end
			#puts "new queue: #{queue.inspect}"
		end




		

		# return confs
	end
	
	def propogate(cur_tile,explored_tiles)
		#puts "propogating #{cur_tile.inspect}"
		#puts "explored: #{explored_tiles}"

		affected_tiles = get_affected_tiles(cur_tile[0],cur_tile[1],explored_tiles)

		unknown_tiles = get_unknown_tiles(cur_tile[0],cur_tile[1])
		last_tiles = []
		confs = @board[cur_tile[0]][cur_tile[1]].confs
		
		#puts "confs for #{cur_tile}: #{confs}"
		affected_tiles.each do |i,j|
			last_tile = true
			#puts "combining #{cur_tile.inspect} with [#{i},#{j}]"
			#puts "confs for [#{i},#{j}]: #{@board[i][j].confs}"

			t_confs = @board[i][j].confs
			
			if (confs == [])
				get_adj_tiles(cur_tile[0],cur_tile[1]).each do |tx,ty|
					t_confs.each do |conf1|
						if (conf1.include?([tx,ty]))
							@board[i][j].confs.delete(conf1)
							#puts "deleting #{conf1} from #{[i,j]}"
							last_tile = false
						end
					end
				end
			else
				t_confs.each do |conf1|
					# flag = false
					intersection = conf1 & get_unknown_tiles(cur_tile[0],cur_tile[1])
					#puts "intersecting #{conf1} and #{affected_unknown_tiles}"
					#puts "intersection = #{intersection}"
					flag = false
					#if (@board[i][j].confs != [])
					confs.each do |conf2|
						if (intersection.to_set == (conf2 & get_unknown_tiles(i,j)).to_set)
							flag = true
							#puts "#{conf1} is possible"
						end
					end
					if (!flag)
						last_tile = false
						@board[i][j].confs.delete(conf1)
						#puts "deleting #{conf1} from #{[i,j]}"
					end
				end
			end

			#puts "New conf for #{cur_tile.inspect}: #{@board[cur_tile[0]][cur_tile[1]].confs}"
			#puts "New conf for #{[i,j]}: #{@board[i][j].confs}"


			if last_tile
				last_tiles << [i,j]
			else
				#puts "New conf for [#{i},#{j}]: #{@board[i][j].confs}"
				if @board[i][j].confs.size > 0
					@board[i][j].confs.inject{|r,e| r & e}.each do |x,y|
						if (!@board[x][y].known_bomb)
							@board[x][y].known_bomb = true
							puts "[#{x},#{y}] known to be bomb!"
						end
						#remove_from_confs(x,y) #!!!!! no
					end
					(@board[i][j].confs.map{|x| get_unknown_tiles(i,j) - x}.inject{|r,e| r & e}).each do |x,y|
						if (!@board[x][y].known_safe)
							@board[x][y].known_safe = true
							puts "[#{x},#{y}] known to be safe!"
						end
						#remove_from_confs(x,y)
					end
				end
			end
		end

		

		output = affected_tiles-last_tiles

		#puts "affected #{output}"

		return output
	end

	def remove_from_confs(i,j)
		@dirs.each do |d_i,d_j|
			t_i = i+d_i
			t_j = j+d_j

			if (inbounds(t_i,t_j) && @board[t_i][t_j].flipped)
				t_confs = Array.new(@board[t_i][t_j].confs)
				t_confs.each do |c|
					#puts "conf: #{c}"
					if c.include?([i,j])
						#puts "deleting #{c} from #{[t_i,t_j]}"
						@board[t_i][t_j].confs.delete(c)
					end
				end
				#puts "new confs for #{[t_i,t_j]}: #{@board[t_i][t_j].confs}"
			end
		end
	end

	def get_affected_tiles(i,j,explored_tiles)
		affected_tiles = []
		[[0,0]].concat(@dirs).each do |d_i1,d_j1|
			@dirs.each do |d_i2,d_j2|
				t_i = i+d_i1+d_i2
				t_j = j+d_j1+d_j2

				if (inbounds(t_i,t_j) && @board[t_i][t_j].flipped && !affected_tiles.include?([t_i,t_j]) && !explored_tiles.include?([t_i,t_j]))
					# puts "adding #{[t_i,t_j]}"
					affected_tiles << [t_i,t_j]
				end
			end
		end
		return affected_tiles
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