library(tidyverse)
#library(neo4r) # not officlally supported.  This version only works with 3.5 and there is still an outstanding pull request for 4.0 from 2020.

tweets <- readr::read_csv('https://raw.githubusercontent.com/rfordatascience/tidytuesday/master/data/2021/2021-06-15/tweets.csv')

# Generate a tweet_id & drop bad row
tweets <- tweets %>% mutate(tweet_id = row_number(), interaction_count = like_count+retweet_count+quote_count) %>% drop_na(username) 
tweets

# relationship helper function
make_pairs <- function (lst) {
  df = NULL
  for (i in seq_along(lst))
  {
    for(label in lst[[i]]) {
      tweet_id = tweets$tweet_id[i]
      df = rbind(df, data.frame(tweet_id, label))
      df <- df %>% mutate(label = str_to_lower(str_remove(label,"[@#]")))
    }
  }
  df
}

# Mention Edges (any @'s)
# from Twitter Help
# A username can only contain alphanumeric characters (letters A-Z, numbers 0-9) with the exception of underscores, as noted above.
mention_edges <- tweets$content %>% str_match_all("@[A-z0-9_]+") %>% make_pairs()
mention_edges
write_csv(mention_edges, "mention_edges.csv")

# User Nodes
users <-tweets %>% select(username, followers, location, lat, long, url) %>% mutate(username=str_to_lower(username)) %>% group_by(username) %>% summarise(followers=max(followers), location=max(location), lat=max(lat), long=max(long), url=max(url))
mention_users <- mentions %>% select(child) %>% rename(username=child) %>% distinct
all_user_nodes <- full_join(users, mention_users, by="username")
all_user_nodes
write_csv(all_user_nodes, "user_nodes.csv")

# Hastage Edges (any #'s)
# Hashtags can only contain letters, numbers, and underscores (_), no special characters
hashtag_edges <- tweets$content %>% str_match_all("#[A-z0-9_]+") %>% make_pairs()
write_csv(hashtag_edges, "hastag_edges.csv")

# Hastag Nodes
hastage_nodes <- hashtag_edges %>% select(label) %>% distinct() %>% mutate(id=label)
hastage_nodes
write_csv(hastage_nodes, "hastag_nodes.csv")

# Tweet Nodes
tweet_nodes <- tweets %>% select(tweet_id, content, datetime, like_count, retweet_count, quote_count, interaction_count)
write_csv(tweet_nodes, "tweet_nodes.csv")

# Tweet Edges
tweet_edges <- tweets %>% select(username, tweet_id, interaction_count)
tweet_edges
write_csv(tweet_edges, "tweet_edges.csv")


##### Avast Ye, NEO4J Cypher down below
## NEO4J Commands

## DELETE ALL NODES and RELATIONSHIPS
MATCH (n)
DETACH DELETE n

load csv from 'file:///tweet_nodes.csv' as row return count(row)
load csv from 'file:///tweet_nodes.csv' as row return row limit 3
load csv with headers from 'file:///tweet_nodes.csv' as row return row limit 3

# See what data we will load
load csv with headers from 'file:///tweet_nodes.csv' as row with datetime(row.datetime) AS datetime,
row.content AS content,
row.tweet_id as tweet_id, 
toInteger(row.interaction_count) AS interaction_count
return tweet_id, datetime, interaction_count, content limit 3

# Create unique constraint
CREATE CONSTRAINT UniqueTweet ON (t:Tweet) ASSERT t.tweet_id IS UNIQUE;

# Load the 444 tweets
load csv with headers from 'file:///tweet_nodes.csv' as row with datetime(row.datetime) AS datetime,
row.content AS content,
row.tweet_id as tweet_id, 
toInteger(row.interaction_count) AS interaction_count
MERGE (t:Tweet {tweet_id:tweet_id})
SET t.tweet_id=tweet_id, t.interaction_count=interaction_count, t.datetime = datetime, t.content= content
return count(t)

# Visualize a sample of the nodes
MATCH (n:Tweet) RETURN n LIMIT 25

# Load the users
load csv from 'file:///user_nodes.csv' as row return row limit 3

load csv with headers from 'file:///user_nodes.csv' as row with
row.username AS username,
toInteger(row.followers) AS followers, 
toFloat(row.lat) AS lat, 
toFloat(row.long) AS long, 
row.url AS url
return username, followers, lat, long, url limit 5;

# Create unique constraint
CREATE CONSTRAINT UniqueUser ON (u:username) ASSERT u.username IS UNIQUE;

load csv with headers from 'file:///user_nodes.csv' as row with
row.username AS username,
toInteger(row.followers) AS followers, 
toFloat(row.lat) AS lat, 
toFloat(row.long) AS long, 
row.url AS url
MERGE (u:User {username:username})
SET u.username=username, u.followers=followers, u.lat=lat, u.long=long, u.url=url
return count(u)


# load the edges between users and tweets
load csv with headers from 'file:///tweet_edges.csv' as row return row limit 3

LOAD CSV WITH HEADERS FROM 'file:///tweet_edges.csv' AS row
WITH
row.tweet_id as tweet_id,
row.username as username,
toInteger(row.interaction_count) as interaction_count
MATCH (t:Tweet {tweet_id: tweet_id})
MATCH (u:User {username: username})
MERGE (u)-[rel:TWEETS {interaction_count: interaction_count}]->(t)
RETURN count(rel);

# load the edges between users and users (mentions)
load csv with headers from 'file:///mention_edges.csv' as row return row limit 3

LOAD CSV WITH HEADERS FROM 'file:///mention_edges.csv' AS row
WITH
row.tweet_id as tweet_id,
row.label as username
MATCH (t:Tweet {tweet_id: tweet_id})
MATCH (u:User {username: username})
MERGE (t)-[rel:MENTIONS]->(u)


# Inspect the graph of only those people mentioned in a tweet
MATCH p=()-[:MENTIONS]->() RETURN p

# Find all the tweets for people who ar mentioned more than once.
MATCH ()-[r:MENTIONS]->(n)
WITH n, count(r) as rel_cnt
WHERE rel_cnt > 1
MATCH p=()-[]-(n) return p

# Load the hastags

# load the edges



