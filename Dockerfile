FROM gitlab/gitlab-runner:v15.8.0
MAINTAINER David Cachau <david.cachau@capsi-informatique.fr>

ADD runner.sh /runner.sh
RUN chmod +x /runner.sh

ENTRYPOINT ["/runner.sh"]
