indexFile = "data/twitter_index"
friendsFile = "data/friends_small"
followersFile = "data/followers_small"
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
    out = Vector{typeof(V[1])}(undef, length(V))
    for t = 1:length(out)
        out[t]=0
    end
    ind = M[1]
    k = 2
    temp = Float64(0)
    L = length(M)
    while k <= L
        a = M[k]
        if a != 0
            temp += V[a]
            k += 1
        else
            out[ind] = temp
            k += 1
            if k > L
                break
            end
            temp = 0
            ind = M[k]
            k += 1
        end
    end
    return out
end

function friendsMultiplyMV(users::Vector{twitterID}, V::Vector{Float64})
    file = open(friendsFile, "r")
    out = Vector{typeof(V[1])}(undef, length(V))
    buffer = Vector{UInt32}(undef, maxBuff)
    for t = 1:length(V)
        out[t]=0
    end
    k = 1
    j = 1
    L = length(users)
    while true
        numUsers = 0
        numFriends = 0
        while true
            theseFriends = users[k].friends + 2
            if theseFriends > maxBuff
                error("Need a larger buffer to do this multiplication fast")
            elseif k > L
                buffer = Vector{UInt32}(undef, numFriends)
                break
            elseif (numFriends + theseFriends) > maxBuff
                break
            else
                k += 1
                numFriends += theseFriends
                numUsers += 1
            end
        end
        curPos = position(file)
        read!(file, buffer)
        seek(file, curPos + (numFriends*4))
        s = 2
        temp = 0
        while s <= numFriends
            a = buffer[s]
            if a != 0
                temp += V[s]
                s += 1
            else
                out[j] = temp
                s += 2
                j += 1
                temp = 0
                if s > numFriends
                    break
                end
            end
        end
        if k > L
            break
        end
    end
    close(file)
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

function randomStep(user::twitterID, userArray::Vector{twitterID})
    x = rand(1:3)
    if x == 1
        return user
    elseif x == 2
        return findUser(rand(readFriends(user)), userArray)
    else
        return findUser(rand(readFollowers(user)), userArray)
    end
end

function randomWalk(startUser::twitterID, numSteps::Int64,userArray::Vector{twitterID})
    out =  Vector{twitterID}(undef, numSteps+1)
    out[1] = startUser
    for k = 1:numSteps
        out[k+1] = randomStep(out[k], userArray)
    end
    return out
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
