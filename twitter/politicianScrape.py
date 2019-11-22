import tweepy
from config import tw_key, tw_secret
import pandas as pd
import json
auth = tweepy.AppAuthHandler(tw_key, tw_secret)
api = tweepy.API(auth, wait_on_rate_limit=True)
politician_ids = []
with open("data/politicians_list", "r") as f:
    for line in f:
        politician_ids.append(line.strip())

has_data = []
try:
    with open("data/pol_json_data","r") as f:
        for line in f:
            pol_obj = json.loads(line)
            has_data.append(pol_obj["id_str"])
except:
    has_data = []
json_data_file = "data/pol_json_data"
print("Found data on " + str(len(has_data)) + " politicians so far.\n")

def politician_scrape(pol_id):
    from datetime import datetime
    try:
        pol = api.get_user(user_id=pol_id)
        print("Getting data on " + pol.name + ". Followers: " + str(pol.followers_count))
    except:
        print("Getting data on id " + pol_id + " failed")
        return None
    followers = []
    friends=[]
    for page_fol in tweepy.Cursor(api.followers_ids,id=pol.id_str, count=5000).pages():
        followers += page_fol
    for page_fr in tweepy.Cursor(api.friends_ids,id=pol.id_str, count = 5000).pages():
        friends += page_fr
    out = {
        'id':pol.id,
        'id_str':pol.id_str,
        'name':pol.name,
        'screen_name':pol.screen_name,
        'location':pol.location,
        'description':pol.description,
        'friends_count':pol.friends_count,
        'followers_count':pol.followers_count,
        'created_at':pol.created_at.strftime("%Y/%m/%d"),
        'friends_ids':friends,
        'followers_ids':followers,
    }
    print("Found " + str(out["followers_count"]) + " followers\n")
    return out

for id in politician_ids:
    if id in has_data:
        continue
    next_pol = politician_scrape(id)
    if next_pol:
        has_data.append(next_pol["id_str"])
        print(next_pol["id_str"]+'\n')
        with open(json_data_file, "a") as f:
            json.dump(next_pol, f)
            f.write('\n')
