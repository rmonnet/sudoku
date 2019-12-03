
#
# = An algorithm to solve Sudoku problems
#
# version 1.0
#
# @copyright 2005 Robert Monnet
#
# This algorithm attempts to solve Sudoku problems efficiently, that is with the
# smallest number of attempts.
#
# More details about Sudoku can be found at http://www.sudoku.com
#
# == The Game
# Sudoku is played with a 9x9 grid. Each grid location contains a number between 1 and 9.
# At the beginning of the game a partially filled-in grid is provided. The goal is to 
# complete the grid such that:
# * each row contains all numbers 1 to 9
# * each column contains all numbers 1 to 9
# * each 3x3 sub-grid contains all numbers 1 to 9
#
# The following example shows a Sudoku problem:
#   . . .  2 . 9  . . .
#   5 . .  . . .  . . 3
#   2 8 .  . 6 .  . 1 5
#
#   . 1 2  . . .  3 8 .
#   . 5 .  7 . 1  . 6 .
#   . 6 3  . . .  5 7 .
#
#   4 2 .  . 1 .  . 5 9
#   6 . .  . . .  . . 7
#   . . .  5 . 7  . . .
#
# and the solution for this is:
#
#   3 7 1  2 5 9  6 4 8
#   5 4 6  1 7 8  2 9 3
#   2 8 9  4 6 3  7 1 5
#
#   7 1 2  6 9 5  3 8 4
#   8 5 4  7 3 1  9 6 2
#   9 6 3  8 4 2  5 7 1
#
#   4 2 7  3 1 6  8 5 9
#   6 3 5  9 8 4  1 2 7
#   1 9 8  5 2 7  4 3 6
#
# == The Algorithm
#
# === Definitions
# before we describe algorithms to solve the Sudoku problem we need to define some
# vocabulary:
#
# Grid::
#           The 9x9 matrix which contains the numbers from 1 to 9
# Location::
#           A point on the Grid defined by its coordinates (row,col) and its value.
#           If the location already contained a number it is said to be _defined_,
#           _undefined_ otherwise
# Box::
#           A 3x3 sub-grid, they are also defined by theirs coordinates (row,col).
#
# Possibility::
#           The set of all possible valid value that an undefined location can take.
#           This is represented by an instance of the Poss class. It contains the
#           location coordinate and the set of valid possible values
# Depth::
#           This is used to designate the number of values in a Possibility. A Depth of
#           1 means that only one new Problem can be derived from the current one if this
#           location is populated.
# Step::
#           A Step is the action of creating a new problem from a _parent_ problem by
#           setting the value of an undefined location. A Solution is obtained from an
#           original problem and a set of steps. A Step is represented by an instance of
#           the class Step
# Degree Of Freedom::
#           This is a measure of how many _undefined_ locations are contained in a 
#           problem.
# Complete Problem::
#           A problem is said to be complete if all locations are _defined_.
#
# === Algorithm
# The Algorithm used is as follow:
# * start with a priority queue seeded with the initial problem
# * The priority queue is sorted by ascending max_poss then ascending degree of freedom
#   such that the top of the queue contains the possibilities with the minimum depth.
# * If at least one possibility of depth 1 exists, then all the depth 1 possibilities are
#   used at once to derive a new child problem.
# * If the minimum depth is greater than 1, then each possible problem derived from the
#   min depth possibilities is generated and pushed on the queue.
# * If the problem at the top of the queue is not complete (does not have any
#   possibility) or is impossible (location conflict), discard it
# * Continue until a solution is found (_complete_ problem) or the maximum number of
#   iteration has been reached.
#
# === Performances
# So how does this algorithm perform?. On the few examples of problems I have, it can
# find a solution in less iterations than the initial problem "degree of freedom".
#
# === Limitations
# This algorithm find only one solution if several exists. Also it does not help generate
# problems in the first place. The {Sudoku web site}[http://www.sudoku.com] claims that
# all its problems only have one solution. It would be interested to modify this
# algorithm to find all the solutions for a particular problem.
#

require 'set'
require 'net/http'

