FROM debian:wheezy
MAINTAINER Pierre Boudes <pierre@mindsized.org>
ARG departement="info"
ARG timeout="20"
RUN apt-get -y update && apt-get -y install locales apt-utils
# http://www-l2ti.univ-paris13.fr/~viennet/ScoDoc/builds/scodoc-1287.tgz
COPY scodoc-1287.tgz /opt/
RUN cd /opt && tar xfz scodoc-1287.tgz
#fix policy rc.d
WORKDIR /usr/sbin/
RUN sed -iold "s/exit 101/exit 0/g" policy-rc.d
# installation initiale
WORKDIR /opt/scodoc/Products/ScoDoc/config
COPY install_debian7_docker.sh install_debian7_docker.sh
RUN chmod u+x install_debian7_docker.sh
RUN ./install_debian7_docker.sh
# création de la base
RUN service postgresql start && echo 'Postgresql starting (wait)' && sleep ${timeout} && ./create_user_db.sh
# mise à jour
RUN service postgresql start && echo 'Postgresql starting (wait)' && sleep ${timeout} && ./upgrade.sh
# création de la base
COPY create_dept_docker.sh create_dept_docker.sh
RUN chmod u+x create_dept_docker.sh
RUN service postgresql start && echo 'Postgresql starting (wait)'  && sleep ${timeout} && ./create_dept_docker.sh ${departement}
# Ouvrir le port Scodoc
EXPOSE 8080
# Il faudra aussi ouvrir/remapper le container avec -p 8081:8080
# et mettre en place le reverse proxy ssl (nginx par exemple)
# en servant le contenu statique directement à partir du
# volume /opt/scodoc/{Products/ScoDoc/static/}
# VOLUME /opt/scodoc/ /var/lib/postgresql/
# lancement de scodoc
WORKDIR /
COPY start.sh /
RUN chmod u+x /start.sh
CMD /start.sh ${timeout}
