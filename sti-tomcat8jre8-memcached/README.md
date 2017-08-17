# sti-tomcat8jre8
An attempt to create Tomcat 8 Openshift Image

This work is based on https://github.com/openshift/sti-wildfly maintained by RedHat

Pull the image
---------------

The Docker image is available at https://hub.docker.com/r/barkbay/tomcat8jre8/ You can either build it with the Dockerfile or pull it :

```
$ docker pull barkbay/tomcat8jre8
```

Build an application
--------------------
```
$ s2i build git://github.com/bparees/openshift-jee-sample barkbay/tomcat8jre8 tomcattest
```

Run the image
-------------

```
$ docker run --rm -p 80:8080 tomcattest 
```

Then point your browser to http://localhost