#
# a Helper class that describes a Step. a Step consists of assigning a value to a
# location. It contains a location (row,col) and the value that is use to fill it.
#
class Step

    attr_reader :row, :col, :value

    def initialize(row, col, value)
        @row, @col, @value = row, col, value
    end

    def to_s
        "(#{@row},#{@col})=>#{@value}"
    end
end

#
# a Helper class that describes a Possibility, i.e. a set of possible values for a
# location. It contains a location (row,col) and the set of possible values to fill-it
#
class Poss

    attr_reader :row, :col, :nrow, :ncol, :nbox

    def initialize(r, c, row, col, box)
        @row, @col = r, c
        @poss = (row & col & box).to_a.sort
        @nrow, @ncol, @nbox = row.length, col.length, box.length
    end

    #
    # Specify the number of possible values associated with this Possibility
    #
    def length
        @poss.length
    end

    def to_s
        nr, nc, nb = @nrow, @ncol, @nbox
        "(#{@row},#{col})=>[#{@poss.join(",")}] (#{nr}*#{nc}*#{nb}=#{nr*nc*nb})"
    end

    #
    # iterate on each value associated with the Possibility
    #
    def each(&block)
        @poss.each(&block)
    end

    #
    # get the first value associated with this possibility
    #
    def first
        @poss[0]
    end

    #
    # return the smallest constraint on the row, column and box this possibility
    # is associated with
    #
    def min_poss
        [@nrow, @ncol, @nbox].min
    end

    #
    # return the total number of possibilities this possibility controls
    #
    def total_poss
        @nrow * @ncol * @nbox
    end

    #
    # return an array containing the possibilities associated with this object
    def to_a
        @poss
    end

end

#
# a Helper class representing the Sudoku grid
#
class Grid

    def initialize(array)
        #ensure array is an Array
        array = array.to_a if array.kind_of? Grid
        # check this is a rectangular array
        ncols = array[0].length
        array.each{ |row| raise "Array must be rectangular" unless row.length == ncols }
        #get a deep copy
        @array = []
        array.each { |row| @array.push(row.dup) }
    end

    def to_a
        @array
    end

    def [](r,c)
        @array[r][c]
    end

    def []=(r ,c, val)
        @array[r][c] = val
    end

    def ==(other)
        @array == other.array
    end

    def number_rows
        @array.length
    end

    def number_cols
        @array[0].length
    end

    def inspect
        res = "["
        @array.each_index do |i|
            res += " " unless i == 0
            res += "[#{@array[i].join(", ")}]"
            res += ",\n" unless i+1 == @array.length
        end
        res += "]\n"
        res
    end

    def to_s(row_sep=1000, col_sep=1000)
        res = "\n"
        @array.each_index do |i|
            res += " "
            row = @array[i]
            row.each_index do |j|
                res += row[j] == 0 ? ". " : "#{row[j]} "
                res += " " if (j % 3) == (row_sep - 1)
            end
            res += "\n"
            res += "\n" if (i % 3) == (col_sep - 1)
        end
        res
    end

    #
    # count how many time a number is contained in the grid
    #
    def number_of(val)
        res = 0
        @array.each { |row| row.each { |v| res +=1 if v == val } }
        res
    end

    protected

    attr_reader :array

end

