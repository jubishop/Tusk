require 'concurrent'

require 'calculated'
require 'core'
require 'duration'

require_relative 'RLDB'

class RLStats
  ##### PRIVATE CONSTANTS #####
  # rubocop:disable Style/StringHashKeys
  STATS_MAP = {
    'Core' => {
      'score' => 'Score',
      'goals' => 'Goals',
      'assists' => 'Assists',
      'saves' => 'Saves',
      'shots' => 'Shots',
      'hits' => 'Hits',
      'passes' => 'Passes',
      'dribbles' => 'Dribbles',
      'aerials' => 'Aerials',
      'speed' => 'Speed',
      'turnovers' => 'Turnovers',
      'takeaways' => 'Takeaways'
    },
    'Boost' => {
      'boost usage' => 'Total Used',
      'average boost level' => 'Avg Boost',
      'num small boosts' => 'Small Pads',
      'num large boosts' => 'Big Pads',
      'num stolen boosts' => 'Stolen',
      'wasted usage' => 'Wasted',
      'time full boost' => 'Time Full',
      'time low boost' => 'Time Low',
      'time no boost' => 'Time Empty',
      'total boost efficiency' => 'Boost Efficiency'
    },
    'Positioning' => {
      'time closest to ball' => 'Closest to Ball',
      'time furthest from ball' => 'Furthest from Ball',
      'time close to ball' => 'Close to Ball',
      'time closest to team center' => 'Closest to Center',
      'time furthest from team center' => 'Furthest from Center',
      'average distance from center' => 'Avg Dist from Center',
      'time near wall' => 'Near Wall',
      'time in corner' => 'In Corner',
      'time most forward player' => 'Most Forward',
      'time most back player' => 'Most Back',
      'time in defending half' => 'In Defending Half',
      'time in attacking half' => 'In Attacking Half',
      'time behind ball' => 'Behind Ball',
      'time in front ball' => 'In Front of Ball'
    },
    'Power' => {
      'ball hit forward' => 'Ball Hit Forward',
      'ball hit backward' => 'Ball Hit Backward',
      'average hit distance' => 'Avg Hit Distance',
      'shot %' => 'Shooting Percentage',
      'time at slow speed' => 'At Slow Speed',
      'time at super sonic' => 'At Supersonic',
      'time at boost speed' => 'At Boost Speed',
      'time on ground' => 'On Ground',
      'time low in air' => 'Low in Air',
      'time high in air' => 'High in Air',
      'aerial efficiency' => 'Aerial Efficiency'
    }
  }.freeze
  # rubocop:enable Style/StringHashKeys
  private_constant :STATS_MAP
  #############################

  def self.stats(jubi, members, channel)
    names = lambda {
      members.sentence { |member| "**#{member.display_name}**" }
    }

    channel.send_message("Now fetching stats for: #{names.run}...")
    db_users = RLDB.users(members.map(&:id), members.first.server.id)

    members.delete_if { |member|
      unless db_users.fetch(member.id).platform == :steam
        channel.send_message("**#{member.display_name}** is not on steam.")
      end
    }

    progress_thread = Thread.new {
      longs = 0
      loop {
        sleep(10)
        channel.send_message(
            "Fetching stats takes a #{'LONG ' * longs}while sometimes...")
        longs += 1
      }
    }

    play_styles = Concurrent::Map.new
    db_users.filter_map { |id, db_user|
      Thread.new {
        begin
          play_styles[id] = Calculated::API.play_style(db_user.account)
        rescue Calculated::Error
          member = members.delete(members.find { |m| m.id == db_user.id })
          channel.send_message(
              "Could not find stats for **#{member.display_name}**.")
        end
      } if db_user.platform == :steam
    }.each(&:join)
    progress_thread.kill

    if play_styles.empty?
      return 'Could not find stats for any requested player.'
    end

    channel.send_message("Average stats per game for #{names.run}:\n")

    messages = STATS_MAP.map { |group_name, attributes|
      <<~MESSAGE.strip
        **#{group_name}**
        #{description(members, play_styles, attributes)}
      MESSAGE
    }
    jubi.send_paginated_message(channel, messages)
  end

  def self.description(members, play_styles, attributes)
    rjust = attributes.values.max_by(&:length).length

    description = '```'
    description << "\n"
    description << members.first.display_name[0, 5].rjust(rjust + 8)
    members[1..].each { |member|
      description << member.display_name[0, 5].rjust(7)
    }
    description << "\n"
    attributes.each_pair { |attribute, display|
      description << "#{display.rjust(rjust)}:"
      members.each { |member|
        value = play_styles.fetch(member.id).attribute(attribute)
        value = if value.is_a?(Duration)
                  "#{value.minutes!}m#{value.seconds!}s"
                else
                  value.round([4 - Math.log((value + 1), 10), 0].max)
                end
        value = value.to_s.rjust(5) # right justify
        description << "  #{value}"
      }
      description << "\n"
    }
    description << '```'
    return description
  end
end
