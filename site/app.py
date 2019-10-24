import json
from random import randint

cacheFile = "data/cacheFile"


try:
    with open(cacheFile, "r") as file:
        cache = json.load(file)
        congress = list(cache.keys())
except:
    raise Exception('No cache found. Make sure you have the data in the data folder and have run the associated buildCache.py script')


from flask import Flask, jsonify, render_template, redirect

app = Flask(__name__)

@app.route("/")
def home():
    return render_template("index.html")


def getUserObject(userID):
    if userID in congress:
        userObj = cache[userID]
    else:
        userObj = {}
    return userObj

@app.route("/user/<userID>")
def giveUser(userID):
    userID = congress[randint(0,len(congress)-1)]
    out = getUserObject(userID)
    return jsonify(out)

if __name__ == '__main__':
    app.run(debug=True)