#
# The main class for Sudoku. It contains a problem (9x9 grid) partially solved and
# associated data such as the list of all possible values for all locations.
#
# In Ruby's tradition, grid index starts at 0.
#
class Sudoku

    #
    # Show the set of steps used to fill-in this problem
    #
    attr_reader :steps

    #
    # retrieve the grid associated with the Sudoku
    #
    attr_reader :grid

    #
    # create a new problem. If a parent is given, then the new problem starts with the 
    # parent values, if not all locations are empty. The list of partial solution is then
    # added to the problem. Each solution is described as a triplet [row, col, value].
    #
    # :call-seq:
    #   Sudoku.new([[1,1,9]]) -> Sudoku problem with one value (9) at location (1,1)
    #   Sudoku.new([[1,1,9]], parent) -> Sudoku problem similar to parent but with value 9 filled-in at location (1,1)
    #
    def initialize(grid, prev_steps=nil, new_steps=nil)

        @grid = Grid.new(grid)
        raise "number of rows must be 9" unless @grid.number_rows
        raise "number of columns must be 9" unless @grid.number_cols
        @steps = (prev_steps or [])

        if new_steps then
            new_steps.each do |step|
                @grid[step.row, step.col] = step.value
                @steps.push(step)
            end
        end

        validate
    end

    def to_s
        @grid.to_s(3, 3)
    end

    #
    # test if two problems are identicals. This test if the grids are identical,
    # regardless of the order in which the locations were filled-in. This is useful
    # to detect duplicate problems when solving.
    #
    def ==(other)
        @grid == other.grid
    end

    #
    # provides a max boundary for the number of possible derived problems.
    # computed as the product of the number of possibilities for each location
    #
    def max_poss
        res = 1
        @poss.each { |p| res *= p.length }
        res
    end

    #
    # provides the minimum depth associated with this problem possibilities
    #
    def min_depth
        return 0 if @poss.empty?
        @poss[0].length
    end

    #
    # provides the number of locations not filled-in for a problem
    #
    def dof
        @grid.number_of(0)
    end

    #
    # iterate on the possibilities associated with this problem (limited to depth
    # equal or less than +max-depth+).
    #
    def each_poss(max_depth=9)
        @poss.each do |p|
            break if p.length > max_depth
            yield p
        end
    end

    def sorted_poss(&sort_criteria)
        @poss.sort(&sort_criteria)
    end

    #
    # test if a problem is complete (all locations are filled-in)
    #
    def complete?
        @poss.empty?
    end

    #
    # provides statistics on a problem
    #
    def show_stats
        res = "\n"
        res += "#{@grid}\n"
        res += "initial problem + #{@steps.join(" + ")}\n"
        res += "max_poss         : #{max_poss}\n"
        res += "min_depth        : #{min_depth}\n"
        res += "degree_of_freedom: #{dof}\n"
        each_poss(min_depth) { |poss| res += "#{poss}\n" }
        res += "\n"
        res
    end

    def analyze
        res = "\n"
        res +="poss:\n"
        @poss.each do |p|
            res += "  #{p}\n"
        end
        @rows.each_index do |r|
            res += "row##{r}: [#{@rows[r].to_a.sort.join(", ")}]\n"
        end
        @cols.each_index do |c|
            res += "col##{c}: [#{@cols[c].to_a.sort.join(", ")}]\n"
        end
        @box.each_index do |r|
            subrow = @box[r]
            subrow.each_index do |c|
                res += "box##{r}-#{c}: [#{subrow[c].to_a.sort.join(", ")}]\n"
            end
        end

        (0..8).each do |r|
            graph = []
            (0..8).each do |c|
                graph.push("{#{@poss_grid[r][c].join(", ")}}")
            end
            res += "row##{r}: [#{graph.join(", ")}]\n"
        end
        (0..8).each do |c|
            graph = []
            (0..8).each do |r|
                graph.push("{#{@poss_grid[r][c].join(", ")}}")
            end
            res += "col##{c}: [#{graph.join(", ")}]\n"
        end
        (0..2).each do |r|
            (0..2).each do |c|
                graph = []
                (0..2).each do |rb|
                    (0..2).each do |cb|
                        graph.push("{#{@poss_grid[r*3+rb][c*3+cb].join(", ")}}")
                    end
                end
                res += "box##{r}-#{c}: [#{graph.join(", ")}]\n"
            end
        end

        res
    end

    private

    #
    # Check if a problem is valid, compute the set of possibilities associated with it 
    # (called from the constructor).
    #
    def validate

        entireSet = Set.new([1, 2, 3, 4, 5, 6, 7, 8, 9])

        @rows = []
        9.times { @rows.push(entireSet.dup) }

        @cols = []
        9.times { @cols.push(entireSet.dup) }

        @box = []
        3.times do
            subrow = []
            3.times { subrow.push(entireSet.dup) }
            @box.push(subrow)
        end

        (0..8).each do |i|
            (0..8).each do |j|
                v = @grid[i,j]
                if v > 0
                    raise "dup number in row #{i} : #{v}" unless @rows[i].delete?(v)
                    raise "dup number in column #{j} : #{v}" unless @cols[j].delete?(v)
                    raise "dup number in box #{i/3}-#{j/3} : #{v}" unless @box[i/3][j/3].delete?(v)
                end
            end
        end

        @poss = []
        @poss_grid = []
        (0..8).each do |i|
            poss_row = []
            (0..8).each do |j|
                if @grid[i,j] == 0 then
                    p = Poss.new(i, j, @rows[i], @cols[j], @box[i/3][j/3])
                    @poss.push(p)
                    poss_row.push(p.to_a)
                else
                    poss_row.push([])
                end
            end
            @poss_grid.push(poss_row)
        end
        @poss.sort! { |x, y| x.length <=> y.length }

    end

