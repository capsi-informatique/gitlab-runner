#!/usr/bin/env bash
set -x

pid=0

TOKEN=()
GITLAB_SERVICE_URL=${GITLAB_PROTOCOL}://${GITLAB_HOST}

# SIGTERM-handler
term_handler() {
  if [ $pid -ne 0 ]; then
    kill -SIGTERM "$pid"
    wait "$pid"
  fi
  gitlab-runner unregister -u ${GITLAB_SERVICE_URL} -t ${TOKEN}
  exit 143; # 128 + 15 -- SIGTERM
}

# setup handlers
# on callback, kill the last background process, which is `tail -f /dev/null` and execute the specified handler
trap 'kill ${!}; term_handler' SIGTERM


if [[ ${SSL_CERTIFICATE} ]]; then
  ln -sf ${SSL_CERTIFICATE} /etc/gitlab-runner/certs/${GITLAB_HOST}.crt
fi

REGISTER_PARAMS='--url '${GITLAB_SERVICE_URL}
REGISTER_PARAMS=${REGISTER_PARAMS}' --registration-token '${GITLAB_RUNNER_TOKEN}
REGISTER_PARAMS=${REGISTER_PARAMS}' --executor docker'
REGISTER_PARAMS=${REGISTER_PARAMS}' --name "runner"'
REGISTER_PARAMS=${REGISTER_PARAMS}' --output-limit 20480'
REGISTER_PARAMS=${REGISTER_PARAMS}' --docker-image "docker:latest"'
REGISTER_PARAMS=${REGISTER_PARAMS}' --locked=false'
REGISTER_PARAMS=${REGISTER_PARAMS}' --docker-volumes /var/run/docker.sock:/var/run/docker.sock'
if [[ ${GITLAB_IP} ]]; then
  REGISTER_PARAMS=${REGISTER_PARAMS}' --docker-extra-hosts ${GITLAB_HOST}:${GITLAB_IP}'
fi
if [[ ${GITLAB_TAG_LIST} ]]; then
  REGISTER_PARAMS=${REGISTER_PARAMS}' --tag-list "'${GITLAB_TAG_LIST}'"'
fi

# register runner
yes '' | gitlab-runner register ${REGISTER_PARAMS}

# assign runner token
TOKEN=$(cat /etc/gitlab-runner/config.toml | grep token | awk '{print $3}' | tr -d '"')

# run multi-runner
gitlab-ci-multi-runner run --user=gitlab-runner --working-directory=/home/gitlab-runner & pid="$!"

# wait forever
while true
do
  tail -f /dev/null & wait ${!}
done
