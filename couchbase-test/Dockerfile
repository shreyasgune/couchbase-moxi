FROM centos:latest
LABEL Author="sgune <sgune@pm.me>"

RUN yum clean all
RUN yum -y install initscripts && yum clean all
RUN yum update -y

ENV PATH=$PATH:/opt/couchbase/bin:/opt/couchbase/bin/tools:/opt/couchbase/bin/install

RUN yum install numactl -y

RUN curl -O http://packages.couchbase.com/releases/couchbase-release/couchbase-release-1.0-5-x86_64.rpm
RUN rpm -i couchbase-release-1.0-5-x86_64.rpm
RUN yum update -y
RUN yum install couchbase-server-community -y

RUN mkdir /opt/couchbase/var/lib/couchbase/data
RUN chgrp -R couchbase /opt/couchbase/var/lib/couchbase/data
RUN chown -R couchbase /opt/couchbase/var/lib/couchbase/data

RUN mkdir /opt/couchbase/var/lib/couchbase/index
RUN chgrp -R couchbase /opt/couchbase/var/lib/couchbase/index
RUN chown -R couchbase /opt/couchbase/var/lib/couchbase/index

COPY couchbase-test/override.conf /etc/systemd/system/couchbase-server.service.d/override.conf
RUN chgrp -R root /etc/systemd/system/couchbase-server.service.d/override.conf
RUN chown -R root /etc/systemd/system/couchbase-server.service.d/override.conf
RUN chmod 644 /etc/systemd/system/couchbase-server.service.d/override.conf

COPY couchbase-test/init.sh /etc/couchbase/init.sh
RUN chmod 700 /etc/couchbase/init.sh


EXPOSE 8091

CMD /etc/couchbase/init.sh
