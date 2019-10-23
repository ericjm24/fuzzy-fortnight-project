from config import tw_key, tw_secret, aws_key, aws_secret
import tweepy
import numpy as np
import boto3
from random import randint
import time

twitterID = np.dtype([
    ("id", np.uint32),
    ("followers", np.uint32),
    ("friends", np.uint32)
])

filename = "data/users_data"
file = open(filename, "r")
users_data = np.fromfile(file, twitterID, count=-1)
file.close()
numUsers = len(users_data)

try:
    filename = "data/has_data"
    file = open(filename, "r")
    has_data = list(np.fromfile(file, np.uint32, count=-1))
    file.close()
except:
    has_data = []


client = boto3.client('dynamodb')

def limit_handled(cursor):
    while True:
        try:
            yield cursor.next()
        except tweepy.RateLimitError:
            time.sleep(15 * 60)

while True:
    x = randint(1,numUsers)
    user = users_data[x-1]
    if user["id"] in has_data:
        continue

    try:
        user = api.get_user(user_id=user["id"])
    except:
        time.sleep(60)
        continue

    friends = []
    if user.friends_count <= 50000:
        for page in limit_handles(tweepy.Cursor(api.friends_ids, user_id = user.id).pages()):
            friends += page

    followers = []
    if user.followers_count <= 50000:
        for page in limit_handled(tweepy.Cursor(api.followers_ids, user_id = user.id).pages()):
            followers += page

    out = {
        "userID":{"N":user.id_str},
        "location":{"S":user.location},
        "name":{"S":user.name},
        "screenname":{"S":user.screen_name},
        "description":{"S":user.description},
        "friends_count":{"N":str(user.friends_count)},
        "followers_count":{"N":str(user.followers_count)},
    }
    if len(friends) >= 1:
        out["friends"] = {"NS":[str(y) for y in friends]}

    if len(followers) >= 1:
        out["followers"] = {"NS":[str(y) for y in followers]}
    client.put_item(TableName="currentTwitter", Item=out)
    print(user.id_str + '\n')
    has_data.append(user.id)
