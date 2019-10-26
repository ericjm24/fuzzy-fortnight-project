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

def getUserObject(userID):
    if userID in congress:
        userObj = cache[userID]
    else:
        userObj = {}
    return userObj

app = Flask(__name__)

@app.route("/")
def home():
    data = []
    for c in congress:
        temp = getUserObject(c)
        data.append({"id":temp["userID"], 'color':temp["color"]})
    return render_template("index.html", congressmembers = data)



@app.route("/user/<userID>")
def giveUser(userID):
    out = getUserObject(userID)
    return jsonify(out)

if __name__ == '__main__':
    app.run(debug=True)
