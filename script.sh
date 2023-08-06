#!/bin/sh

# This script installs obbctl.
#
# Quick install: `curl https://onboardbase.github.io/obbctl-sh/ | bash`
#
# This script will install share to the directory you're in. To install
# somewhere else (e.g. /usr/local/bin), cd there and make sure you can write to
# that directory, e.g. `cd /usr/local/bin; curl https://onboardbase.github.io/obbctl-sh/ | sudo bash`
#
# Found a bug? Report it here: https://github.com/onboardbase/obbctl/issues
#
# Acknowledgments:
#  - getmic.ro: https://github.com/benweissmann/getmic.ro
#  - eget: https://github.com/zyedidia/eget

set -e -u

githubLatestTag() {
  finalUrl=$(curl "https://github.com/onboardbase/obbctl/releases/latest" -s -L -I -o /dev/null -w '%{url_effective}')
  printf "%s\n" "${finalUrl##*v}"
}

platform=''
machine=$(uname -m)
executable="obbctl"

if [[ "${OBB_PLATFORM:-unset}" != "unset" ]]; then
  platform="$OBB_PLATFORM"
else
  case "$(uname -s | tr '[:upper:]' '[:lower:]')" in
  "linux")
    case "$machine" in
    "arm64"* | "aarch64"*) platform='Linux_arm64' ;;
    "arm"* | "aarch"*) platform='Linux_arm64' ;;
    *"86") platform='Linux_x86_64' ;;
    *"64") platform='Linux_x86_64' ;;
    esac
    ;;
  "darwin")
    case "$machine" in
    "arm64"* | "aarch64"*) platform='Darwin_x86_64' ;;
    *"64") platform='Darwin_x86_64' ;;
    esac
    ;;
  "msys"* | "cygwin"* | "mingw"* | *"_nt"* | "win"*)
    case "$machine" in
    *"86") platform='Windows_x86_64' ;;
    *"64") platform='Windows_x86_64' ;;
    esac
    ;;
  esac
fi
if [ "$platform" = "" ]; then
  cat <<'EOM'
/=====================================\\
|      COULD NOT DETECT PLATFORM      |
\\=====================================/
Uh oh! We couldn't automatically detect your operating system.
To continue with installation, please choose from one of the following values:
- Linux_x86_64
- Linux_arm64
- Darwin_x86_64 (MacOS)
- Windows_x86_64
Export your selection as the OBB_PLATFORM environment variable, and then
re-run this script.
For example:
  $ export OBB_PLATFORM=Linux_x86_64
  $ curl https://onboardbase.github.io/obbctl-sh/ | bash
EOM
  exit 1
else
  printf "Detected platform: %s\n" "$platform"
fi

TAG=$(githubLatestTag onboardbase/ctl)

# if [ "$platform" = "Windows_x86_64" ]; then
#   extension='zip'
# else
extension='tar.gz'
# fi

printf "Latest Version: %s\n" "$TAG"
printf "Downloading https://github.com/onboardbase/obbctl/releases/download/v%s/obbctl-v%s-%s.%s\n" "$TAG" "$TAG" "$platform" "$extension"
curl -L "https://github.com/onboardbase/obbctl/releases/download/v$TAG/obbctl_$platform.$extension" >"$executable.$extension"

case "$extension" in
"zip") unzip -j "$executable.$extension" -d "obbctl_$platform" ;;
"tar.gz") tar -xvzf "$executable.$extension" "obbctl" ;;
esac

echo "Downloaded to obbctl_$platform/$executable"

rm "$executable.$extension"
rm -rf "obbctl_$platform"

##Make obbctl globally executable

# Check the operating system
if [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
  # Windows
  bin_dir="$HOME/bin"
  executable_path="$bin_dir/$executable"

  # Create the bin directory if it doesn't exist
  if [ ! -d "$bin_dir" ]; then
    mkdir "$bin_dir"
  fi

  # Copy the executable to the bin directory
  cp "$executable" "$executable_path"

  # Set executable permissions
  chmod +x "$executable_path"

  # Add the bin directory to the PATH environment variable
  echo "export PATH=\$PATH:$bin_dir" >>"$HOME/.bashrc"

elif [[ "$OSTYPE" == "linux-gnu"* || "$OSTYPE" == "darwin"* ]]; then
  # Linux or macOS
  executable_path="/usr/local/bin/$executable"

  # Copy the executable to the /usr/local/bin directory
  sudo cp "$executable" "$executable_path"

  # Set executable permissions
  sudo chmod +x "$executable_path"

else
  # Unsupported operating system
  echo "Unsupported operating system: $OSTYPE"
  exit 1
fi

rm -rf $executable

cat <<-'EOM'
obbctl has been downloaded and is now globally accessible.
You can run it with:

obbctl help
EOM
