{ lib, pkgs, ... }:
let
  fhsArgs = pkgs.appimageTools.defaultFhsEnvArgs;

  bootstrap = pkgs.writeShellApplication {
    name = "gazebo";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.findutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.micromamba
      pkgs.which
    ];
    text = ''
      set -euo pipefail

      spec="''${GAZEBO_CONDA_SPEC:-gz-sim8}"
      channel="''${GAZEBO_CONDA_CHANNEL:-conda-forge}"
      root="''${XDG_DATA_HOME:-$HOME/.local/share}/gazebo-micromamba"
      env_dir="$root/envs/$spec"
      worlds_dir="$env_dir/share/gz/$spec/worlds"
      override_root="$root/overrides/$spec"
      override_gz_share="$override_root/share/gz"
      override_rb_dir="$override_root/lib/ruby/gz"
      override_sim_rb="$override_rb_dir/codex_cmdsim8.rb"
      override_sim_yaml="$override_gz_share/sim8.yaml"

      export MAMBA_ROOT_PREFIX="$root"
      mkdir -p "$root"
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/gazebo"
      mkdir -p "''${XDG_CACHE_HOME:-$HOME/.cache}/gazebo/fuel"

      if [ ! -x "$env_dir/bin/gz" ]; then
        echo "Bootstrapping Gazebo package '$spec' from channel '$channel' into $env_dir" >&2
        micromamba create --yes --channel "$channel" --prefix "$env_dir" "$spec"
      fi

      mkdir -p "$override_gz_share" "$override_rb_dir"

      cat >"$override_sim_yaml" <<EOF
--- # Subcommands available inside Gazebo Sim
format: 1.0.0
library_name: gz-sim-gz
library_version: 8.10.0
library_path: $override_sim_rb
commands:
    - sim : Run and manage the Gazebo Simulator.
---
EOF

      cat >"$override_sim_rb" <<EOF
require '$env_dir/lib/ruby/gz/cmdsim8'

OriginalCmd = Cmd
Object.send(:remove_const, :Cmd)

class Cmd < OriginalCmd
  def codex_kill_process(pid, name, timeout)
    begin
      self.killProcess(pid, name, timeout)
    rescue Errno::ESRCH
      nil
    end
  end

  def parse(args)
    mutable_args = args.dup
    internal_mode = nil

    if mutable_args.delete('--codex-internal-server')
      internal_mode = 'server'
    elsif mutable_args.delete('--codex-internal-gui')
      internal_mode = 'gui'
    end

    options = super(mutable_args)

    case internal_mode
    when 'server'
      options['server'] = 1
      options['gui'] = 0
      options['wait_gui'] = 1
    when 'gui'
      options['gui'] = 1
      options['server'] = 0
      options['wait_gui'] = 1
    end

    options
  end

  def codex_combined_mode?(args)
    return false unless args[0] == 'sim'
    return false if args.include?('--codex-internal-server')
    return false if args.include?('--codex-internal-gui')
    return false if args.include?('-g') || args.include?('-s')
    return false if args.include?('-h') || args.include?('--help')
    true
  end

  def execute(args)
    if args.include?('--codex-internal-server')
      Process.setproctitle('gz sim server')
      return super(args)
    end

    if args.include?('--codex-internal-gui')
      Process.setproctitle('gz sim gui')
      return super(args)
    end

    mutable_args = args.dup
    return super(mutable_args) unless codex_combined_mode?(mutable_args)

    gz_bin = '$env_dir/bin/gz'
    passthrough = mutable_args[1..] || []

    server_pid = Process.spawn({ 'RMT_PORT' => '1500' }, gz_bin, 'sim',
                               '--codex-internal-server', *passthrough)
    gui_pid = Process.spawn({ 'RMT_PORT' => '1501' }, gz_bin, 'sim',
                            '--codex-internal-gui', *passthrough)

    handler = proc do
      codex_kill_process(gui_pid, 'Gazebo Sim GUI', 5.0)
      codex_kill_process(server_pid, 'Gazebo Sim Server', 5.0)
      exit 1
    end

    Signal.trap('INT', &handler)
    Signal.trap('TERM', &handler)

    pid, _status = Process.wait2

    if pid == server_pid
      codex_kill_process(gui_pid, 'Gazebo Sim GUI', 5.0)
    else
      codex_kill_process(server_pid, 'Gazebo Sim Server', 5.0)
    end
  end
