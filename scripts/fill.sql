\copy users(username,password) from '/root/data/users.csv' delimiter ',' csv header;
\copy posts(time,user_id,content) from '/root/data/posts.csv' delimiter ',' csv header;
\copy comments(time,user_id,post_id,content) from '/root/data/comments.csv' delimiter ',' csv header;
\copy follows(from_user_id,to_user_id) from '/root/data/follows.csv' delimiter ',' csv header;
\copy likes(user_id,post_id) from '/root/data/likes.csv' delimiter ',' csv header;
\copy topics(name) from '/root/data/topics.csv' delimiter ',' csv header;
\copy posts_topics(post_id,topic_id) from '/root/data/posts_topics.csv' delimiter ',' csv header;
