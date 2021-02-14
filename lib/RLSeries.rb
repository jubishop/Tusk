require 'concurrent'

require 'ballchasing'
require 'core'
require 'jubibot'

require_relative 'RLDB'

class RLSeries
  include JubiSingleton

  ##### PRIVATE CONSTANTS #####
  NUM_THREADS = 4
  private_constant :NUM_THREADS

  SERIES_MAP = {
    Core: {
      wins: 'Wins',
      losses: 'Losses',
      score: 'Score',
      goals: 'Goals',
      shots: 'Shots',
      saves: 'Saves',
      assists: 'Assists',
      shooting_percentage: 'Shot %',
      demo__inflicted: 'Demos Inflicted',
      demo__taken: 'Demos Received'
    },
    Boost: {
      avg_amount: 'Average Boost',
      amount_collected: 'Collected',
      amount_stolen: 'Stolen',
      count_collected_big: 'Big Pads',
      count_stolen_big: 'Stolen Big',
      count_collected_small: 'Small Pads',
      count_stolen_small: 'Stolen Small',
      amount_overfill: 'Overfill',
      amount_overfill_stolen: 'Stolen Overfill',
      amount_used_while_supersonic: 'Wasted at Super',
      time_zero_boost: 'At Zero',
      time_full_boost: 'At Full',
      time_boost_0_25: 'With < 25',
      time_boost_75_100: 'With > 75'
    },
    Movement: {
      avg_speed: 'Average Speed',
      time_supersonic_speed: 'At Supersonic',
      time_boost_speed: 'At Boost Speed',
      time_slow_speed: 'At Slow Speed',
      time_ground: 'On Ground',
      time_low_air: 'Low in Air',
      time_high_air: 'High In Air',
      time_powerslide: 'Powersliding',
      count_powerslide: 'Powerslides'
    },
    Positioning: {
      avg_distance_to_ball: 'Avg Distance to Ball',
      time_defensive_third: 'In Defensive Third',
      time_neutral_third: 'In Neutral Third',
      time_offensive_third: 'In Offensive Third',
      time_defensive_half: 'In Defending Half',
      time_offensive_half: 'In Offensive Half',
      time_behind_ball: 'Behind Ball',
      time_infront_ball: 'In Front of Ball'
    }
  }.freeze
  private_constant :SERIES_MAP

  TEAM_GROUPS = [%i[orange blue], %i[blue orange]].freeze
  private_constant :TEAM_GROUPS
  #############################

  ##### PRIVATE CLASSES #####
  class PlayerStats
    # User from local database matches Player from ballchasing.com.
    def self.player_match?(db_user, player)
      return db_user.account == player.id.id &&
             db_user.platform[0, 2] == player.id.platform[0, 2]
    end
    public_class_method :player_match?

    attr_reader :wins, :losses

    def initialize(db_user, replays)
      @wins, @losses, @stats = 0, 0, []
      replays.each { |replay|
        TEAM_GROUPS.each { |us, them|
          our_players = replay.public_send(us).players
          player = our_players.find { |p| self.class.player_match?(db_user, p) }
          next unless player

          @stats.push(player.stats)
          our_goals = replay.public_send(us).stats.core.goals
          their_goals = replay.public_send(them).stats.core.goals
          @wins += 1 if our_goals > their_goals
          @losses += 1 if our_goals < their_goals
        }
      }
      @num_games = Rational(@stats.length)
    end

    def avg(group, attrib)
      return sum(group, attrib) / @num_games
    end

    def sum(group, attrib)
      values = @stats.map { |stat| stat.public_send(group).public_send(attrib) }
      # rubocop:disable Performance/Sum
      return values.reduce { |acc, elem| acc + elem } # Required for Durations.
      # rubocop:enable Performance/Sum
    end
  end
  private_constant :PlayerStats
  ###########################

  def series(jubi, uploader, members, channel, duration = 72.hours)
    db_uploader, db_users = fetch_users(uploader, members)
    unless db_uploader.platform == :steam
      raise JubiBotError, 'Only `steam` users can use the `series` command.'
    end

    names = members.sentence { |member| "**#{member.display_name}**" }
    summaries = fetch_summaries(db_uploader, db_users, duration)
    if summaries.empty?
      return "Could not find any games in the last #{duration.hours} hours " \
             "with #{names}."
    end

    channel.send_message("Found #{summaries.length} games with #{names} in " \
      "the last #{duration.hours} hours.")

    db_replays, api_replays = fetch_replays(channel,
                                            summaries,
                                            db_uploader.server)
    all_replays = db_replays.merge(api_replays)
    raise StandardError, "Couldn't fetch any replays?" if all_replays.empty?

    RLDB.store_replays(db_uploader.account, api_replays.values)
    messages = replay_messages(members, db_users, all_replays)
    jubi.send_paginated_message(channel, messages)
  end

  def alltime(jubi, uploader, members, channel)
    db_uploader, db_users = fetch_users(uploader, members)
    unless db_uploader.platform == :steam
      raise JubiBotError, 'Only `steam` users can use the `alltime` command.'
    end

    names = members.sentence { |member| "**#{member.display_name}**" }
    replays = RLDB.replays_with_players(db_uploader.account, db_users)
    return "Could not find any games with #{names}." if replays.empty?

    channel.send_message("Found #{replays.length} games with #{names}.")

    messages = replay_messages(members, db_users, replays)
    jubi.send_paginated_message(channel, messages)
  end

  private

  #####################################
  # RESPONSE MARKUP
  #####################################
  def replay_messages(members, db_users, replays)
    player_stats = db_users.map { |db_user|
      [db_user.id, PlayerStats.new(db_user, replays.values)]
    }.to_h
    return SERIES_MAP.map { |group, attributes|
      <<~MESSAGE.strip
        **#{group}**
        #{description(members, player_stats, group.downcase, attributes)}
      MESSAGE
    }
  end

  def description(members, player_stats, group, attributes)
    rjust = attributes.values.max_by(&:length).length

    description = '```'
    description << "\n"
    description << members.first.display_name[0, 5].rjust(rjust + 8)
    members[1..].each { |member|
      description << member.display_name[0, 5].rjust(7)
    }
    description << "\n"
    attributes.each_pair { |attribute, display|
      group_name, attrib = group, attribute.to_s
      group_name, attrib = attrib.split('__', 2) if attrib.include?('__')

      description << "#{display.rjust(rjust)}:"
      members.each { |member|
        player_stat = player_stats.fetch(member.id)
        value = if player_stat.respond_to?(attribute)
                  player_stat.public_send(attribute)
                else
                  avg = player_stat.avg(group_name, attrib)
                  if avg.is_a?(Duration)
                    "#{avg.minutes!}m#{avg.seconds!}s"
                  else
                    avg.to_f.round([4 - Math.log((avg + 1), 10), 0].max)
                  end
                end
        description << "  #{value.to_s.rjust(5)}"
      }
      description << "\n"
    }
    description << '```'
    return description
  end

  #####################################
  # FETCHING DATA
  #####################################
  # Fetches database entries of uploader and series members.
  def fetch_users(uploader, members)
    all_users = [uploader] + members
    all_users.uniq!
    all_users.map!(&:id)
    db_all = RLDB.users(all_users, uploader.server.id)
    return db_all.fetch(uploader.id), db_all.fetch_values(*members.map(&:id))
  end

  # Fetches summaries of all games from uploader with all users playing.
  def fetch_summaries(db_uploader, db_users, duration)
    summaries = try_api(db_uploader.server) { |api|
      api.replays('uploader': db_uploader.account,
                  'replay-date-after': (DateTime.now - duration).rfc3339,
                  'sort-by': 'replay-date',
                  'sort-dir': 'asc',
                  'count': 200)
    }

    return summaries.select { |summary|
      players = summary.orange.players + summary.blue.players
      db_users.all? { |db_user|
        players.any? { |player| PlayerStats.player_match?(db_user, player) }
      }
    }
  end

  # Fetches replay details of all games in given summaries.
  def fetch_replays(channel, summaries, server)
    replay_ids = summaries.map(&:id)
    db_replays = RLDB.replays(replay_ids)

    replay_ids.delete_if { |replay_id| db_replays.key?(replay_id) }
    replay_ids = Concurrent::Array.new(replay_ids)
    api_replays = Concurrent::Hash.new

    progress_thread = Thread.new {
      loop {
        sleep(10)
        channel.send_message("#{replay_ids.length} replays left to fetch.")
      }
    }

    begin
      Array.new(NUM_THREADS) {
        Thread.new {
          while (replay_id = replay_ids.pop)
            api_replays[replay_id] = try_api(server) { |api|
              api.replay(replay_id)
            }
          end
        }
      }.each(&:join)
    rescue StandardError
      # Ballchasing.com error, but we move on.
    ensure
      progress_thread.kill
    end

    return db_replays, api_replays
  end

  # Generic wrapper of calls to ballchasing.com API with error catching.
  def try_api(server)
    api = Ballchasing::API.new(
        ENV['BALLCHASING_TOKEN'],
        "TuskBot; server=#{server}")
    return yield(api)
  rescue Ballchasing::RateLimitError => e
    Discordrb::LOGGER.warn(<<~WARN.chomp)
      Token: #{e.token}
      Error: <#{e.class}>: ballchasing.com rate limit hit
    WARN
    raise JubiBotError,
          'Sorry, Tusk has exceeded the rate limit set by ballchasing.com. ' \
          'If you wait a few seconds you can probably try again.'
  rescue Ballchasing::ResponseError => e
    Discordrb::LOGGER.warn(<<~WARN.chomp)
      Token: #{e.token}
      Error: <#{e.class}>: #{e.response}
    WARN
    raise JubiBotError, 'API error of some sort with ballchasing.com'
  end
end
