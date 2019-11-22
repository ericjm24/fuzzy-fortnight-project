#Twitter Folder

This folder contains all the code used to perform a scrape on Twitter and calculations of data pulled from it. Note that all data is reserved on private computers instead of being made publically available. Please download data directly from their sources if you wish to run this code, and leave it in a /data/ folder.

##Notable Files:

twitterJL.jl - Julia code that performs graph-theoretic calculations on users and their friends/followers. Written in Julia for speed, includes self-written implementations of sparse matrix multiplication from disk, external merge sort, eigenvector calculation via power iteration, and more. Note that recent work on this subject has moved to https://github.com/ericjm24/PersonalProjects/tree/master/Networks

politicianScrape.py - Python script that grabs the current followers/friends lists of all sitting members of congress and saves them as json object. Requires a Twitter API key, subject to Twitter's rate limits. Code mostly inteded for personal use (uncommented)

twitterArchiveParse.py - Python module for walking through data from the archive of the Spritzer Twitter stream on archive.org. Useful for extracting specific pieces of information, such as the text, user's id, user's location, or other such fields. Implements multi-threading to help handle the tremendous amount of data. Code is at production-stage.

ipynb files are generally for testing purposes. Note that some IPython Notebooks are actually running Julia, not python.
