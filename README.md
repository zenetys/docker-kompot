## Run manually (eg: for testing)

```
docker run \
    --rm \
    --name kompot \
    --hostname kompot \
    --tmpfs /run \
    --tmpfs /tmp \
    --volume ~/app/kompot/etc:/etc/kompot \
    --volume ~/app/kompot/data:/var/lib/kompot \
    --volume ~/app/kompot/log:/var/log \
    --publish 0.0.0.0:8083:80/tcp \
    --publish 0.0.0.0:8084:443/tcp \
    --publish 0.0.0.0:2222:22/tcp \
    --publish 0.0.0.0:5514:514/udp \
    --publish 0.0.0.0:5514:514/tcp \
    --publish 0.0.0.0:1162:162/udp \
    zenetys/kompot
```

## Run with an auto-(re)start policy (no systemd service integration)

```
docker run \
    --restart unless-stopped \
    --name kompot \
    --hostname kompot \
    --tmpfs /run \
    --tmpfs /tmp \
    --volume ~/app/kompot/etc:/etc/kompot \
    --volume ~/app/kompot/data:/var/lib/kompot \
    --volume ~/app/kompot/log:/var/log \
    --publish 0.0.0.0:8083:80/tcp \
    --publish 0.0.0.0:8084:443/tcp \
    --publish 0.0.0.0:2222:22/tcp \
    --publish 0.0.0.0:5514:514/udp \
    --publish 0.0.0.0:5514:514/tcp \
    --publish 0.0.0.0:1162:162/udp \
    zenetys/kompot
```

## Run as systemd service with podman (recommended)

```
dnf --setopt install_weak_deps=0 install podman
curl -o /etc/containers/systemd/kompot.container \
    https://raw.githubusercontent.com/zenetys/docker-kompot/refs/heads/master/misc/kompot.container
systemctl daemon-reload
systemctl start kompot
systemctl enable kompot
```

## Run as systemd service with docker (discouraged, not reliable)

```
docker pull zenetys/kompot
cp $GIT_SOURCES/misc/docker-run-sd /usr/local/bin/
cp $GIT_SOURCES/misc/docker-kompot.service /etc/systemd/system/
systemctl daemon-reload
systemctl start docker-kompot
systemctl enable docker-kompot
```

## Notes

In order to start the centreon_vmware service, Perl modules from VMware vSphere and vsan SDKs are required. Create a `system` directory in the `/etc/kompot/` volume; put the tarball (vSphere SDK) and zip (vsan SDK) in that directory. The SDKs can be downloaded from Broadcom website :

* https://developer.broadcom.com/sdks/vsphere-perl-sdk/latest
* https://developer.broadcom.com/sdks/vsan-management-sdk-for-perl/latest
