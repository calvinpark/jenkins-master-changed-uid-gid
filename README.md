# tl;dr
Run Jenkins master Docker image [`jenkins/jenkins`](https://hub.docker.com/r/jenkins/jenkins/) as a user with UID & GID that are not [`1000`/`1000`](https://github.com/jenkinsci/docker/blob/master/Dockerfile#L7-L8).

```
docker run -d -P -v /var/jenkins_home/:/var/jenkins_home/:rw \
           calvinpark/jenkins-master-changed-uid-gid ${UID} ${GID}
```
It will
- Modify `jenkins` user's `uid`/`gid` within the container
- `chmod` all files/dirs that were previously owned by `1000`/`1000` uid/gid
- Run `jenkins/jenkins` normally

# Options
```
ROBOT_ACCOUNT_NAME="svc-team-acct"
ROBOT_UID=$(id -u ${ROBOT_ACCOUNT_NAME})
ROBOT_GID=$(id -g ${ROBOT_ACCOUNT_NAME})

TAG="latest-alpine"  # matches the tags in jenkins/jenkins
PLUGINS="$(pwd)/plugins.txt"  # pre-install plugins

docker run -d -P \
           -v /var/jenkins_home/:/var/jenkins_home/:rw \
           -v ${PLUGINS}:/plugins.txt \
           calvinpark/jenkins-master-changed-uid-gid:${TAG} ${ROBOT_UID} ${ROBOT_GID}
```


# Why?
[`jenkins/jenkins`](https://hub.docker.com/r/jenkins/jenkins/) image is configured to run as a user with `uid`/`gid` of [`1000`/`1000`](https://github.com/jenkinsci/docker/blob/master/Dockerfile#L7-L8).

This is a problem when
- `uid`/`gid` of corporate AD robot account is not `1000`/`1000`
- `/var/jenkins_home` is mounted on an NFS share, and you need the files to be owned by the robot account, not the user `1000`

This image accepts `uid`/`gid` as parameters, modifies `jenkins` user's `uid`/`gid` to the parameters, then runs `jenkins/jenkins`.

It also accepts a text file with the list of plugins to pre-install as Jenkins.

