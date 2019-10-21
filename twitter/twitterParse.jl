
function lineParse(s::String)
    x,y = split(chomp(s), '\t')
    return (parse(UInt32, x), parse(UInt32, y))
end


function DoIt()
    inFileName = "data/twitter_rv.net"
    outFollowName = "data/followers"
    outFriendsName = "data/friends"

    BUFFER_SIZE_8 = Int64(2000000000) #4 GB buffer
    BUFFER_SIZE_32 = Int64(BUFFER_SIZE_8/4) #1 billion 32-bit integers
    BUFFER_SIZE_64 = Int64(BUFFER_SIZE_32/2) #500 million 64-bit integers or pairs of 32-bit integers

    outBuffer = Array{UInt64,1}(undef, BUFFER_SIZE_32)

    k = 1
    k_pages = 1
    inFile = open(inFileName, "r")
    for s in eachline(inFile)
        if k%100000 == 0
            println(k)
        end
        x,y = lineParse(s)
        outBuffer[k] = reinterpret(UInt64, [x,y])[1]
        if (k == BUFFER_SIZE_64) || (eof(inFile))
            outFile = open(outFollowName * "_" * string(k_pages, base=10), "w")
            write(outFile, outBuffer[1:k])
            close(outFile)
            k = 1
            k_pages += 1
        else
            k += 1
        end
    end
    close(inFile)
end
DoIt()
