
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
  debug: false
  script:
  - if <server.has_file[../dWild/config.yml]>:
    - ~yaml load:../dWild/config.yml id:dWild_config
    - announce to_console "[dWild] Loaded config.yml"

dWild:
  type: world
  debug: false
  events:
    on reload scripts:
      - inject dWild_init

    on server start:
      - inject dWild_init

      - if <yaml.list.contains[dWild_config]>:
        - narrate "<green>Loaded dWild config successfully."
      - else:
        - narrate "<red>One or more config files failed to load. Please check your console log."
        - stop

dWild_cmd:
  type: command
  debug: false
  name: dwild
  aliases: wild
  permission: dwild.use
  script:
    - if <player.has_permission[dWild.wild]]>

      - define minDistFromSpawn:<yaml[dWild_config].read[min-distance-from-spawn]>
      - define maxDistFromSpawn:<yaml[dWild_config].read[max-distance-from-distance]>

      - if <yaml[dWild_config].read[use-worldborder]> == true:
        - if <player.location.world.border_size> > 10000:
          - define safeSpawnDistPositive:<player.location.world.border_size.sub[1000]>
          - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>
        - else
          - define safeSpawnDistPositive:<player.location.world.border_size.sub[<player.location.world.border_size.mul[0.10]>]>
          - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>

      - else:

        - define safeSpawnDistPositive:<[maxDistFromSpawn].sub[<[maxDistFromSpawn].as_element.mul[0.10]>]>
        - define safeSpawnDistNegative:<[safeSpawnDistPositive].to_element.mul[-1]>

      - define randZCoords:<util.random.int[<[safeSpawnDistNegative]>].to[<[safeSpawnDistPositive]>]>
      - define randXCoords:<util.random.int[<[safeSpawnDistNegative]>].to[<[safeSpawnDistPositive]>]>

    - if <player.location.world.spawn_location.z> > <[minDistFromSpawn]> && <player.location.world.spawn_location.x> > <[minDistFromSpawn]>

      - choose <yaml[dWild_config].read[teleport-type]>:
        - case safe:
          - 
          - 
        - case wild:
        - default:


# --- Ignore below here, for now.


      - if <player.has_flag[dWildRecent]>:
        - narrate "<&c>You must wait <player.flag[dWildRecent].expiration.formatted> before you can use this command again."
        - stop
      - if <context.args.get[1]||null> == null:
        - define target:<player>
      - else if <player.has_permission[dWild.other]>:
        - define target <server.match_player[<context.args.get[1]>]>
      - else:
        - narrate "<&c>You lack the permissions to teleport another player."
        - stop

system_wilderness_teleport_events:
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
