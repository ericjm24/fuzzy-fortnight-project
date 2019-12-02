indexFile = "data/twitter_index"
friendsFile = "data/friends_small_indexed"
followersFile = "data/followers_small_indexed"
maxBuff = Int64(125000000)

struct twitterID
    id::UInt32
    followers::UInt32
    followersPosition::UInt64
    friends::UInt32
    friendsPosition::UInt64
end

function readIndexFile()
    file = open(indexFile, "r")
    numElements = Int64(read(file, UInt32))
    out = Vector{twitterID}(undef, numElements)
    temp = Vector{UInt32}(undef, 7)
    for k = 1:numElements
        read!(file, temp)
        out[k] = twitterID(temp[1], temp[2], reinterpret(UInt64, temp[3:4])[1], temp[5], reinterpret(UInt64, temp[6:7])[1])
    end
    return out
end

function printUser(user::twitterID)
    println("User ID: " * string(user.id, base=10))
    println("Followers: " * string(user.followers, base=10))
    println("Friends: " * string(user.friends, base=10))
end

function randUser(userArray::Vector{twitterID})
    numUsers = length(userArray)
    return userArray[Int64(ceil(rand()*numUsers))]
end

function readFollowers(user::twitterID)
    file = open(followersFile, "r")
    seek(file, user.followersPosition)
    output = Vector{UInt32}(undef, user.followers)
    read!(file, output)
    close(file)
    return output
end

function readFriends(user::twitterID)
    file = open(friendsFile, "r")
    seek(file, user.friendsPosition)
    output = Vector{UInt32}(undef, user.friends)
    read!(file, output)
    close(file)
    return output
end

function sparseAdjacencyMultiplyMV(M::Vector{UInt32}, V::Vector)
    out = zeros(typeof(V[1]), length(V))
    ind = M[1]
    k = 2
    L = length(M)
    while k <= L
        a = M[k]
        if a != 0
            out[a] += V[ind]
            k += 1
        else
            k += 1
            if k > L
                break
            end
            ind = M[k]
            k += 1
        end
    end
    return out
end

function loadToChannel(c::Channel, inFileName::String)
    file = open(inFileName)
    while !eof(file)
        put!(c, read(file, UInt32))
    end
    close(file)
end
function calculateOnChannel(c, V::Vector{Float64}, maxNums::Int64)
    outVec = zeros(length(V))
    bDefined = false
    index=0::Int64
    wait(c)
    bContinue = true
    itm = 0::Int64
    kRead = 0
    tempTot = 0.0
    while kRead < maxNums
        try
            itm = take!(c)
        catch
            break
        end
        if bDefined == false && itm != 0
            index = itm
            bDefined = true
            tempTot = 0.0
        elseif itm == 0
            bDefined = false
            outVec[index] = tempTot
        else
            tempTot += V[itm]
        end
        kRead += 1
    end
    return outVec
end
function sparseAdjacencyMultiplyMV(inFileName::String, V::Vector{Float64})
    file = open(inFileName, "r")
    seekend(file)
    numP = Int64(position(file)/4)
    close(file)
    c = Channel{UInt32}(500)
    @async loadToChannel(c, inFileName)
    outVec = fetch(@async calculateOnChannel(c, V, numP))
    close(c)
    return outVec
end

function calculateOnChannelt(c, V::Vector{Float64}, maxNums::Int64)
    outVec = zeros(length(V))
    bDefined = false
    index=0::Int64
    wait(c)
    bContinue = true
    itm = 0::Int64
    kRead = 0
    while kRead < maxNums
        try
            itm = take!(c)
        catch
            break
        end
        if bDefined == false && itm != 0
            index = itm
            bDefined = true
        elseif itm == 0
            bDefined = false
        else
            outVec[itm] += V[index]
        end
        kRead += 1
    end
    return outVec
end
function sparseAdjacencyMultiplyMtV(inFileName::String, V::Vector{Float64})
    file = open(inFileName, "r")
    seekend(file)
    numP = Int64(position(file)/4)
    close(file)
    c = Channel{UInt32}(500)
    @async loadToChannel(c, inFileName)
    outVec = fetch(@async calculateOnChannelt(c, V, numP))
    close(c)
    return outVec
