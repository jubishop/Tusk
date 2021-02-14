require 'http'

require 'jubibot'

require_relative 'RLDB'

class RLUtils
  ##### PRIVATE CONSTANTS #####
  RANK_EMOJIS = [
    718611763981189212, # Bronze 1
    718611808679886880, # Bronze 2
    718611808755122278, # Bronze 3
    718611808998653992, # Silver 1
    718611808793133057, # Silver 2
    718611808994197534, # Silver 3
    718611808742539285, # Gold 1
    718611809090928750, # Gold 2
    718611808734150667, # Gold 3
    718611809069694976, # Platinum 1
    718612668281389186, # Platinum 2
    718612668306686092, # Platinum 3
    718612667924742265, # Diamond 1
    718612668281389236, # Diamond 2
    718612668302360647, # Diamond 3
    718612668117680190, # Champion 1
    718612667987918882, # Champion 2
    718612668335784018, # Champion 3
    760884036025057330, # Grand Champ 1
    760884036074733649, # Grand Champ 2
    760884036104224799, # Grand Champ 3
    760884036091641957  # Supersonic Legend
  ].freeze
  private_constant :RANK_EMOJIS

  RANK_NAMES = [
    'Bronze 1',
    'Bronze 2',
    'Bronze 3',
    'Silver 1',
    'Silver 2',
    'Silver 3',
    'Gold 1',
    'Gold 2',
    'Gold 3',
    'Platinum 1',
    'Platinum 2',
    'Platinum 3',
    'Diamond 1',
    'Diamond 2',
    'Diamond 3',
    'Champion 1',
    'Champion 2',
    'Champion 3',
    'Grand Champ 1',
    'Grand Champ 2',
    'Grand Champ 3',
    'Supersonic Legend'
  ].freeze
  private_constant :RANK_NAMES
  #############################

  def self.link(member, urls)
    db_user = RLDB.user(member.id, member.server.id)
    unless urls.key?(db_user.platform)
      raise JubiBotError, "**#{member.display_name}**'s platform:" \
        " **#{db_user.platform}** does not support this link."
    end

    return escape(urls.fetch(db_user.platform) + db_user.account)
  end

  def self.rank_emoji(bot, rank)
    return bot.emoji(RANK_EMOJIS[rank.rank])
  end

  def self.rank_name(rank)
    rank_name = RANK_NAMES[rank.rank]
    rank_name += " (#{rank.mmr})" unless rank.mmr.nil?
    return rank_name
  end

  def self.rank_url(rank)
    return "https://cdn.discordapp.com/emojis/#{RANK_EMOJIS[rank.rank]}.png"
  end

  ##### PRIVATE #####

  def self.escape(url)
    return url.gsub(' ', '%20')
  end
  private_class_method :escape
end
