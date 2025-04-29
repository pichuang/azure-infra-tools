[root@vm-rhlel9-twn ~]# buildah images
REPOSITORY                                  TAG      IMAGE ID       CREATED         SIZE
localhost/mtr-ubi9-micro                    latest   dd9a02b63188   6 minutes ago   252 MB
registry.access.redhat.com/ubi9/ubi-micro   latest   c3ce3344581e   26 hours ago    23.5 MB

[root@vm-rhlel9-twn ~]# buildah containers
CONTAINER ID  BUILDER  IMAGE ID     IMAGE NAME                       CONTAINER NAME

[root@vm-rhlel9-twn ~]# git clone https://github.com/upa/deadman

[root@vm-rhlel9-twn ~]# buildah from localhost/mtr-ubi9-micro
mtr-ubi9-micro-working-container

[root@vm-rhlel9-twn ~]# mount_point=$(buildah mount mtr-ubi9-micro-working-container)
echo "Container mounted at: $mount_point"
Container mounted at: /var/lib/containers/storage/overlay/cb36b6e56a8c273d19652d2d6b8cba82b0c4e45e5e9776b24d1b528e6c45d5ca/merged

[root@vm-rhlel9-twn ~]# cp -r ./deadman "$mount_point"/root/
[root@vm-rhlel9-twn root]# ls -la "$mount_point"/root/deadman
total 44
drwxr-xr-x. 4 root root   114 Apr 29 15:08 .
dr-xr-x---. 1 root root    21 Apr 29 15:08 ..
-rwxr-xr-x. 1 root root 27413 Apr 29 15:08 deadman
-rw-r--r--. 1 root root  1278 Apr 29 15:08 deadman.conf
drwxr-xr-x. 8 root root   163 Apr 29 15:08 .git
-rw-r--r--. 1 root root    17 Apr 29 15:08 .gitignore
drwxr-xr-x. 2 root root    30 Apr 29 15:08 img
-rw-r--r--. 1 root root  1088 Apr 29 15:08 LICENSE
-rw-r--r--. 1 root root  1745 Apr 29 15:08 README.md

[root@vm-rhlel9-twn root]# buildah umount mtr-ubi9-micro-working-container
9eab110f72b35fe1ca35b8e10d797342e2d41190ddc9240eacb506f2280b17a6

[root@vm-rhlel9-twn root]# buildah commit mtr-ubi9-micro-working-container deadmna-ubi9-micro
Getting image source signatures
Copying blob f9c54b5fcfef skipped: already exists
Copying blob 62e5c95f73fb skipped: already exists
Copying blob 1722f02f7ea1 done   |
Copying config 3ae277e240 done   |
Writing manifest to image destination
3ae277e240201af7a429194cc4fa7cbe2537dd43eddbaa90d733c2202005b443

[root@vm-rhlel9-twn root]# buildah images
REPOSITORY                                  TAG      IMAGE ID       CREATED          SIZE
localhost/deadmna-ubi9-micro                latest   3ae277e24020   44 seconds ago   260 MB
localhost/mtr-ubi9-micro                    latest   dd9a02b63188   11 minutes ago   252 MB
registry.access.redhat.com/ubi9/ubi-micro   latest   c3ce3344581e   26 hours ago     23.5 MB

[root@vm-rhlel9-twn root]# podman run --rm -it localhost/deadmna-ubi9-micro ./deadman/deadman

