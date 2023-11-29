# Homelab Configs

My homelab config files.

## Docker-Main
Main server running docker containers such as Home Assistant, Plex etc. Create a `.env` file. Use the `.env.example` as a template. Update `docker-compose.yml` to use the correct `.env` file and NAS server address.

To setup the directories and files, run `./setup.sh`. This will create the directories and files needed for the docker containers to run.