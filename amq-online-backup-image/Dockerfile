# the idea I have is to Job, this job will have a list of namespaces
# it will scan each namespace and export the addresses.

FROM quay.io/openshift/origin-cli:latest

ENV APP_ROOT=/opt/amq-online-backup \
    AMQ_ONLINE_NAMESPACE="amq-online-infra" \
    NAMESPACES_LIST="amq-online-infra,products-catalog" \
    BACKUP_FOLDER=/opt/amq-online-backup/backup

USER root

RUN mkdir -p ${APP_ROOT}

RUN groupadd --gid 1001 app-group
RUN useradd --uid 1001 --gid 1001 --non-unique --comment "" --home-dir ${APP_ROOT} app

# See: https://docs.openshift.com/container-platform/4.6/openshift_images/create-images.html#images-create-guide-openshift_create-images
#RUN chmod -R u+x ${APP_ROOT} && \
#    chgrp -R 0 ${APP_ROOT} && \
#    chmod -R g=u ${APP_ROOT}

RUN chown 1001:1001 ${APP_ROOT} && \
    chmod 775 ${APP_ROOT} && \
    chmod g+s ${APP_ROOT}

COPY scripts/ /usr/local/bin/

WORKDIR ${APP_ROOT}

USER app

RUN mkdir ${BACKUP_FOLDER} && \
    chown 1001:1001 ${BACKUP_FOLDER}

VOLUME ["${BACKUP_FOLDER}"]
ENTRYPOINT ["/usr/local/bin/export-amq-online-backup.sh"]
CMD []
