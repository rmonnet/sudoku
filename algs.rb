
def pile_exclusion(nodes)

    dim = nodes.length

    puts "processing #{nodes_to_s(nodes)}..."
    (1...dim).each do |i|
        matching_nodes_idx = []
        nodes.each_index do |idx|
            matching_nodes_idx.push(idx) if nodes[idx].include? i
        end
        #puts "nodes index for #{i} are #{matching_nodes_idx.join(",")}"
        pile = []
        nb_matching_nodes = matching_nodes_idx.length

        (1...dim).each do |j|
            nb_match = 0
            matching_nodes_idx.each do |idx|
                nb_match += 1 if nodes[idx].include? j
            end
            pile.push(j) if nb_match == nb_matching_nodes
        end
        if pile.length > 0 and pile.length == nb_matching_nodes then
            #puts "found pile: [#{pile.join(", ")}]"
            #replace the given nodes with the matching subset
            matching_nodes_idx.each do |idx|
                nodes[idx] = pile
            end
        end

    end
    puts "result     #{nodes_to_s(nodes)}"

end

def nodes_to_s(nodes)
    node_s = []
    nodes.each { |node| node_s.push("{#{node.join(",")}}") }
    "[#{node_s.join(", ")}]"
end

if __FILE__ == $0

    nodes = [[1,2,3,5], [3,6], [3,4], [5,6], [1,7,8,9], [4,6], [5,7,8,9], [4,6],
             [6,7,8,9], [1,4]]

    pile_exclusion(nodes)

end

