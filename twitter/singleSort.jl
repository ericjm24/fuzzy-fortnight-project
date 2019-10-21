function singleSort(filename)
    file = open(filename, "r")
    seekend(file)
    fSize = Int64(position(file)/8)
    seekstart(file)
    out = Array{UInt64, 1}(undef, fSize)
    read!(file, out)
    close(file)

    sort!(out)

    file = open(filename, "w")
    write(file, out)
    close(file)
end

pages = 6
for k = 1:pages
    name = "data/followers_" * string(k, base=10)
    singleSort(name)
    println(k)
end
