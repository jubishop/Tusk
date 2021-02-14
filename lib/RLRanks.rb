require 'http'

require 'core'
require 'calculated'
require 'discordrb'
require 'json'
require 'rlranks'
require 'steam'

require_relative 'RLDB'
require_relative 'RLRoles'

class RLRanks
  def self.ranks(member, event, db_user = nil)
    event.channel.send_message(
        "Now fetching ranks for: **#{member.display_name}**...")
    db_user ||= RLDB.user(member.id, member.server.id)

    ranks = fetch_ranks(db_user)
    return "Couldn't fetch ranks for #{member.display_name}." unless ranks

    RLRoles.update_role(member, ranks)
    RLDB.store_ranks(ranks)
    return "#{member.display_name} isn't ranked in anything." if ranks.unranked?

    event.channel.send_embed { |embed|
      embed.title = "**#{member.display_name}**'s Ranks"
      embed.timestamp = Time.now
      embed.color = 0xff0000

      _, longest_rank = ranks.max_by { |_, rank| rank.playlist.length }
      playlist_length = longest_rank.playlist.length
      embed.description = <<~DESCRIPTION.strip
        ```fix
        #{ranks.map { |_, rank|
          "#{rank.playlist.rjust(playlist_length)}: #{RLUtils.rank_name(rank)}"
        }.join("\n")}
        ```
      DESCRIPTION

      embed.thumbnail = Discordrb::Webhooks::EmbedThumbnail.new(
          url: RLUtils.rank_url(ranks.best))

      embed.footer = Discordrb::Webhooks::EmbedFooter.new(
          text: ranks.best.playlist,
          icon_url: RLUtils.rank_url(ranks.best))

      if db_user.platform == :steam
        player_summary = Steam::API.new.player_summary(db_user.account)
        embed.author = Discordrb::Webhooks::EmbedAuthor.new(
            name: player_summary[:personaname],
            url: player_summary[:profileurl],
            icon_url: player_summary[:avatarfull])
      end
    }
  end

  ##### PRIVATE #####

  class Error < RuntimeError; end
  private_constant :Error

  # Returns false if no ranks could be found
  def self.fetch_ranks(user)
    methods = {
      Calculated: -> { Calculated::API.ranks(user.id, user.account) },
      RLTracker: -> { rltracker(user) },
      RLDB: -> { RLDB.ranks(user.id, user.account, user.platform) }
    }
    methods.delete(:Calculated) unless user.platform == :steam
    methods.each_pair { |name, job|
      begin
        response = job.run
      rescue Error, Calculated::Error
        Discordrb::LOGGER.warn("#{name} failed for #{user}")
      end
      return response if response
    }
    return false
  end
  private_class_method :fetch_ranks

  RLT_PLATFORM_MAP = {
    xbox: :xbl,
    ps4: :psn,
    steam: :steam
  }.freeze
  private_constant :RLT_PLATFORM_MAP

  RLT_RANK_MAP = {
    'Ranked Duel 1v1': :duel,
    'Ranked Doubles 2v2': :doubles,
    'Ranked Solo Standard 3v3': :solo_standard,
    'Ranked Standard 3v3': :standard,
    'Hoops': :hoops,
    'Rumble': :rumble,
    'Dropshot': :dropshot,
    'Snowday': :snow_day,
    'Tournament Matches': :tournament
  }.freeze
  private_constant :RLT_RANK_MAP

  def self.rltracker(user)
    base_url = 'https://rocketleague.tracker.network/rocket-league/profile'
    response = get_response(<<~URI.chomp)
      #{base_url}/#{RLT_PLATFORM_MAP[user.platform]}/#{user.account}
    URI

    begin
      source = response.body.to_s
      json = source.match(/<script>window.__INITIAL_STATE__=(.+?});/)[1]
      profiles = JSON.parse(json)['stats-v2']['standardProfiles'].values.first
      playlists = profiles['segments'].select { |segment|
        segment['type'] == 'playlist'
      }
      rank_list = playlists.map { |playlist|
        [playlist['metadata']['name'], playlist['stats']['tier']['value']]
      }.to_h
    rescue StandardError
      raise Error
    end

    raise Error if rank_list.empty?

    ranks = {}
    rank_list.each { |playlist, rank|
      ranks[RLT_RANK_MAP.fetch(playlist.to_sym)] = rank - 1 if rank.positive?
    }

    return RLRanks.new(user.id, user.account, user.platform, **ranks)
  end
  private_class_method :rltracker

  # Helper for wrapping HTTP calls.  Throws Error on any failure.
  def self.get_response(url)
    begin
      response = HTTP.get(url)
    rescue HTTP::Error
      raise Error
    end
    raise Error unless response.status.success?

    return response
  end
  private_class_method :get_response
end
