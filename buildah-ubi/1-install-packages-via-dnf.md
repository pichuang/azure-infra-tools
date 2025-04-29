[root@vm-rhlel9-twn ~]# buildah images
REPOSITORY   TAG   IMAGE ID   CREATED   SIZE

[root@vm-rhlel9-twn ~]# buildah containers
CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME

[root@vm-rhlel9-twn ~]# microcontainer=$(buildah from registry.access.redhat.com/ubi9/ubi-micro)
Trying to pull registry.access.redhat.com/ubi9/ubi-micro:latest...
Getting image source signatures
Checking if image destination supports signatures
Copying blob 314a1726db7d done   |
Copying config c3ce334458 done   |
Writing manifest to image destination
Storing signatures

[root@vm-rhlel9-twn ~]# micromount=$(buildah mount $microcontainer)
[root@vm-rhlel9-twn ~]# dnf install --installroot $micromount --releasever=/ --setopt install_weak_deps=false --setopt=reposdir=/etc/yum.repos.d/ --nodocs -y mtr
Red Hat Enterprise Linux 9 for x86_64 - BaseOS from RHUI (RPMs)                       39 MB/s |  52 MB     00:01
Red Hat Enterprise Linux 9 for x86_64 - AppStream from RHUI (RPMs)                    37 MB/s |  54 MB     00:01
Red Hat CodeReady Linux Builder for RHEL 9 x86_64 (RPMs) from RHUI                    13 MB/s |  12 MB     00:00
Red Hat Enterprise Linux 9 for x86_64 - Supplementary (RPMs) from RHUI               7.4 kB/s | 3.4 kB     00:00
Microsoft Azure RPMs for Red Hat Enterprise Linux 9 (rhel9)                          6.3 kB/s | 2.3 kB     00:00
Dependencies resolved.
=====================================================================================================================
 Package            Architecture      Version                    Repository                                     Size
=====================================================================================================================
Installing:
 mtr                x86_64            2:0.94-6.el9_4             rhel-9-for-x86_64-baseos-rhui-rpms             91 k
Installing dependencies:
 jansson            x86_64            2.14-1.el9                 rhel-9-for-x86_64-baseos-rhui-rpms             48 k

Transaction Summary
=====================================================================================================================
Install  2 Packages

Total download size: 139 k
Installed size: 272 k
Downloading Packages:
(1/2): jansson-2.14-1.el9.x86_64.rpm                                                 189 kB/s |  48 kB     00:00
(2/2): mtr-0.94-6.el9_4.x86_64.rpm                                                   284 kB/s |  91 kB     00:00
---------------------------------------------------------------------------------------------------------------------
Total                                                                                429 kB/s | 139 kB     00:00
Running transaction check
Transaction check succeeded.
Running transaction test
Transaction test succeeded.
Running transaction
  Preparing        :                                                                                             1/1
  Installing       : jansson-2.14-1.el9.x86_64                                                                   1/2
  Installing       : mtr-2:0.94-6.el9_4.x86_64                                                                   2/2
  Running scriptlet: mtr-2:0.94-6.el9_4.x86_64                                                                   2/2
  Verifying        : jansson-2.14-1.el9.x86_64                                                                   1/2
  Verifying        : mtr-2:0.94-6.el9_4.x86_64                                                                   2/2
Installed products updated.

Installed:
  jansson-2.14-1.el9.x86_64                                 mtr-2:0.94-6.el9_4.x86_64

Complete!

[root@vm-rhlel9-twn ~]# buildah umount ${microcontainer}
f47cb9a5a68457c983bdcf205c895885872b1ddb8fde12741a4c1cb67518fa68

[root@vm-rhlel9-twn ~]# buildah commit ${microcontainer} mtr-ubi9-micro
Getting image source signatures
Copying blob f9c54b5fcfef skipped: already exists
Copying blob 62e5c95f73fb done   |
Copying config dd9a02b631 done   |
Writing manifest to image destination
dd9a02b63188fcfd7d3b45f5cb7c7112a00717648638d44d8829e72d5411fb77

[root@vm-rhlel9-twn ~]# buildah images
REPOSITORY                                  TAG      IMAGE ID       CREATED          SIZE
localhost/mtr-ubi9-micro                    latest   dd9a02b63188   17 seconds ago   252 MB
registry.access.redhat.com/ubi9/ubi-micro   latest   c3ce3344581e   26 hours ago     23.5 MB

[root@vm-rhlel9-twn ~]# podman run --rm -it localhost/mtr-ubi9-micro mtr --version
mtr 0.94