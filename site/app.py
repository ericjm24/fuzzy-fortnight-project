import importlib.util
spec = importlib.util.spec_from_file_location("twitterGraph", "../twitter/twitterGraph.py")
tg = importlib.util.module_from_spec(spec)
spec.loader.exec_module(tg)
graph = tg.twitterGraph()

from flask import Flask, jsonify

app = Flask(__name__)

@app.route("/")
def home():
    return None

@app.route("/user/<userID>")
def giveUser(userID):
    try:
        id = int(userID)
    except:
        None
    out = {
        'id':userID,
        'friends':list(graph.getFriends(id)),
        'followers':list(graph.getFollowers(id))
    }
    return jsonify(out)

if __name__ == '__main__':
    app.run(debug=True)