end

function normalizeV(inVector::Vector{Float64})
    inVector = copy(inVector)
    mag = 0.0
    for k = 1:length(inVector)
        temp = inVector[k]
        mag += (temp*temp)
    end
    mag = sqrt(mag)
    for k = 1:length(inVector)
        inVector[k] /= mag
    end
    return inVector
end

function randV(vecLength::Int64)
    out = Vector{Float64}(undef, vecLength)
    for k = 1:vecLength
        out[k] = rand()
    end
    return normalizeV(out)
end

function userIndexToVector(userN::Int64, vecLength::Int64)
    out = zeros(vecLength)
    out[userN] = 1.0
    return out
end

function userVectorToIndex(userVec::Vector)
    temp = 0::typeof(userVec[1])
    index = 0::Int64
    for k = 1:length(userVec)
        if userVec[k] > temp
            temp = userVec[k]
            index=k
        end
    end
    if temp > 0
        return index
    else
        return 0
    end
end

function dotVV(vec1::Vector{Float64}, vec2::Vector{Float64})
    len = length(vec1)
    if length(vec2) < len
        len = length(vec2)
    end
    out = 0.0
    for k = 1:len
        out += vec1[k]*vec2[k]
    end
    return out
end

function scalarMultSV(scalar, inVector::Vector{Float64})
    inVector = copy(inVector)
    for k = 1:length(inVector)
        inVector[k] *= scalar
    end
    return inVector
end

function calculateErrorVV(vec1::Vector, vec2::Vector)
    temp = 0::Float64
    len = length(vec1)
    if length(vec2) < len
        len = length(vec2)
    end
    for k = 1:len
        t = vec1[k] - vec2[k]
        temp += t*t
    end
    return sqrt(temp/len)
end

function magnitudeSquaredV(vec::Vector)
    temp = 0
    for k in 1:length(vec)
        temp += vec[1]*vec[1]
    end
    return temp
end

function addVV(alpha, VectorAlpha::Vector{Float64}, beta, VectorBeta::Vector{Float64})
    if length(VectorAlpha) == length(VectorBeta)
        VectorAlpha = copy(VectorAlpha)
        for k = 1:length(VectorAlpha)
            VectorAlpha[k] = alpha*VectorAlpha[k] + beta*VectorBeta[k]
        end
        return VectorAlpha
    elseif length(VectorAlpha) < length(VectorBeta)
        VectorBeta = copy(VectorBeta)
        shortLen = length(VectorAlpha)
        for k = 1:length(VectorBeta)
            if k <= shortLen
                VectorBeta[k] = alpha*VectorAlpha[k] + beta*VectorBeta[k]
            else
                VectorBeta[k]*=beta
            end
        end
        return VectorBeta
    else
        VectorAlpha=copy(VectorAlpha)
        shortLen = length(VectorBeta)
        for k = 1:length(VectorAlpha)
            if k <= shortLen
                VectorAlpha[k] = alpha*VectorAlpha[k] + beta*VectorBeta[k]
            else
                VectorAlpha[k] *= beta
            end
        end
        return VectorAlpha
    end
end

function simpleAddVV(VectorAlpha::Vector{Float64}, VectorBeta::Vector{Float64})
    out = copy(VectorAlpha)
    for k in 1:length(VectorAlpha)
        out[k] += VectorBeta[k]
    end
    return out
end

function simpleSubtractVV(VectorAlpha::Vector{Float64}, VectorBeta::Vector{Float64})
    out = copy(VectorAlpha)
    for k in 1:length(VectorAlpha)
        out[k] -= VectorBeta[k]
    end
    return out
end

function distanceVV(vec1::Vector{Float64}, vec2::Vector{Float64}, align)
    dist = 0.0
    for k = 1:length(vec1)
        if align == true
            t = abs(vec1[k]) - abs(vec2[k])
        else
            t = vec1[k] - vec2[k]
        end
        dist += t*t
    end
    return sqrt(dist)
end

