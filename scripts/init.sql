drop view if exists pr_stats;
drop table if exists user_stats;
drop table if exists deleted_users;
drop table if exists posts_topics;
drop table if exists topics;
drop table if exists likes;
drop table if exists follows;
drop table if exists comments;
drop table if exists posts;
drop table if exists users;

--* uprav primary, constraint atd. mozna na zvlastni radky kvuli prehlednosti
--* zkontroluj, jestli se nekde nehodi databazi utahnout

create table users (
    id serial primary key,
    username varchar(20) not null unique,
    password char(64) not null -- sha256 hashovana hesla
);

create table posts (
    id serial primary key,
    time timestamptz default now(),
    user_id integer not null,
    content text not null,
    foreign key (user_id) references users(id) on delete cascade
);

create table comments (
    id serial primary key,
    time timestamptz default now(),
    user_id integer not null,
    post_id integer not null,
    content text not null,
    foreign key (user_id) references users(id) on delete cascade,
    foreign key (post_id) references posts(id) on delete cascade
);

create table follows (
    from_user_id integer not null,
    to_user_id integer not null,
    primary key (from_user_id, to_user_id),
    foreign key (from_user_id) references users(id) on delete cascade,
    foreign key (to_user_id) references users(id) on delete cascade
);

create table likes (
    user_id integer not null,
    post_id integer not null,
    primary key (user_id, post_id),
    foreign key (user_id) references users(id) on delete cascade,
    foreign key (post_id) references posts(id) on delete cascade
);

create table topics (
    id serial primary key,
    name varchar(20) not null unique
);

create table posts_topics (
    post_id integer not null,
    topic_id integer not null,
    primary key (post_id, topic_id),
    foreign key (post_id) references posts(id) on delete cascade,
    foreign key (topic_id) references topics(id) on delete cascade
);
