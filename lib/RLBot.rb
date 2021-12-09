require 'core'
require 'singleton'

require_relative 'RLDB'
require_relative 'RLRanks'
require_relative 'RLRegions'
require_relative 'RLSeries'
require_relative 'RLUtils'

class RLBot
  include Singleton

  ##### PRIVATE CONSTANTS #####
  PLATFORMS = %i[steam xbox ps epic].freeze
  private_constant :PLATFORMS
  #############################

  ##### CLASS METHODS #####
  def self.validate_platform(platform)
    return if PLATFORMS.include?(platform)

    platform_list = PLATFORMS.sentence('or') { |e| "`#{e}`" }
    raise InvalidParam, "`platform` must be one of #{platform_list}."
  end

  def self.validate_region(region)
    return if RLRegions::REGION_ROLES.include?(region)

    region_list = RLRegions::REGION_ROLES.to_a.sentence('or') { |e| "`#{e}`" }
    raise InvalidParam, "`region` must be one of #{region_list}."
  end
  #########################

  def initialize
    @start_time = Time.now
  end

  #######################################
  # MANAGEMENT (UNDOCUMENTED, ADMIN ONLY)
  #######################################
  def user_info(member, server)
    db_user = RLDB.user(member.id, server.id)

    return <<~USER.strip
      *Member Name*:  **#{member.display_name}**
      *Discord ID*:  #{member.id}
      *Server ID*:  #{server.id}
      *Account ID*:  #{db_user.account}
      *Platform*:  #{db_user.platform}
    USER
  end

  def admin_register(member, orig_account, platform, region, event)
    return register(member, orig_account, platform, region, event)
  end

  def admin_unregister(member)
    return unregister(member)
  end

  def playing(bot, game)
    bot.game = game
    return 'Fun game.'
  end

  def listening(bot, song)
    bot.listening = song
    return 'Cool tune.'
  end

  def watching(bot, show)
    bot.watching = show
    return 'Great show.'
  end

  def clear_playlists(server)
    RLDB.store_server_playlists(server.id, [])
    return "#{server.name} role playlists cleared back to default: " \
           "#{RLDB::PLAYLIST_COLUMNS.sentence { |pl| "`#{pl}`" }}."
  end

  def playlists(server, playlists)
    if playlists.empty?
      playlists = RLDB.server_playlists(server.id)
      playlists = RLDB::PLAYLIST_COLUMNS if playlists.empty?
    else
      RLDB.store_server_playlists(server.id, playlists)
    end

    return "#{server.name} role playlists set to " \
           "#{playlists.sentence { |pl| "`#{pl}`" }}."
  end

  def update_all_roles(event)
    all_users = RLDB.all_users(event.server.id)
    all_users.each { |db_user|
      member = event.server.member(db_user.id)
      if member
        ranks(member, event)
        sleep(3)
      end
    }
  end

  def command_prefix(server)
    return "#{server.name} command prefix set to " \
           "#{RLDB.server_prefix(server.id)}"
  end

  def set_command_prefix(server, prefix)
    RLDB.store_server_prefix(server.id, prefix)
    return "#{server.name} command prefix set to #{prefix}"
  end

  def enable_region_roles(server)
    RLDB.store_server_region_roles(server.id, true)
    return "#{server.name} region roles now enabled"
  end

  def disable_region_roles(server)
    RLDB.store_server_region_roles(server.id, false)
    return "#{server.name} region roles now disabled"
  end

  def enable_platform_roles(server)
    RLDB.store_server_platform_roles(server.id, true)
    return "#{server.name} platform roles now enabled"
  end

  def disable_platform_roles(server)
    RLDB.store_server_platform_roles(server.id, false)
    return "#{server.name} platform roles now disabled"
  end

  def uptime
    return Duration.new(Time.now - @start_time).to_s
  end

  #######################################
  # USER REGISTRATION MANAGEMENT
  #######################################
  def register(member, account, platform, region, event)
    event.channel.send_message("Now registering: **#{member.display_name}**...")
    return "Couldn't find **#{orig_account}** on *#{platform}*." unless account

    RLDB.register(member.id, member.server.id, account, platform)
    event.channel.send_message(
        "**#{member.display_name}** successfully registered.")

    RLRegions.update_nick(member, region)
    RLRoles.update_roles(member, RLRanks.ranks(member, event), platform, region)
    return
  end

  def unregister(member)
    RLDB.unregister(member.id, member.server.id)
    RLRegions.remove_nick(member)
    RLRoles.remove_roles(member)
    return "**#{member.display_name}** successfully unregistered."
  end

  #######################################
  # RANK INFORMATION
  #######################################
  def ranks(member, event)
    RLRoles.update_roles(member, RLRanks.ranks(member, event))
    return
  end

  #####################################
  # SERIES
  #####################################
  def series(jubi, uploader, members, channel)
    return RLSeries.series(jubi, uploader, members, channel)
  end

  def alltime(jubi, uploader, members, channel)
    return RLSeries.alltime(jubi, uploader, members, channel)
  end

  #######################################
  # SIMPLE LINKS
  #######################################
  def invite(jubi)
    return jubi.invite
  end

  def support
    return 'https://discord.gg/2YSmnyX'
  end

  def twitch
    return 'http://twitch.tv/rocketleague'
  end

  def ballchasing(member)
    return RLUtils.link(member, {
      steam: 'http://ballchasing.com/player/steam/'
    })
  end

  def steam(member)
    return RLUtils.link(member, {
      steam: 'http://steamcommunity.com/profiles/'
    })
  end

  def tracker(member)
    return RLUtils.link(member, {
      steam: 'http://rocketleague.tracker.network/rocket-league/profile/steam/',
      xbox: 'https://rocketleague.tracker.network/rocket-league/profile/xbl/',
      ps: 'https://rocketleague.tracker.network/rocket-league/profile/psn/',
      epic: 'https://rocketleague.tracker.network/rocket-league/profile/epic/'
    })
  end
end
