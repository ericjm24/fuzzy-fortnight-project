from config import tw_key, tw_secret, aws_key, aws_secret
import tweepy
import numpy as np
import boto3
from random import randint
import time

auth = auth = tweepy.AppAuthHandler(tw_key, tw_secret)
api = tweepy.API(auth)
has_data_file = "data/has_data"
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
    file = open(has_data_file, "r")
    has_data = list(np.fromfile(file, np.uint32, count=-1))
    file.close()
except:
    has_data = []


client = boto3.client('dynamodb', region_name='us-west-2')

def limit_handled(cursor):
    while True:
        try:
            yield cursor.next()
        except tweepy.RateLimitError:
            print("Hit rate limit. Waiting...\n")
            time.sleep(15 * 60)

while True:
    x = randint(1,numUsers)
    user = users_data[x-1]
    if user["id"] in has_data:
        continue

    print("Trying user " + str(user["id"]) + "\n")
    try:
        user = api.get_user(user_id=user["id"])
    except:
        continue

    try:
        friends = []
        if user.friends_count <= 50000:
            for page in tweepy.Cursor(api.friends_ids, user_id = user.id).pages():
                friends += page

        followers = []
        if user.followers_count <= 50000:
            for page in tweepy.Cursor(api.followers_ids, user_id = user.id).pages():
                followers += page

        out = {
            "userID":{"N":user.id_str},
            "friends_count":{"N":str(user.friends_count)},
            "followers_count":{"N":str(user.followers_count)},
        }
        if user.location:
            out["location"] = {"S":user.location}
        if user.name:
            out["name"] = {"S":user.name}
        if user.screen_name:
            out["screenname"] = {"S":user.screen_name}
        if user.description:
            out["description"] = {"S":user.description}
        if len(friends) >= 1:
            out["friends"] = {"NS":[str(y) for y in friends]}

        if len(followers) >= 1:
            out["followers"] = {"NS":[str(y) for y in followers]}

        print(out)
        response = client.put_item(TableName="currentTwitter", Item=out)
        print(response)
        has_data.append(user.id)
        with open(has_data_file, "w") as file:
            np_has_data = np.array(has_data, dtype=np.uint32)
            np_has_data.tofile(file)
    except:
        time.sleep(60)
