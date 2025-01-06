-- - jeden SELECT vypočte průměrný počet záznamů na jednu tabulku v DB
select avg(n_live_tup) as row_avg from pg_stat_user_tables;

-- VIEW (1x) s podstatnými informacemi z několika tabulek najednou
-- - jeden SELECT bude obsahovat vnořený SELECT
drop view if exists pr_stats;
create view pr_stats as select
(select count(*) from users) as users,
(select count(*) from posts) as posts,
(select count(*) from likes) +
(select count(*) from follows) as interactions;

-- INDEX (1x), indexový soubor nad nějakým sloupcem tabulky
-- - alespoň jeden netriviální indexový soubor (unikátní, fulltextový, …)
create index posts_idx on posts using gin (to_tsvector('english', content));
select u.username, p.content
from posts p
inner join users u on p.user_id = u.id
where to_tsvector('english', content) @@ to_tsquery('english', 'fun');

-- FUNCTION (1x), která bude realizovat výpočet nějaké hodnoty z dat v DB
-- - jeden SELECT bude řešit rekurzi nebo hierarchii (SELF JOIN)
-- - jeden SELECT bude obsahovat nějakou analytickou funkci (SUM, COUNT, AVG,…) spolu s agregační klauzulí GROUP BY
create or replace function foaf(person varchar(20))
returns table(username varchar(20), fic bigint)
language plpgsql
returns null on null input
as $$
begin
    return query
    select u2.username as username, count(*) as fic
    from users u1
    inner join follows f1 on u1.id = f1.from_user_id
    inner join follows f2 on f1.to_user_id = f2.from_user_id
    inner join users u2 on f2.to_user_id = u2.id
    where u1.username = person and u1.username <> u2.username
    group by u2.username
    order by fic desc;
end; $$;
select * from foaf('AnnaJoy92'); -- je to opravdu rekurze?

-- PROCEDURE (1x), která bude používat 1x CURSOR a také 1x ošetření chyb (HANDLER /
-- TRY…CATCH / RAISE / EXCEPTION - dle zvoleného DBMS)
-- - např. vytvoří a naplní novou tabulku informacemi o náhodných slevách na vybrané
-- výrobky, nebo zákazníkům vygeneruje slevové bonusy podle určitých podmínek, apod.
-- TRANSACTION (1x) použít v některé z předchozích procedur / funkcí
-- - tj. uzavřít skupinu příkazů do transakce a ošetřit případ, kdy není možné všechny uvedené
-- příkazy vykonat najednou (ROLLBACK)
-- - např. převod peněz z jednoho účtu na druhý uzavřít do transakce + ošetřit situaci kdy
-- odesilatel nemá na účtu dostatek financí na provedení převodu
-- - START/BEGIN TRANSACTION, COMMIT, ROLLBACK (případně i SAVEPOINT)
drop table if exists user_stats;
create table user_stats (
    user_id integer primary key,
    follows integer not null,
    following integer not null,
    foreign key (user_id) references users(id) on delete cascade
);
create or replace procedure gen_user_stats()
language plpgsql
as $$
declare
	user_cursor cursor for select * from users;
	user_record record;
	follows integer;
	following integer;
begin
	begin
		delete from user_stats; -- vycisti tabulku
		open user_cursor;
		loop
			fetch next from user_cursor into user_record;
			exit when not found;
			select count(*) into follows
			from follows
			where to_user_id = user_record.id;
			select count(*) into following
			from follows
			where from_user_id = user_record.id;
			insert into user_stats(user_id,follows,following)
			values(user_record.id,follows,following);
		end loop;
		close user_cursor;
	exception
	when others then
		rollback;
		raise;
	end;
end; $$;
call gen_user_stats();
select * from user_stats;

-- TRIGGER (1x), který ošetří práci uživatele s daty DB
drop table if exists deleted_users;
create table deleted_users (
    id serial primary key,
    username varchar(20) not null unique,
    time timestamptz default now()
);
create or replace function log_user_deletion()
returns trigger as $$
begin
    insert into deleted_users(username)
    values (old.username);
    return old;
end;
$$ language plpgsql;
create trigger user_delete_trigger
after delete on users
for each row
execute function log_user_deletion();

-- USER - mít předem připravené příkazy na ukázku práce s účty uživatelů
-- - umět vytvořit/odstranit účet uživatele CREATE/DROP USER
-- - umět se přihlásit jako právě vytvořený uživatel a ověřit dostupnost databází z pohledu
-- nového uživatele
-- - umět vytvořit/odstranit roli CREATE/DROP ROLE (některé DBMS nemají role)
-- - umět přidělit/odebrat uživateli nebo roli nějaká práva GRANT / REVOKE
create user anon;
grant select on table pr_stats to anon;

-- LOCK - mít předem připravené příkazy na ukázku zamykání tabulek
-- - umět zamknout/odemknout tabulku (případně celou databázi, nebo jen řádek - pokud to
-- zvolený DBMS umožňuje)
-- - LOCK TABLE Vyrobky READ / UNLOCK TABLE Vyrobky / UNLOCK TABLES
begin;
	lock table posts in access exclusive mode;
	delete from comments;
commit;

-- ORM – umět používat objektově-relační mapování
-- - některý z výše uvedených úkolů realizovat pomocí vhodného ORM, např. SQLAlchemy,
-- Django, apod.
viz orm.py
