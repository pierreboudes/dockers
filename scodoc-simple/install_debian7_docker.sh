#!/bin/bash

#
# ScoDoc: install third-party software necessary for our installation
# starting for a minimal Debian (Wheezy, 7.0) install.
#
# E. Viennet, Jun 2008, Apr 2009, Sept 2011, Sept 2013, Nov 2013
#

source config.sh
source utils.sh

check_uid_root $0

PYTHON=/opt/zope213/bin/python

# ------------ Safety checks
if [ ${debian_version:0:1} != "7" ]
then
   echo "Version du systeme Linux Debian incompatible"
   exit 1
fi

if [ $(arch) != "x86_64" ]
then
   echo "Version du systeme Linux Debian incompatible (pas X86 64 bits)"
   exit 1
fi

# ------------ Permissions
# source dir should be writable by scodoc to write bytecode files
chgrp www-data $SCODOC_DIR $SCODOC_DIR/ZopeProducts/*
chmod g+w $SCODOC_DIR $SCODOC_DIR/ZopeProducts/*

chgrp -R www-data "${SCODOC_DIR}"/static/photos
chmod -R g+w "${SCODOC_DIR}"/static/photos

# ------------ LOCALES
echo
echo '---- Configuration des locales...'
echo

if [ ! -e /etc/locale.gen ]
then
touch /etc/locale.gen
fi


for locname in en_US.UTF-8 en_US.ISO-8859-15 en_US.ISO-8859-1
do
  outname=$(echo ${locname//-/} | tr '[A-Z]' '[a-z]')
  if [ $(locale -a | egrep -i ^${outname}$ | wc -l) -lt 1 ]
  then
    echo adding $locname
    echo "$locname ${locname##*.}" >> /etc/locale.gen
  fi
done

/usr/sbin/locale-gen --keep-existing


if [ "$LANG" != "en_US.UTF-8" ]
then
   # ceci est necessaire a cause de postgresql 8.3 qui
   # cree son cluster lors de l'install avec la locale par defaut !
   echo "Attention: changement de la locale par defaut"
   mv /etc/default/locale /etc/default/locale.orig
   echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale
   export LANG=en_US.UTF-8
fi
echo 'Done.'


# ------------ AJOUT DES PAQUETS NECESSAIRES
apt-get update
apt-get -y install subversion curl cracklib-runtime firehol
apt-get -y install postgresql-9.1 postgresql-client-9.1
apt-get -y install graphviz

# ------------ INSTALL DES EXTENSIONS PYTHON (2.7)

apt-get -y install python-jaxml
apt-get -y install python-psycopg2
apt-get -y install python-pyrss2gen
apt-get -y install python-imaging python-reportlab
apt-get -y install python-cracklib # was python-crack
apt-get -y install python-pyparsing
apt-get -y install python-beautifulsoup

apt-get -y install python-egenix-mxtools python-egenix-mxdatetime

# Installe la version standard de pydot (XXX A TESTER)
# apt-get -y install python-pydot
# python-pydot is currently bugged in Debian 5: install our 0.9.10
# Le probleme: pydot v > 1 a change l'API : resultat de get_node est une liste. Resolu par sco_utils.pydot_get_node
# pydot 1.0.25 bug avec python 2.4 (get_node_list() renvoie toujours [])
#       1.0.3 idem (voir misc/testpydot.py)
echo '\nInstallation de pydot\n'
apt-get -y remove python-pydot
(cd /tmp; tar xfz $SCODOC_DIR/config/softs/pydot-0.9.10.tar.gz)
(cd /tmp/pydot-0.9.10;  $PYTHON setup.py install)


# UNUSED BY ScoDoc 7:
# SOFTS="$SCODOC_DIR/config/softs"

# ------------
SVNVERSION=$(cd ..; svnversion)
SVERSION=$(curl --silent http://notes.iutv.univ-paris13.fr/scodoc-installmgr/version?mode=install\&svn=$SVNVERSION)
echo $SVERSION > $SCODOC_DIR/config/scodoc.sn


# ------------ PYEXCELERATOR
echo
echo 'Installation de pyExcelerator'
echo

(cd /tmp; tar xfz $SCODOC_DIR/config/softs/pyExcelerator-0.6.3a.patched.tgz)
(cd /tmp/pyExcelerator-0.6.3a.patched; $PYTHON setup.py install)

echo 'Done.'

# ------------ CONFIG SERVICE SCODOC
echo
echo "Installer le service scodoc permet de lancer automatiquement le serveur au demarrage."
#echo -n "Voulez vous installer le service scodoc ? (y/n) [y] "
#read ans
ans='Y'
if [ "$(norm_ans "$ans")" != 'N' ]
then
    echo 'Installation du demarrage automatique de ScoDoc'
    cp $SCODOC_DIR/config/etc/scodoc /etc/init.d/
    insserv scodoc
fi

# ------------ THE END
echo
echo "Installation terminee."
echo
echo "Vous pouvez maintenant creer la base d'utilisateurs avec ./create_user_db.sh"
echo "puis creer un departement avec  ./create_dept.sh"
echo "Ou bien restaurer vos donnees a partir d'une ancienne installation a l'aide du script restore_scodoc_data.sh"
echo "(voir https://trac.lipn.univ-paris13.fr/projects/scodoc/wiki/MigrationVersScoDocSept)"
echo
