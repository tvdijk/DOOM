cmake_minimum_required(VERSION 3.15)
project(DOOM C)

set(CMAKE_C_STANDARD 11)

add_compile_definitions(NORMALUNIX LINUX)

add_executable(DOOM
        linuxdoom-1.10/am_map.c
        linuxdoom-1.10/i_main.c
        linuxdoom-1.10/d_items.c
        linuxdoom-1.10/d_main.c
        linuxdoom-1.10/d_net.c
        linuxdoom-1.10/doomstat.c
        linuxdoom-1.10/dstrings.c
        linuxdoom-1.10/f_finale.c
        linuxdoom-1.10/f_wipe.c
        linuxdoom-1.10/g_game.c
        linuxdoom-1.10/hu_lib.c
        linuxdoom-1.10/hu_stuff.c
        linuxdoom-1.10/i_net.c
        linuxdoom-1.10/i_sound.c
        linuxdoom-1.10/i_system.c
        linuxdoom-1.10/i_video.c
        linuxdoom-1.10/info.c
        linuxdoom-1.10/m_argv.c
        linuxdoom-1.10/m_bbox.c
        linuxdoom-1.10/m_cheat.c
        linuxdoom-1.10/m_fixed.c
        linuxdoom-1.10/m_menu.c
        linuxdoom-1.10/m_misc.c
        linuxdoom-1.10/m_random.c
        linuxdoom-1.10/p_ceilng.c
        linuxdoom-1.10/p_doors.c
        linuxdoom-1.10/p_enemy.c
        linuxdoom-1.10/p_floor.c
        linuxdoom-1.10/p_inter.c
        linuxdoom-1.10/p_lights.c
        linuxdoom-1.10/p_plats.c
        linuxdoom-1.10/p_map.c
        linuxdoom-1.10/p_maputl.c
        linuxdoom-1.10/p_mobj.c
        linuxdoom-1.10/p_pspr.c
        linuxdoom-1.10/p_saveg.c
        linuxdoom-1.10/p_setup.c
        linuxdoom-1.10/p_sight.c
        linuxdoom-1.10/p_spec.c
        linuxdoom-1.10/p_switch.c
        linuxdoom-1.10/p_telept.c
        linuxdoom-1.10/p_tick.c
        linuxdoom-1.10/p_user.c
        linuxdoom-1.10/r_bsp.c
        linuxdoom-1.10/r_data.c
        linuxdoom-1.10/r_draw.c
        linuxdoom-1.10/r_main.c
        linuxdoom-1.10/r_plane.c
        linuxdoom-1.10/r_segs.c
        linuxdoom-1.10/r_sky.c
        linuxdoom-1.10/r_things.c
        linuxdoom-1.10/s_sound.c
        linuxdoom-1.10/sounds.c
        linuxdoom-1.10/st_lib.c
        linuxdoom-1.10/st_stuff.c
        linuxdoom-1.10/tables.c
        linuxdoom-1.10/v_video.c
        linuxdoom-1.10/w_wad.c
        linuxdoom-1.10/wi_stuff.c
        linuxdoom-1.10/z_zone.c
        )

target_include_directories(DOOM
        PRIVATE
            /opt/X11/include)

target_link_libraries(DOOM
        /opt/X11/lib/libX11.dylib
        /opt/X11/lib/libXext.dylib)
