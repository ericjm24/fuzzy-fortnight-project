function doot()
    edge_file = "data/twitter_rv.net"
    out_file = "data/twitter_gephi.csv"
    file = open(edge_file, "r")
    out_f = open(out_file, "w")
    line = readline(file)
    a,b = split(line, '\t')
    a0 = chomp(a)
    b0 = chomp(b)
    write(out_f, a0*','*b0)
    while !eof(file)
        a,b = split(line, '\t')
        a = chomp(a)
        b = chomp(b)
        if a == a0
            write(out_f, ','*b)
        else
            write(out_f, '\n'*a*','*b)
            a0 = a
        end
    end
    close(file)
    close(out_f)
end

doot()