#!/bin/bash

#
# Create a WSL development environment.
#
# Locally build the project Dockerfile image, export the container, and import
# into WSL.
#
# Writes WSL output to "$HOME/work/env/wsl/personal/rhel9". Modify this location
# by specifying the `--wsl-output` argument.
#

set -eu
#set -x

# Initialize configuration
dryrun=0
image_base_name="wsl-rhel9"
image_only=0
enable_k8s=0
wsl_output=""
no_cache=0
verbose=0

# Print usage statement and exit
usage() {
>&2 cat << EOF

Usage: $0 [OPTIONS]

Options:
 -n, --name       The quick name suffix to use
                  Defaults to '$image_base_name'
 -w, --wsl-output Set the WSL output location
                  Defaults to '$HOME/work/env/wsl/personal/rhel9/<base_name>'
     --k8s        Enable k8s install. Disabled by default.
     --image-only Build docker image and exit
     --no-cache   Pass to docker build to disable cache
 -v, --verbose    print verbose output
 -d, --dryrun     print commands without executing
 -h, --help       display this help

EOF
exit 1
}

# Process command line args
args=$(getopt -a -o n:w:vdh --long name:,wsl-output:,k8s,image-only,no-cache,verbose,dryrun,help -- "$@")
if [[ $? != 0 ]]; then
  usage
fi

eval set -- "${args}"

while :
do
  case $1 in
    -n | --name)
      image_base_name=$2; shift 2;;
    -w | --wsl-output)
      wsl_output=$2; shift 2;;
    --k8s)
      enable_k8s=1; shift;;
    --image-only)
      image_only=1; shift;;
    --no-cache)
      no_cache=1; shift;;
    -v | --verbose)
      verbose=1; shift;;
    -d | --dryrun)
      dryrun=1; shift;;
    -h | --help)
      usage;;
    # end of arguments
    --)
      shift; break;;
    *)
      >&2 printf "Unsupported option: %s\n" "$1"
      usage;;
  esac
done

# This script does not support any non-flag arguments.
if [[ $# != 0 ]]; then
  usage
fi

# Log function writes all arguments to stderr ending with a newline.
log() {
  if [[ $verbose == 1 ]]; then
    printf "%b " "$@" >&2
    printf "\n" >&2
  fi
}

image_name="personal/rhel9/$image_base_name"

if [ -z "$wsl_output" ]; then
  wsl_output="$HOME/work/env/wsl/$image_name"
fi

# Log runtime configuration
if [[ $verbose ]]; then
  log Configuration...
  log "  dryrun=$dryrun"
  log "  no_cache=$no_cache"
  log "  enable_k8s=$enable_k8s"
  log "  image_only=$image_only"
  log "  verbose=$verbose"
  log "  image_name=$image_name"
  log "  wsl_output=$wsl_output"
fi

# If no-cache enabled, then set the docker build command to insert.
no_cache_cmd=""
if [[ $no_cache == 1 ]]; then
  no_cache_cmd=--no-cache
fi

build_target="build-env"
if [[ $enable_k8s == 1 ]]; then
  build_target="k8s-env"
fi

# Log arguments if dryrun is enabled, otherwise execute the arguments.
dryrun() {
  if [[ $dryrun == 1 ]]; then
    log "dryrun:" "$@"
  else
    "$@"
  fi
}

log Get the script path, use to determine project root dir
script_dir="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
log "script_dir=$script_dir"

log Get the project dir
project_dir="$(cd "$script_dir/../../" >/dev/null 2>&1; pwd -P)"
log "project_dir=$project_dir"

log Get the git commit to use as the image tag...
image_tag=$(git rev-parse --short=9 HEAD~)
log "image_tag=$image_tag"

log Get local git config for container...
user_git_config=/tmp/.gitconfig
{
  printf "[user]\n\tname = "
  git config user.name
  printf "\temail = "
  git config user.email
} >> $user_git_config
dryrun mv "$user_git_config" "$project_dir/tools/docker/dev/"

log Build the docker image...
dryrun docker build \
  $no_cache_cmd \
  --build-arg BASE_IMAGE_NAME="registry.redhat.io/ubi9/ubi" \
  --build-arg BASE_IMAGE_TAG="9.7" \
  --build-arg USERNAME="$USERNAME" \
  --secret id=RHEL_ORG \
  --secret id=RHEL_ACTIVATION_KEY \
  --target "$build_target" \
  --tag "$image_name:$image_tag" \
  "$project_dir/tools/docker/dev/"

if [[ $image_only == 1 ]]; then
  log Exit after building image
  exit 0
fi

log Create a container from the image...
dryrun docker create "$image_name:$image_tag"

log Get the created container id...
container_id=0
container_id="$(dryrun docker container ls --all --quiet --filter "ancestor=$image_name:$image_tag")"
dryrun log "container_id=$container_id"

log Set temp container file location
container_file="/tmp/$image_base_name-$image_tag.tar"
log "container_file=$container_file"

log Export the container...
dryrun docker export "$container_id" > "$container_file"

distro_name=personal-$image_base_name

log Terminate WSL distro if exists...
dryrun wsl --terminate $distro_name || true

log Unregister WSL distro if exists...
dryrun wsl --unregister $distro_name || true

log Create wsl output directory if not exists...
dryrun mkdir -p $wsl_output

log Import new container to WSL...
dryrun wsl --import $distro_name "$wsl_output" "$container_file"

log Remove temporary container file...
dryrun rm -f "$container_file"

log Remove container instance...
dryrun docker container rm "$container_id"

log Remove temp gitconfig...
dryrun rm -r "$project_dir/tools/docker/dev/.gitconfig"

log Done! "\n"
log Enable WSL integration in Docker Desktop settings.
log Launch your new dev env with \"wsl -d $distro_name\"
