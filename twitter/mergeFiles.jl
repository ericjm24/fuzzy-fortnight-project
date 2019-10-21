function findMinimum(x::Array{UInt64,1}, doIt::Array{Int64,1})
    temp = typemax(UInt64)
    k = UInt64(0)
    for j = 1:length(x)
        if doIt[j] > 0 && x[j] < temp
            temp = x[j]
            k = j
        end
    end
    return temp, k
end

function mergeFiles()
    inFileName = "data/followers_"
    outFileName = "data/followers"
    pages = Int64(6)
    MAX_SIZE = Int64(25000000)
    OUT_SIZE = Int64(MAX_SIZE*4)


    buffer = Array{UInt64, 1}(undef, MAX_SIZE)
    out = Array{UInt64, 2}(undef, MAX_SIZE, pages)
    outBuffer = Array{UInt64,1}(undef, OUT_SIZE)
    startIndex = Array{Int64, 1}(undef, pages)
    finIndex = Array{Int64, 1}(undef, pages)
    posArray = Array{Int64, 1}(undef, pages)
    temp = Array{UInt64, 1}(undef, pages)
    doIt = Array{Int64,1}(undef,pages)
    for k = 1:pages
        println("Loading page " * string(k, base=10))
        fileName = inFileName * string(k, base=10)
        file = open(fileName,"r")
        read!(file, buffer)
        if eof(file)
            posArray[k] = -1
            finIndex[k] = Int64(position(file)/8)
        else
            posArray[k] = position(file)
            finIndex[k] = MAX_SIZE
        end
        close(file)
        doIt[k] = 1
        startIndex[k] = 1
        temp[k] = buffer[1]
        out[:,k] = buffer
    end

    n = Int64(1)
    cur, j = findMinimum(temp, doIt)
    while j > 0
        outBuffer[n] = cur
        startIndex[j] += 1
        if startIndex[j] > finIndex[j]
            if posArray[j] < 0
                doIt[j] = -1
                println("Finished with page " *string(j, base=10))
            else
                println("Loading page " * string(j, base=10))
                fileName = inFileName * string(j, base=10)
                file = open(fileName, "r")
                seekend(file)
                nItems = Int64((position(file) - posArray[j])/8)
                seek(file, posArray[j])
                if nItems < MAX_SIZE
                    tbuf = Array{UInt64,1}(undef, nItems)
                    read!(file, tbuf)
                    buffer[1:nItems] = tbuf
                    finIndex[j] = Int64((position(file) - posArray[j])/8)
                    posArray[j] = -1
                else
                    read!(file, buffer)
                    posArray[j] = position(file)
                    finIndex[j] = MAX_SIZE
                end
                close(file)
                temp[j] = buffer[1]
                startIndex[j] = 1
                out[:,j] = buffer
            end
        else
            temp[j] = out[startIndex[j], j]
        end
        n += 1
        if n > OUT_SIZE
            file = open(outFileName, "a")
            write(file, outBuffer)
            close(file)
            n = 1
        end
        cur, j = findMinimum(temp, doIt)
    end
    out = nothing
    buffer = nothing
    if n > 1
        n -= 1
        file = open(outFileName, "a")
        write(file, outBuffer[1:n])
        close(file)
    end
end

mergeFiles()