end

#
# Class used to solve a Sudoku problem, it can be solved all at once or step by step
#
class Solver

    MAX_ITER = 10000

    attr_reader :initial_problem, :nb_try, :nb_dup, :nb_discard, :nb_iter
    attr_reader :duration
    #
    # set up the solver, assign an initial problem
    #
    def initialize(problem)
        @initial_problem = problem
        @pb_list = [problem]
        @nb_try = 0
        @nb_dup = 0
        @nb_discard = 0
        @nb_iter = 0
        @duration = 0.0
        @rejected_grids = []
    end

    def analyze
        return if @pb_list.empty?
        @pb_list[0].analyze
    end

    def status

        return "solution found iter##{nb_iter}  bktrk=#{@nb_discard}  qs=#{@pb_list.length}  rj=#{@rejected_grids.length}" if solution
        return "no solution" if @pb_list.empty?
        return "max iter. exceeded" if @nb_iter >= MAX_ITER
        dof = best_problem ? " dof=#{best_problem.dof}" : ""
        "iter##{@nb_iter}  #{dof}  bktrk=#{@nb_discard}  qs=#{@pb_list.length}  rj=#{@rejected_grids.length}"
    end

    def show_state

        res = "\n"
        res += "initial problem is\n#{@initial_problem}\n"

        if solution then
            res += "solution is\n#{solution}\n"
        elsif @pb_list.empty? then
            res += "no solution\n"
        elsif @nb_iter >= MAX_ITER
            res += "max number of iterations exceeded\n"
        else
            res += "solution not found yet\n"
        end

        res += "initial dof           = #{@initial_problem.dof}\n"
        res += "max possibilities     = #{@initial_problem.max_poss}\n"
        res += "nb iterations         = #{@nb_iter}\n"
        res += "nb problems computed  = #{@nb_try}\n"
        res += "nb duplicates         = #{@nb_dup}\n"
        res += "nb problems discarded = #{@nb_discard}\n"
    end

    #
    # return the current best problem
    #
    def best_problem
        return nil if @pb_list.empty?
        @pb_list[0]
    end

    #
    # return the solution if one was found
    #
    def solution
        if @pb_list.empty? then
            return nil
        elsif @pb_list[0].complete? then
            return @pb_list[0]
        else
            return nil
        end
    end

    #
    # remove the solution if one was found so we can try for other ones
    #
    def pop_solution
        return nil if @pb_list.empty?
        return nil if not @pb_list[0].complete?
        return @pb_list.shift
    end

    #
    # check if the solver is done
    #
    def done?
        @pb_list.empty? or @nb_iter >= MAX_ITER or @pb_list[0].complete?
    end

    #
    # return the number of problems currently on the queue
    #
    def nb_problems
        return @pb_list.length
    end

    #
    # perform one iteration of the Sudoku problem. Return the current problem
    # at the top of the queue. If the queue is empty, return nil
    #
    def step0(debug=false)

        # make sure we don't step beyond the solution
        return nil if done?

        t0 = Time.now
        @nb_iter += 1

        puts "+++iteration #{@nb_iter}+++" if debug
        puts "nb problems = #{@pb_list.length}" if debug

        best_pb = @pb_list.shift
        @rejected_grids.push(best_pb.grid)

        puts "best problem:" if debug
        puts best_pb.show_stats if debug

        if best_pb.min_depth == 1 then

            # we can create a problem with all the steps included at once
            new_steps = []
            best_pb.each_poss(1) do |poss|
                new_steps.push(Step.new(poss.row, poss.col, poss.first))
            end
            @nb_try += 1
            begin
                child = Sudoku.new(best_pb.grid, best_pb.steps, new_steps)
                #if the new problem is a dead-end, discard it
                if child.max_poss == 0 and not child.complete? then
                    puts "No solution possible for best problem, discard it" if debug
                    @rejected_grids.push(child.grid)
                    @nb_discard += 1
                #avoid duplicates
                elsif @pb_list.include?(child)
                    @nb_dup += 1
                elsif @rejected_grids.include?(child.grid)
                    # this problem has been processed before
                    @nb_discard += 1
                else
                    @pb_list.push(child)
                end
            rescue RuntimeError
                # the combination of depth=1 solution caused a conflict
                puts "Impossible solution for best problem, discard it" if debug
                @nb_discard += 1
            end
        else

            # we need to create a new problem for each possibility
            best_pb.each_poss(best_pb.min_depth) do |poss|
                poss.each do |v|
                    @nb_try += 1
                    new_steps = [Step.new(poss.row, poss.col, v)]
                    child = Sudoku.new(best_pb.grid, best_pb.steps, new_steps)
                    #if the new problem is a dead-end, discard it
                    if child.max_poss == 0 and not child.complete? then
                        puts "No solution possible for best problem, discard it" if debug
                        @rejected_grids.push(child.grid)
                        @nb_discard += 1
                    #avoid duplicates
                    elsif @pb_list.include?(child)
                        @nb_dup += 1
                    elsif @rejected_grids.include?(child.grid)
                        # this problem has been processed before
                        @nb_discard += 1
                    else
                        @pb_list.push(child)
                    end
                end
            end
        end

        # resort the list by max_poss / min_dof
        @pb_list.sort! do |x,y|
            res = x.max_poss <=> y.max_poss
            res = x.dof <=> y.dof if res == 0
            res
        end

        @duration += Time.now - t0

        #return the solution if we have one
        if @pb_list.empty? then
            return null
        else
            return @pb_list[0]
        end

    end


    #
    # solve the Sudoku problem p. If debug is true, steps of the computation 
    # are displayed on screen
    #
    def solve0(show_res=true, debug=false)

        while not done?
            step0(debug)
        end

        if show_res or debug then
            puts show_state
            puts "computed in             #{@duration} sec"
        end

        solution
    end

    #
    # perform one iteration of the Sudoku problem. Return the current problem
    # at the top of the queue. If the queue is empty, return nil
    #
    def step(debug=false)

        # make sure we don't step beyond the solution
        return nil if done?

        t0 = Time.now
        @nb_iter += 1

        puts "+++iteration #{@nb_iter}+++" if debug
        puts "nb problems = #{@pb_list.length}" if debug

        best_pb = @pb_list.shift
        @rejected_grids.push(best_pb.grid)

        puts "best problem:" if debug
        puts best_pb.show_stats if debug

        if best_pb.min_depth == 1 then

            # we can create a problem with all the steps included at once
            new_steps = []
            best_pb.each_poss(1) do |poss|
                new_steps.push(Step.new(poss.row, poss.col, poss.first))
            end
            @nb_try += 1
            begin
                child = Sudoku.new(best_pb.grid, best_pb.steps, new_steps)
                #if the new problem is a dead-end, discard it
                if child.max_poss == 0 and not child.complete? then
                    puts "No solution possible for best problem, discard it" if debug
                    @rejected_grids.push(child.grid)
                    @nb_discard += 1
                #avoid duplicates
                elsif @pb_list.include?(child)
                    @nb_dup += 1
                elsif @rejected_grids.include?(child.grid)
                    # this problem has been processed before
                    @nb_discard += 1
                else
                    @pb_list.push(child)
                end
            rescue RuntimeError
                # the combination of depth=1 solution caused a conflict
                puts "Impossible solution for best problem, discard it" if debug
                @nb_discard += 1
            end
        else

            # we will just process the problem that reduce the most the possibilities
            # on its row, col and box
            poss_list = best_pb.sorted_poss { |x, y| x.min_poss <=> y.min_poss }
            poss = poss_list[0]
            poss.each do |v|
                @nb_try += 1
                new_steps = [Step.new(poss.row, poss.col, v)]
                child = Sudoku.new(best_pb.grid, best_pb.steps, new_steps)
                #if the new problem is a dead-end, discard it
                if child.max_poss == 0 and not child.complete? then
                    puts "No solution possible for best problem, discard it" if debug
                    @rejected_grids.push(child.grid)
                    @nb_discard += 1
                #avoid duplicates
                elsif @pb_list.include?(child)
                    @nb_dup += 1
                elsif @rejected_grids.include?(child.grid)
                    # this problem has been processed before
                    @nb_discard += 1
                else
                    @pb_list.push(child)
                end
            end
        end

        # resort the list by max_poss / min_dof
        @pb_list.sort! do |x,y|
            res = x.max_poss <=> y.max_poss
            res = x.dof <=> y.dof if res == 0
            res
        end

        @duration += Time.now - t0

        #return the solution if we have one
        if @pb_list.empty? then
            return nil
        else
            return @pb_list[0]
        end

    end


    #
    # solve the Sudoku problem p. If debug is true, steps of the computation 
    # are displayed on screen
    #
    def solve(show_res=true, debug=false)

        while not done?
            step(debug)
        end

        if show_res or debug then
            puts show_state
            puts "computed in             #{@duration} sec"
        end

        solution
    end

