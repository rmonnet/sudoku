
require 'net/http'


page = Net::HTTP.get_response("show.websudoku.com", "?select&level=4")

page.body =~ /Puzzle (.*?) /
puzzle_id = $1

page.body =~ /<TABLE .*?>(.*)?<\/TABLE>/
table = $1

grid = []
(0..8).each do |r|
    row = []
    (0..8).each do |c|
        table =~ /<TD CLASS=.. ID=c#{c}#{r}>(.*?)<\/TD>/
        cell = $1
        puts $1
        cell =~ /READONLY VALUE="(\d)"/
        if cell
            row.push($1.to_i)
        else
            row.push(0)
        end
    end
    grid.push(row)
end

puts "puzzle # #{puzzle_id}"
puts grid.inspect

