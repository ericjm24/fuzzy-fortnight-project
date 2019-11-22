# Political Persuadability in Twitter
A large-scale project attempting to measure how politically persuadable a Twitter user is based on their profile.

Project Question:

	Cambridge Analytica used facebook data from 50 million users in the 2016 election to guess which users were most likely to be persuaded to change their minds, and then use this information to target voters. Can we try and kind-of replicate this effect using the information that is available to us now?

	If we can’t, can we identify what information would be needed to be able to reliably do this?
	

##Directory Structure

/census: code for retrieving information from the us census. Contains self-written wrappers for the us census that allow for quick extraction of any desired data points for the entire country. Also allows for pulling multiple years worth of data and interpolating it. Still needs an implementation of natural neighbor interpolation for spatial interpolation of data.

/twitter: code for working with twitter information. Information is provided by scraping Twitter directly through their API and also from historical datasets, primarily the archive.org Twitter stream archive and a graph of all twitter users and their followers circa 2010 obtained from https://snap.stanford.edu/data/twitter-2010.html

/ML: machine learning algorithms. Will utilize either boosted decision trees or artificial neural networks in tensorflow to provide complex predictions based on demographic information and Twitter friends/followers

/site: Container for all html, css, js, etc for the github site for the project.


Data Sources:

Social Media
Twitter
Demographics
Census
Poll information

Major Questions to be looked at:

Census data is available for different geographic regions during different census cycles. How do we accurately predict the current demographics of a location based on the history of the census data?

How do we build a graph of twitter followers to identify key players and perform data analysis?

Data validation: History of polls and advertising data. Can we look at the history of polls and advertising as a way to validate our data?

How do we combine all the information we have into a guess of how likely a person is to be swayed by advertising?

Future Question: How do we design our messaging to best sway people?