end

#
# get a grid from websudoku.com
# level 1..4 = easy, medium, hard, evil
#
def get_puzzle_grid(level)

    #get a random grid
    page = Net::HTTP.get_response("show.websudoku.com", "?select&level=#{level}")

    #find the puzzle number for reference
    page.body =~ /Puzzle (.*?) /
    puzzle_id = $1

    #the puzzle is in a giant table
    page.body =~ /<TABLE .*?>(.*)?<\/TABLE>/
    table = $1

    # each cell has ID=cxy where x is column, y is row
    grid = []
    (0..8).each do |r|
        row = []
        (0..8).each do |c|
            table =~ /<TD CLASS=.. ID=c#{c}#{r}>(.*?)<\/TD>/
            cell = $1
            cell =~ /READONLY VALUE="(\d)"/
            if cell
                row.push($1.to_i)
            else
                row.push(0)
            end
        end
        grid.push(row)
    end

    return grid
end

if __FILE__ == $0

    dec05 = Sudoku.new(
        [[0, 0, 0, 2, 0, 9, 0, 0, 0],
         [5, 0, 0, 0, 0, 0, 0, 0, 3],
         [2, 8, 0, 0, 6, 0, 0, 1, 5],
         [0, 1, 2, 0, 0, 0, 3, 8, 0],
         [0, 5, 0, 7, 0, 1, 0, 6, 0],
         [0, 6, 3, 0, 0, 0, 5, 7, 0],
         [4, 2, 0, 0, 1, 0, 0, 5, 9],
         [6, 0, 0, 0, 0, 0, 0, 0, 7],
         [0, 0, 0, 5, 0, 7, 0, 0, 0]])

    Solver.new(dec05).solve(true)

    jan06 = Sudoku.new(
        [[0, 0, 7, 8, 0, 5, 2, 0, 0],
         [8, 0, 0, 6, 0, 4, 0, 0, 5],
         [0, 1, 0, 0, 9, 0, 0, 8, 0],
         [4, 0, 0, 2, 8, 9, 0, 0, 7],
         [0, 0, 0, 0, 0, 0, 0, 0, 0],
         [5, 0, 0, 7, 6, 1, 0, 0, 2],
         [0, 7, 0, 0, 3, 0, 0, 6, 0],
         [3, 0, 0, 1, 0, 6, 0, 0, 4],
         [0, 0, 2, 5, 0, 8, 1, 0, 0]])

    Solver.new(jan06).solve(true)

    hmpage = Sudoku.new(
        [[0, 6, 0, 1, 0, 4, 0, 5, 0],
         [0, 0, 8, 3, 0, 5, 6, 0, 0],
         [2, 0, 0, 0, 0, 0, 0, 0, 1],
         [8, 0, 0, 4, 0, 7, 0, 0, 6],
         [0, 0, 6, 0, 0, 0, 3, 0, 0],
         [7, 0, 0, 9, 0, 1, 0, 0, 4],
         [5, 0, 0, 0, 0, 0, 0, 0, 2],
         [0, 0, 7, 2, 0, 6, 9, 0, 0],
         [0, 4, 0, 5, 0, 8, 0, 7, 0]])

    Solver.new(hmpage).solve(true, false)

end
