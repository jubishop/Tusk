require 'pg'

raise ArgumentError, 'Pass DB name' if ARGV.empty?

db = PG.connect(dbname: ARGV.first)

# Create platform enum. (switch not supported atm)
db.exec(<<~SQL)
  create type platform as ENUM ('steam', 'xbox', 'ps', 'epic', 'switch')
SQL

# Create users table.
db.exec(<<~SQL)
  create table users (
    id bigint not null,
    server bigint not null,
    account varchar(32) not null,
    platform platform not null default 'steam',
    primary key (id, server)
  )
SQL

# Create rank table.
db.exec(<<~SQL)
  create table ranks (
    id bigint not null,
    account varchar(32) not null,
    platform platform not null default 'steam',
    standard smallint,
    doubles smallint,
    duel smallint,
    solo_standard smallint,
    rumble smallint,
    dropshot smallint,
    hoops smallint,
    snow_day smallint,
    primary key (id, account, platform)
  )
SQL

# Create servers table.
db.exec(<<~SQL)
  create table servers (
    id bigint not null primary key,
    prefix varchar(8) default '!',
    playlists int
  )
SQL

# Create bc_replays table.
db.exec(<<~SQL)
  create table bc_replays (
    id varchar(64) not null primary key,
    account varchar(32) not null,
    date timestamp not null,
    info jsonb not null
  )
SQL

# Create bc_players table.
db.exec(<<~SQL)
  create table bc_players (
    account varchar(32) not null,
    platform platform not null default 'steam',
    replay_id varchar(64) not null,
    primary key (account, platform, replay_id),
    foreign key (replay_id) references bc_replays (id)
  )
SQL