end
EOF

      export PATH="$env_dir/bin:$PATH"
      export GZ_CONFIG_PATH="$env_dir/share/gz''${GZ_CONFIG_PATH:+:$GZ_CONFIG_PATH}:$override_gz_share"
      export GZ_IP="''${GZ_IP:-127.0.0.1}"
      export GZ_PARTITION="''${GZ_PARTITION:-gazebo''${UID:-0}}"

      run_gz() {
        exec "$env_dir/bin/gz" "$@"
      }

      resolve_world() {
        local world="''${1:-}"

        if [ -z "$world" ]; then
          printf '%s\n' "$worlds_dir/shapes.sdf"
          return 0
        fi

        if [ -f "$world" ]; then
          printf '%s\n' "$world"
          return 0
        fi

        if [ -f "$worlds_dir/$world" ]; then
          printf '%s\n' "$worlds_dir/$world"
          return 0
        fi

        if [ -f "$worlds_dir/$world.sdf" ]; then
          printf '%s\n' "$worlds_dir/$world.sdf"
          return 0
        fi

        printf '%s\n' "$world"
      }

      run_split() {
        local world
        world="$(resolve_world "''${1:-}")"

        micromamba run --prefix "$env_dir" gz sim "$world" -s -v 4 &
        server_pid=$!

        cleanup() {
          kill "$server_pid" 2>/dev/null || true
          wait "$server_pid" 2>/dev/null || true
        }

        trap cleanup EXIT INT TERM

        # Give the server a moment to start and advertise the world.
        sleep 2

        run_gz sim -g
      }

      if [ "$#" -eq 0 ]; then
        run_gz sim
      fi

      case "$1" in
        shell)
          shift
          exec bash "$@"
          ;;
        menu|quickstart)
          shift
          run_gz sim "$@"
          ;;
        split)
          shift
          run_split "''${1:-}"
          ;;
        gz)
          shift
          run_gz "$@"
          ;;
        sim)
          shift
          run_gz sim "$@"
          ;;
        *)
          run_gz sim "$@"
          ;;
      esac
    '';
  };

  desktopItem = pkgs.makeDesktopItem {
    name = "gazebo";
    exec = "gazebo";
    desktopName = "Gazebo";
    comment = "Gazebo simulator launcher for NixOS";
    categories = [
      "Development"
      "Education"
      "Science"
    ];
    terminal = false;
  };

  gazebo = pkgs.buildFHSEnv (
    lib.recursiveUpdate fhsArgs {
      name = "gazebo";

      extraPreBwrapCmds = ''
        # Some Wayland sessions using xwayland-satellite do not export DISPLAY
        # into every shell. If there is exactly one host X11 socket, use it.
        if [ -z "$DISPLAY" ] && [ -d /tmp/.X11-unix ]; then
          x_sockets=(/tmp/.X11-unix/X*)
          if [ "''${#x_sockets[@]}" -eq 1 ] && [ -S "''${x_sockets[0]}" ]; then
            display_nr=''${x_sockets[0]##*/X}
            export DISPLAY=":$display_nr"
          fi
        fi
      '';

      targetPkgs =
        pkgs:
        fhsArgs.targetPkgs pkgs
        ++ (with pkgs; [
          alsa-lib
          bashInteractive
          coreutils
          findutils
          gnugrep
          gnused
          libgbm
          libGLU
          libpulseaudio
          libxkbcommon
          mesa
          micromamba
          vulkan-loader
          wayland
          which
          xorg.libxcb
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXxf86vm
        ]);

      multiPkgs =
        pkgs:
        fhsArgs.multiPkgs pkgs
        ++ (with pkgs; [
          alsa-lib
          libgbm
          libGLU
          libpulseaudio
          libxkbcommon
          mesa
          vulkan-loader
          wayland
          xorg.libxcb
          xorg.libXcursor
          xorg.libXi
          xorg.libXinerama
          xorg.libXxf86vm
        ]);

      runScript = "${bootstrap}/bin/gazebo";

      profile = ''
        export GZ_FUEL_CACHE_PATH="''${XDG_CACHE_HOME:-$HOME/.cache}/gazebo/fuel"
        export QT_XKB_CONFIG_ROOT=/usr/share/X11/xkb
      '';

      extraInstallCommands = ''
        mkdir -p "$out/share/applications"
        cp ${desktopItem}/share/applications/*.desktop "$out/share/applications/"
      '';

      meta = {
        description = "Gazebo simulator launcher for NixOS using conda-forge packages inside an FHS environment";
        homepage = "https://gazebosim.org/";
        license = lib.licenses.asl20;
        mainProgram = "gazebo";
        platforms = [ "x86_64-linux" ];
      };
    }
  );
in
{
  environment.systemPackages = [ gazebo ];
}
