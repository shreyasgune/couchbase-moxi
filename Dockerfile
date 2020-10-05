
FROM centos:latest

LABEL Author="sgune <sgune@pm.me>"

EXPOSE 11211

RUN yum clean all
RUN yum update -y
RUN yum install moxi-server consul consul-template nc -y

COPY scripts/init.sh /opt/moxi/etc/init.sh
COPY configs/moxi-cluster.cfg /opt/moxi/etc/moxi-cluster.cfg
COPY configs/moxi.cfg /opt/moxi/etc/moxi.cfg

RUN chown -R moxi:moxi /opt/moxi
RUN chmod +x /opt/moxi/etc/init.sh
USER moxi
CMD /opt/moxi/etc/init.sh