function orthogonalizeV(inVec::Vector{Float64}, GSArray::Array{Float64,2})
    inVec = copy(inVec)
    vecLength, numVec = size(GSArray)
    for k = 1:numVec
        inVec = addVV(1.0, inVec, -dotVV(inVec, GSArray[:,k]), GSArray[:,k])
    end
    return inVec
end

function orthonomalizeV(inVec::Vector{Float64}, GSArray::Array{Float64,2})
    return normalizeV(orthogonalizeV(inVec, GSArray))
end


function calculateTransitionOnChannel(c, V::Vector{Float64}, dimVec, maxNums::Int64)
    outVec = zeros(length(V))
    bDefined = false
    index=0::Int64
    wait(c)
    itm = 0::Int64
    kRead = 0
    while kRead < maxNums
        try
            itm = take!(c)
        catch
            break
        end
        if bDefined == false && itm != 0
            index = itm
            bDefined = true
        elseif itm == 0
            bDefined = false
        else
            if dimVec[index] > 0
                outVec[itm] += V[index]/dimVec[index]
            end
        end
        kRead += 1
    end
    return outVec
end

function sparseTransitionMultiplyMV(inFileName::String, V::Vector{Float64}, dimVec)
    file = open(inFileName, "r")
    seekend(file)
    numP = Int64(position(file)/4)
    close(file)
    c = Channel{UInt32}(500)
    @async loadToChannel(c, inFileName)
    outVec = fetch(@async calculateTransitionOnChannel(c,V, dimVec, numP))
    close(c)
    return outVec
end

function calculateDimVecOnChannel(c, veclength, maxNums)
    dimVec = zeros(veclength)
    wait(c)
    bDefined = false
    kRead = 0::Int64
    itm = 0::UInt32
    while kRead < maxNums
        try
            itm = take!(c)
        catch
            break
        end
        if bDefined == false && itm != 0
            bDefined = true
        elseif itm == 0
            bDefined = false
        else
            dimVec[itm] += 1
        end
        kRead += 1
    end
    return dimVec
end

function getDimVec(fileName::String, veclength::Int64)
    file = open(fileName, "r")
    seekend(file)
    numP = Int64(position(file)/4)
    close(file)
    c = Channel{UInt32}(500)
    @async loadToChannel(c, fileName)
    dimVec = fetch(@async calculateDimVecOnChannel(c, veclength, numP))
    close(c)
    return dimVec
end

function getDimVec(fileName::String)
    file = open(fileName, "r")
    max = UInt32(0)
    temp = UInt32(0)
    numP = UInt32(0)
    while !eof(file)
        temp = read(file, UInt32)
        if temp > max
            max = temp
        end
        numP += 1
    end
    close(file)
    c = Channel{UInt32}(500)
    @async loadToChannel(c, fileName)
    dimVec = fetch(@async calculateDimVecOnChannel(c, max, numP))
    close(c)
    return dimVec
end

function getDimVec(M::Vector{UInt32})
    dimVec = zeros(typeof(M[1]), maximum(M))
    k = 2
    while k <= length(M)
        a = M[k]
        if a == 0
            k += 2
        else
            dimVec[a] += 1
            k += 1
        end
    end
    return dimVec
end

function sparseTransitionMultiplyMV(M::Vector{UInt32}, V::Vector{Float64}, dimVec)
    out = zeros(typeof(V[1]), length(V))
    V2 = copy(V)
    for s = 1:length(V2)
        if dimVec[s] == 0
            V2[s] == 0
        else
            V2[s] /= dimVec[s]
        end
    end
    ind = M[1]
    k = 2
    L = length(M)
    while k <= L
        a = M[k]
        if a != 0
            out[a] += V2[ind]
            k += 1
        else
            k += 1
            if k > L
                break
            end
            ind = M[k]
            k += 1
        end
    end
    return out
end

