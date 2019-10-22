from config import tw_key, tw_secret, aws_key, aws_secret
import tweepy
import numpy as np
import boto3
from random import randint

twitterID = np.dtype([
    ("id", np.uint32),
    ("followers", np.uint32),
    ("friends", np.uint32)
])

filename = "data/users_data"

file = open(filename, "r")

numUsers = np.fromfile(file, np.uint32)[0]

users_data = np.fromfile(file, twitterID, count=numUsers)

client = boto3.client('dynamodb')
