require 'json'
require 'pg'

require 'ballchasing'
require 'core'
require 'datacache'
require 'duration'
require 'jubibot'
require 'rlranks'
require 'rstruct'

class RLDB
  include JubiSingleton

  ##### PUBLIC CONSTANTS #####
  PLAYLIST_COLUMNS = %i[
    standard
    doubles
    duel
    rumble
    dropshot
    hoops
    snow_day
    tournament
  ].freeze
  public_constant :PLAYLIST_COLUMNS
  #############################

  ##### PRIVATE STRUCTS #####
  User = KVStruct.new(:id, :server, :account, :platform) {
    def initialize(id:, server:, account:, platform:)
      super(id: id.to_i,
            server: server.to_i,
            account: account,
            platform: platform.to_sym)
    end
  }
  private_constant :User
  ###########################

  ##### PRIVATE CACHES #####
  ServerCache = DataCache.new(10.days)
  private_constant :ServerCache
  ##########################

  def initialize
    if !ENV.key?('DATABASE_URL') && !ENV.key?('DISCORD_DB')
      raise ArgumentError, 'ENV DATABASE_URL or DISCORD_DB must be set'
    end

    @db = if ENV.key?('DATABASE_URL')
            PG.connect(ENV['DATABASE_URL'])
          else
            PG.connect(dbname: ENV['DISCORD_DB'])
          end
  end

  #######################################
  # USERS TABLE
  #######################################
  def unregister(user, server)
    sql(<<~SQL)
      delete from users where id = #{user} and server = #{server}
    SQL
  end

  def register(user, server, account, platform)
    sql(<<~SQL, catching: [PG::InvalidTextRepresentation, PG::UniqueViolation])
      insert into users (id, server, account, platform)
        values (#{user}, #{server}, '#{account}', '#{platform}')
    SQL
  rescue PG::InvalidTextRepresentation
    raise JubiBotError, "#{platform} is not a valid platform"
  rescue PG::UniqueViolation
    raise UserIDError.new('**{name}** already exists in registry.  ' \
                          'Try `unregister` first.', user)
  else
    return User.new(
        id: user,
        server: server,
        account: account,
        platform: platform)
  end

  def all_users(server)
    users = sql(<<~SQL).entries
      select * from users where server = #{server}
    SQL
    return users.map { |user| User.new(**user) }
  end

  def users(users, server)
    return {} if users.empty?

    user_entries = sql(<<~SQL).entries
      select * from users
        where id in (#{users.join(',')}) and server = #{server}
    SQL
    user_hash = user_entries.to_h { |user| [user[:id].to_i, User.new(**user)] }

    if user_hash.size < users.length
      users.each { |user|
        unless user_hash.key?(user.to_i)
          raise UserIDError.new('**{name}** not found in registry.', user)
        end
      }
    end

    return user_hash
  end

  def user(user, server)
    return users([user], server).fetch(user.to_i)
  end

  #######################################
  # SERVERS TABLE
  #######################################
  def server_playlists(server)
    server_info = _server_info(server)
    return [] unless server_info

    return playlists_from_int(server_info.fetch(:playlists).to_i)
  end

  def store_server_playlists(server, playlists)
    playlists_int = int_from_playlists(playlists)

    sql(<<~SQL)
      insert into servers (id, playlists)
        values (#{server}, #{playlists_int})
      on conflict (id) do update set
        playlists = #{playlists_int}
    SQL

    ServerCache.invalidate(server)
  end

  def server_platform_roles(server)
    server_info = _server_info(server)
    return true unless server_info

    return server_info.fetch(:platform_roles) == 't'
  end

  def store_server_platform_roles(server, enabled)
    sql(<<~SQL)
      insert into servers (id, platform_roles)
        values (#{server}, '#{enabled}')
      on conflict (id) do update set
        platform_roles = '#{enabled}'
    SQL

    ServerCache.invalidate(server)
  end

  def server_region_roles(server)
    server_info = _server_info(server)
    return true unless server_info

    return server_info.fetch(:region_roles) == 't'
  end

  def store_server_region_roles(server, enabled)
    sql(<<~SQL)
      insert into servers (id, region_roles)
        values (#{server}, '#{enabled}')
      on conflict (id) do update set
        region_roles = '#{enabled}'
    SQL

    ServerCache.invalidate(server)
  end

  def server_prefix(server)
    return '!' unless server

    server_info = _server_info(server)
    return '!' unless server_info

    return server_info.fetch(:prefix)
  end

  def store_server_prefix(server, prefix)
    sql(<<~SQL)
      insert into servers (id, prefix)
        values (#{server}, '#{prefix}')
      on conflict (id) do update set
        prefix = '#{prefix}'
    SQL

    ServerCache.invalidate(server)
  end

  def _server_info(server)
    return ServerCache.fetch(server) {
      sql(<<~SQL).entries.first
        select * from servers where id = #{server}
      SQL
    }
  end

  #######################################
  # RANKS TABLE
  #######################################
  def ranks(user, account, platform)
    rank_results = sql(<<~SQL).entries.first
      select * from ranks where id = #{user} and
                           account = '#{account}' and
                          platform = '#{platform}'
    SQL
    return unless rank_results

    id = rank_results.delete(:id)
    account = rank_results.delete(:account)
    platform = rank_results.delete(:platform)
    return RLRanks.new(id, account, platform, **rank_results)
  end

  def store_ranks(ranks)
    return if ranks.unranked?

    rank_columns = {
      id: ranks.id,
      account: ranks.account,
      platform: ranks.platform
    }
    ranks.each { |column, rank|
      rank_columns[column] = rank.rank
    }

    sql(<<~SQL)
      insert into ranks (#{rank_columns.keys.join(',')})
        values ('#{rank_columns.values.join("','")}')
      on conflict (id, account, platform) do update set
        #{ranks.map { |column, rank| "#{column} = #{rank.to_i}" }.join(',')}
    SQL
  end

  #####################################
  # BC TABLES
  #####################################
  def replays(ids = [])
    return {} if ids.empty?

    return sql_replays(<<~SQL)
      select * from bc_replays where id in ('#{ids.join("', '")}')
    SQL
  end

  def replays_with_players(account, players = [])
    return {} if players.empty?

    return sql_replays(<<~SQL)
      select * from bc_replays where account = '#{account}' and id in (
        #{players.map { |player|
          "select replay_id from bc_players where
            account = '#{player.account}' and platform = '#{player.platform}'"
        }.join(' intersect ')}
      )
    SQL
  end

  def store_replays(account, replays)
    return if replays.empty?

    platform_map = {
      steam: 'steam',
      xbox: 'xbox',
      ps: 'ps',
      epic: 'epic'
    }.freeze
    valid_player = lambda { |player|
      return player.id.id && platform_map.key?(player.id.platform.to_sym)
    }
    platform = lambda { |player|
      return platform_map.fetch(player.id.platform.to_sym)
    }

    sql(<<~SQL)
      begin;
      insert into bc_replays (id, account, date, info) values
        #{replays.map { |replay|
          "('#{replay.id}',
            '#{account}',
            '#{replay.date}',
            '#{replay.raw_data.delete("'")}'
          )"
        }.join(', ')};
      insert into bc_players (account, platform, replay_id) values
        #{replays.map { |replay|
          players = (replay.orange.players + replay.blue.players)
          players.uniq!
          players.filter_map { |player|
            if valid_player.run(player)
              "('#{player.id.id}', '#{platform.run(player)}', '#{replay.id}')"
            end
          }.join(', ')
        }.join(', ')};
      commit;
    SQL
  end

  private

  def int_from_playlists(playlist_columns)
    playlist_int = 0
    playlist_columns.each { |playlist_column|
      playlist_index = PLAYLIST_COLUMNS.index(playlist_column.to_sym)
      if playlist_index.nil?
        raise JubiBotError,
              "`#{playlist_column}` is not a defined playlist column. " \
              'Valid names are: ' \
              "#{PLAYLIST_COLUMNS.sentence { |pl| "`#{pl}`" }}"
      end

      playlist_int += 2**playlist_index
    }

    return playlist_int
  end

  def playlists_from_int(playlist_int)
    playlist_columns = []
    (PLAYLIST_COLUMNS.length - 1).downto(0) { |playlist_index|
      if playlist_int >= 2**playlist_index
        playlist_columns.push(PLAYLIST_COLUMNS[playlist_index])
        playlist_int -= 2**playlist_index
      end
    }

    if playlist_int.positive?
      raise StandardError, "playlist_int somehow has remainder: #{playlist_int}"
    end

    return playlist_columns
  end

  def sql_replays(command)
    return sql(command).entries.to_h { |replay|
      replay_info = JSON.parse(replay[:info])
      replay_info[:raw_data] = replay[:info]
      [replay[:id], Ballchasing::Replay.new(replay_info.deep_symbolize_keys!)]
    }
  end

  def sql(command, catching: [])
    return exec(command)
  rescue PG::Error => e
    raise e if catching.any? { |error_class| e.is_a?(error_class) }

    Discordrb::LOGGER.warn(<<~WARN.chomp)
      SQL command: #{command}
      Exception: <#{e.class}>: #{e.message}
    WARN

    @db.reset
    return exec(command)
  end

  def exec(command)
    return @db.exec(command.chomp).map(&:symbolize_keys)
  end
end