function calculateInfluenceVector_v2(adjacency, inVector::Vector, conductivity::Float64, epsilon::Float64, maxIter)
    out = sparseAdjacencyMultiplyMV(adjacency, copy(inVector))
    dimVec = getDimVec(adjacency)
    temp = scalarMultSV(conductivity, sparseTransitionMultiplyMV(adjacency, out, dimVec))
    len = length(out)
    error = sqrt(dotVV(temp, temp)/len)
    k = 0
    while error > epsilon && k < maxIter
        out = simpleAddVV(out, temp)
        temp = scalarMultSV(conductivity, sparseTransitionMultiplyMV(adjacency, temp, dimVec))
        error = sqrt(magnitudeSquaredV(temp)/len)
        k += 1
    end
    return out
end


function findUser(id::UInt32, userArray::Vector{twitterID})
    kStart = 1
    kEnd = length(userArray)
    if userArray[kStart].id == id
        return userArray[kStart]
    end
    if userArray[kEnd].id == id
        return userArray[kEnd]
    end
    n = 1
    while n < 10000
        kTemp = Int64(floor((kStart + kEnd)/2))
        if userArray[kTemp].id == id
            return userArray[kTemp]
        elseif kTemp==kStart
            return nothing
        elseif userArray[kTemp].id < id
            kStart = kTemp
        else
            kEnd = kTemp
        end
        n += 1
    end
    return nothing
end

function findUserIndex(id::UInt32, userArray::Vector{twitterID})
    kStart = 1
    kEnd = length(userArray)
    if userArray[kStart].id == id
        return kStart
    end
    if userArray[kEnd].id == id
        return kEnd
    end
    n = 1
    while n < 10000
        kTemp = Int64(floor((kStart + kEnd)/2))
        if userArray[kTemp].id == id
            return kTemp
        elseif kTemp==kStart
            return 0
        elseif userArray[kTemp].id < id
            kStart = kTemp
        else
            kEnd = kTemp
        end
        n += 1
    end
    return 0
end

function writeIndexFile(filename, out::Vector{twitterID})
    out32 = Vector{UInt32}(undef, Int64(7*length(out)))
    for k = 1:length(out)
        out32[7*k-6] = out[k].id
        out32[7*k-5] = out[k].followers
        out32[7*k-4:7*k-3] = reinterpret(UInt32, [out[k].followersPosition])
        out32[7*k-2] = out[k].friends
        out32[7*k-1:7*k] = reinterpret(UInt32, [out[k].friendsPosition])
    end
    file = open(filename, "w")
    write(file, UInt32(length(out)))
    write(file, out32)
    close(file)
end

function mergeIndexFiles(friendsIndexFile, followersIndexFile)
    #TO DO: Clean up this function, remove the hardcoded number of users before the while loop
    file1 = open(friendsIndexFile, "r")
    seekend(file1)
    file1Length = Int64(position(file1)/4)
    seekstart(file1)
    friends = Vector{UInt32}(undef, file1Length)
    read!(file1, friends)
    close(file1)

    file2 = open(followersIndexFile, "r")
    seekend(file2)
    file2Length = Int64(position(file2)/4)
    followers = Vector{UInt32}(undef, file2Length)
    seekstart(file2)
    read!(file2, followers)
    close(file2)

    k1 = 1
    k2 = 1
    k = 1
    out = Vector{twitterID}(undef, 41652229) #TO DO: Remove this hardcoded number
    while true
        if k1 > file1Length && k2>file2Length
            break
        end
        if k1 > file1Length || friends[k1] > followers[k2]
            temp = twitterID(followers[k2], followers[k2+1], reinterpret(UInt64, followers[k2+2:k2+3])[1], 0, 0)
            out[k] = temp
            k += 1
            k2 += 4
            continue
        end
        if k2 > file2Length || followers[k2] > friends[k1]
            temp = twitterID(friends[k1], 0, 0, friends[k1+1], reinterpret(UInt64, friends[k1+2:k1+3])[1])
            out[k] = temp
            k += 1
            k1+= 4
            continue
        end
        temp = twitterID(friends[k1], followers[k2+1], reinterpret(UInt64, followers[k2+2:k2+3])[1], friends[k1+1], reinterpret(UInt64, friends[k1+2:k1+3])[1])
        out[k] = temp
        k += 1
        k1+=4
        k2 += 4
    end
    followers = nothing
    friends = nothing
    k -= 1
    println(k)
