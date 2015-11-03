# docker-config-loop

Insert

`add https://raw.githubusercontent.com/steigr/docker-config-loop/master/docker.config-loop.sh /usr/share/shell-libs/` into your Docker file.

Insert

`. /usr/share/shell-libs/*` somewhere at the top of your entrypoint-script.

## Usage

`config_register "variable" "default-value" "severity" "prefix" "suffix"` to register a config variable.

`[[ "$1" = "config" ]] && $@` after initalizing your environment (`config_register()`-calls) but before your application will actually start.

## CLI


### Get default config
`docker $DOCKER_OPTS $IMAGE config print > environment`

### Modify one setting

`docker $DOCKER_OPTS --env-file environment --env VARIABLE_OF_ENVIRONMENT=SETTING $IMAGE config print > environment.tmp && mv environment.tmp environment`

### Launch your App

`docker $DOCKER_OPTS --env-file environment $IMAGE $APP_OPTS`