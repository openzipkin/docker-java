#!/bin/sh
#
# Copyright 2019-2020 The OpenZipkin Authors
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except
# in compliance with the License. You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software distributed under the License
# is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express
# or implied. See the License for the specific language governing permissions and limitations under
# the License.

# Install OS packages that support most software we build
# * openjdk8: includes openjdk8, but not docs or demos
# * tar: BusyBux built-in tar doesn't support --strip=1
# * wget: BusyBox built-in wget doesn't support --tries=3

set -uex

# Ensure we can create hs_err_pid*.log
ulimit -c unlimited
function maybe_log_crash() {
  (cat $(ls hs_err_pid*.log) 2>&- || true) && exit 1;
}

java_version=${1?java_version is required. ex 15.0.1_p9}
maven_version=${2?maven_version is required. ex 3.6.3}

apk --no-cache add openjdk8=~${java_version} tar wget

# Typically, only amd64 is tested in CI: Run commands that ensure binaries match current arch.
# * JDK 1.8 jar doesn't include a version command, so we list a small jar instead
if ! java -version || ! ${JAVA_HOME}/bin/jar -tvf ${JAVA_HOME}/jre/lib/management-agent.jar; then maybe_log_crash; fi

# Connection resets are frequent in CI
alias wget="wget --tries=3 -qO-"

mkdir maven
# Install Maven by downloading it from and Apache mirror. Prime local repository with common plugins
maven_dist_path=/maven/maven-3/$maven_version/binaries/apache-maven-${maven_version}-bin.tar.gz
# Sometimes, closer.cgi returns an empty string
apache_mirror_json=$(wget https://www.apache.org/dyn/closer.cgi\?as_json\=1 || echo '{"preferred":"https://downloads.apache.org/"}')
apache_mirror=$(echo $apache_mirror_json | sed -n '/preferred/s/.*"\(.*\)".*/\1/gp')
# Sometimes, there is a bad mirror in the json
apache_backup_mirror=https://downloads.apache.org/
# First try the preferred mirror. If that's bad, use the backup mirror
(wget ${apache_mirror}${maven_dist_path} || wget ${apache_backup_mirror}${maven_dist_path}) | tar xz --strip=1 -C maven
ln -s ${PWD}/maven/bin/mvn /usr/bin/mvn

mvn -q --batch-mode help:evaluate -Dexpression=maven.version -q -DforceStdout || maybe_log_crash
mvn -q --batch-mode org.apache.maven.plugins:maven-dependency-plugin:3.1.2:get -Dmdep.skip