end

function makeSmallFile(filename, bReverse::Bool)
    temp = Array{UInt64,1}(undef,1)
    file = open(filename, "r")
    temp[1] = read(file, UInt64)
    if bReverse
        yStart,xStart = reinterpret(UInt32, temp)
    else
        xStart,yStart = reinterpret(UInt32, temp)
    end
    seekstart(file)
    outFileName = filename*"_small"
    outFile = open(outFileName, "w")
    write(outFile, xStart)
    write(outFile, yStart)
    while !eof(file)
        temp[1] = read(file, UInt64)
        if bReverse
            y,x = reinterpret(UInt32, temp)
            if x == xStart
                if y != yStart
                    write(outFile, y)
                    yStart = y
                end
            else
                write(outFile, UInt32(0))
                write(outFile, x)
                write(outFile, y)
                xStart = x
                yStart = y
            end
        else
            x,y = reinterpret(UInt32, temp)
            if y == xStart
                if x != yStart
                    write(outFile, x)
                    xStart = x
                end
            else
                write(outFile, UInt32(0))
                write(outFile, x)
                write(outFile, y)
                xStart = x
                yStart = y
            end
        end

    end
    write(outFile, UInt32(0))
    close(file)
    close(outFile)
end

function makeIndexFile(filename)
    #Input should be the name of the LARGE file, not the _small file
    temp64 = Array{UInt64, 1}(undef, 1)
    temp128 = Array{UInt128, 1}(undef, 1)
    inFileName = filename * "_small"
    file = open(filename, "r")
    outFileName = filename * "_index"
    outFile = open(outFileName, "w")
    posStart = UInt64(position(file))
    idStart = read(file, UInt32)
    friends = UInt32(0)
    while !eof(file)
        id = read(file, UInt32)
        if id == UInt32(0)
            temp64 = reinterpret(UInt64, [idStart, friends])
            temp128 = reinterpret(UInt128, [temp64[1], posStart])
            write(outFile, temp128[1])
            if eof(file)
                break
            else
                posStart = UInt64(position(file))
                idStart = read(file, UInt32)
                friends = UInt32(0)
            end
        else
            friends += UInt32(1)
        end
    end
    close(file)
    close(outFile)
end

function bIncludeUserInSubnetwork(user::UInt32, startUser, endUser)
    bOut = false
    if user == 0
        bOut = true
    elseif (user >= startUser) && (user <= endUser)
        bOut = true
    end
    return bOut
end

function stripZeroes(inVector::Vector{UInt32})
    numUsers = 0
    bZeroes = false
    for k = 1:length(inVector)
        if inVector[k] > 0
            bZeroes = false
            numUsers += 1
        elseif bZeroes == false && inVector[k] == 0
            bZeroes = true
            numUsers += 1
        end
    end
    out = Vector{UInt32}(undef, numUsers)
    numUsers = 0
    bZeroes = false
    for k = 1:length(inVector)
        if inVector[k] > 0
            bZeroes = false
            numUsers += 1
            out[numUsers] = inVector[k]
        elseif bZeroes == false && inVector[k] == 0
            bZeroes = true
            numUsers += 1
            out[numUsers] = 0
        end
    end
    return out
end

function buildSubNetwork(inFileName, outFileName, startUser, endUser)
    inFile = open(inFileName, "r")
    outFile = open(outFileName, "w")
    x = read(inFile, UInt32)
    if x >= startUser && x <= endUser
        bInclude = true
    else
        bInclude = false
    end
    seekstart(inFile)
    while !eof(inFile)
        x = read(inFile, UInt32)
        if bInclude == true && (x >= startUser && x <= endUser)
            write(outFile, x)
        elseif x == 0
            if bInclude == true
                write(outFile, x)
            end
            if eof(inFile)
                break
            end
            x = read(inFile, UInt32)
            if (x >= startUser) && (x <= endUser)
                write(outFile, x)
                bInclude = true
            else
                bInclude = false
            end
        end
    end
    close(inFile)
    close(outFile)
end
