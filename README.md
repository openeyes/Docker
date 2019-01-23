# docker
Docker configuration etc.

THIS IS NOT READY FOR REAL WORLD USE

# DISCLAIMER
This project is not offically supported. It is currently maintained by @biskyt as a side project, for his own use. While every effort is made to cover a wide range of use cases, your milage may vary.

**NO SUPPORT IS PROVIDED / IMPLIED**, and use is **AT YOUR OWN RISK**

**NOTE:** If you wish to share back docker volumes to a [Windows] host. Use the following image:

`
docker run --name volume-sharer -d -v /var/lib/docker/volumes:/docker_volumes -p 139:139 -p 445:445 -v /var/run/docker.sock:/var/run/docker.sock --net=host gdiepen/volume-sharer`

This will make all volumes available via samba on the host \\10.0.75.2 (which is the default docker for windows VM IP Address)
