ARG DNF_CLEAN=
ARG KOMPOT_VERSION=

FROM rockylinux:9 as base-os
SHELL [ "bash", "-c" ]

COPY ./runit/ /tmp/build-resources/runit/

RUN --mount=id=cache-dnf-el9,target=/var/cache/dnf,type=cache,sharing=locked \
    set -exo pipefail; \
    echo keepcache=1 >> /etc/dnf/dnf.conf; \
        :; \
    curl -L -o /etc/yum.repos.d/kompot.repo \
        https://packages.zenetys.com/projects/kompot/latest/redhat/kompot.repo; \
    awk '/^\[/ {inside=$1} inside=="[crb]"&&/enabled/{print "enabled=1"; next}{print}' \
        /etc/yum.repos.d/rocky.repo > /etc/yum.repos.d/rocky.repo.new; \
    mv /etc/yum.repos.d/rocky.repo{.new,}; \
        :; \
    _dnf() { dnf --setopt install_weak_deps=False -y "$@"; }; \
    _dnf clean expire-cache; \
    _dnf install epel-release; \
    _dnf update; \
    _dnf module enable nodejs:18; \
    _dnf install busybox; \
        :; \
    for i in chpst runsv runsvdir sv svc svlogd svok; do \
        ln -s /usr/sbin/busybox "/usr/local/bin/$i"; \
    done; \
    mv -T /tmp/build-resources/runit /etc/sv; \
        :;

FROM base-os as base-kompot
ARG DNF_CLEAN
ARG KOMPOT_VERSION
SHELL [ "bash", "-c" ]

#COPY ./kompot-latest.rpm /tmp/build-resources/
#COPY ./kompot-setup-latest.rpm /tmp/build-resources/

RUN --mount=id=cache-dnf-el9,target=/var/cache/dnf,type=cache,sharing=locked \
    set -exo pipefail; \
    echo keepcache=1 >> /etc/dnf/dnf.conf; \
        :; \
    groupadd -g 992 -r ssh_keys; \
    groupadd -g 993 -r nagios; \
    useradd -u 993 -r -g nagios -d /var/spool/nagios -s /sbin/nologin nagios; \
    groupadd -g 994 -r influxdb; \
    useradd -u 994 -r -g influxdb -d /var/lib/influxdb -s /bin/false influxdb; \
    groupadd -g 995 -r grafana; \
    useradd -u 995 -r -g grafana -d /usr/share/grafana -s /sbin/nologin grafana; \
    groupadd -g 996 -r centreon; \
    useradd -u 996 -r -g centreon -d /var/log/centreon -s /sbin/nologin centreon; \
        :; \
    _dnf() { dnf --setopt install_weak_deps=False -y "$@"; }; \
    [[ $DNF_CLEAN == 1 ]] && dnf clean all; \
    KOMPOT_SETUP=0 _dnf install kompot{,-setup}${KOMPOT_VERSION:+-$KOMPOT_VERSION}; \
    #KOMPOT_SETUP=0 _dnf install /tmp/build-resources/kompot{,-setup}-latest.rpm; \
        :;

FROM base-kompot
SHELL [ "bash", "-c" ]
ENTRYPOINT [ "/entrypoint" ]

COPY ./entrypoint /

RUN --mount=id=cache-dnf-el9,target=/var/cache/dnf,type=cache,sharing=locked \
    set -exo pipefail; \
        :; \
    rm -f /root/{anaconda-ks.cfg,anaconda-post.log,original-ks.cfg}; \
    rm -rf /var/log/{README,anaconda}; \
        :; \
    awk 'BEGIN { print "#kompot\n#overrides /usr/lib/tmpfiles.d/legacy.conf\n"; } \
         $2 != "/var/log/README"' /usr/lib/tmpfiles.d/legacy.conf \
            > /etc/tmpfiles.d/legacy.conf; \
    awk 'ARGIND == 1 && $1 ~ /[dD]/ && $2 ~ /^\/var\/log\// { x[$2]=1 } \
         ARGIND == 2 && !x[$4] { print $0 }' \
            <(systemd-tmpfiles --cat-config) \
            <(find /var/log -mindepth 1 -maxdepth 1 -type d -printf '%u %g %m %p\n') | \
                sort -k 3 > /opt/kompot/share/install.var-log; \
        :; \
    rm -rf /tmp/build-resources; \
        :;

EXPOSE 22/tcp
EXPOSE 80/tcp
EXPOSE 514/udp
EXPOSE 162/udp

# use -v, --volume explicitly
#VOLUME /etc/kompot
#VOLUME /var/lib/kompot
#VOLUME /var/log
