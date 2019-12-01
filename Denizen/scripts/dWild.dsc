
# +--------------------
# |
# | dWild
# |
# | Allows players to be teleported to a random
# | location, a minimum (and maximum) distance 
# | from spawn.
# |
# +----------------------
#
# @author GoMinecraft ( Discord: GoMinecraft#1421 )
# @date 2019/11/28
# @denizen-build REL-1696
# @script-version 0.0.1
#
# Usage - Alias: /wild:
# /dwild
# /dwild (version) - Shows the version
# /dwild reload - Reloads the config.yml
#
# Permissions:
# dwild.wild - Lets a player use /wild
# dwild.wild.other
#
# dwild.version - Shows the dwild version number
# dwild.reload - Reloads the dwild config

# ---- Don't edit below here unless you know what you're doing.
# ---- I definitely don't know what I'm doing.

dWild_version:
  type: yaml data
  version: 0.0.1

dWild_init:
  type: task
  debug: true
  script:
  - if <server.has_file[../dWild/config.yml]>:
    - ~yaml load:../dWild/config.yml id:dWild_config
    - announce to_console "[dWild] Loaded config.yml"

  - if <yaml.list.contains[dWild_config]>:
    - announce to_console "<green>Loaded dWild config successfully."
    - flag server dWildLoaded:true
  - else:
    - announce to_console "<red>One or more config files failed to load. Please check your console log."
    - flag srver dWildLoaded:false

dWild:
  type: world
  debug: false
  events:
    on reload scripts:
      - inject dWild_init

    on server start:
      - inject dWild_init

dWild_cmd:
  type: command
  debug: false
  name: dwild
  aliases:
  - wild
  permission: dwild.wild
  script:

  - if <server.flag[dWildLoaded]> == false:
    - narrate "An error has occured in dWild."
    - stop

  - if <player.has_flag[dWildRecent]>:
    - narrate "<&c>You must wait <player.flag[dWildRecent].expiration.formatted> before you can use this command again."
    - stop

  - if <context.args.get[1]||null> == null:
    - define target:<player>
  - else:
    - if <player.has_permission[dWild.other]>:
      - define target:<server.match_player[<context.args.get[1]>]>
    - else:
      - narrate "You do not have permission to use wild on other players."
      - stop

  - define minDistFromSpawn:<yaml[dWild_config].read[min-teleport-distance]>
  - define maxDistFromSpawn:<yaml[dWild_config].read[max-teleport-distance]>

  - if <yaml[dWild_config].read[use-worldborder]> == true:
    - narrate "use-worldborder is true"
    - define border:<player.location.world.border_size>
    - if <player.location.world.border_size> > 10000:
      - narrate "Border > 10000"
      - define safeSpawnDistPositive:<player.location.world.border_size.sub[1000]>
      - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>
    - else:
      - narrate "Border < 10000"
      - define safeSpawnDistPositive:<player.location.world.border_size.sub[<player.location.world.border_size.mul[0.10]>]>
      - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>
  - else:
    - narrate "use-worldborder is false"
    - define safeSpawnDistPositive:<[maxDistFromSpawn].sub[<[maxDistFromSpawn].as_element.mul[0.10]>]>
    - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>

  - define randZCoords:<util.random.int[<[safeSpawnDistNegative]>].to[<[safeSpawnDistPositive]>]>
  - define randXCoords:<util.random.int[<[safeSpawnDistNegative]>].to[<[safeSpawnDistPositive]>]>

  - if <player.has_permission[dWild.wild]>
    - teleport <player> l@[<[randXCoords]>,255,<[randZCoords]>]
    - flag <[target]> freeFalling:true duration:<yaml[dWild_config].read[immunity-seconds]>
    - flag <[target]> dWildRecent:true duration:<yaml[dWild_config].read[command-cooldown]>


dWild_events:
  type: world
  debug: false
  events:
    on player damaged by FALL bukkit_priority:LOWEST:
      - if <player.has_flag[freeFalling]>:
        - flag <player> freeFalling:!
        - determine cancelled

    on entity starts gliding:
      - if <player.has_flag[freeFalling]>:
        - flag <player> freeFalling:!
