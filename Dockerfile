FROM gitlab/gitlab-runner:v11.5.0
MAINTAINER Lucas POUZAC <lucas.pouzac@lpoconseil.fr>

ADD runner.sh /runner.sh
RUN chmod +x /runner.sh

ENTRYPOINT ["/runner.sh"]
