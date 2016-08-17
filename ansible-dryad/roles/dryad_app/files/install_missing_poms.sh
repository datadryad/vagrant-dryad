#!/bin/sh

# Per http://wiki.datadryad.org/How_To_Install_Dryad#Installation_issues_with_maven
mvn install:install-file -Dfile=discovery-solr-provider-0.9.4-SNAPSHOT.jar  -DgroupId=org.dspace.discovery -DartifactId=discovery-solr-provider -Dversion=0.9.4-SNAPSHOT -Dpackaging=jar
mvn install:install-file -Dfile=dspace-solr-solrj-1.4.0.1-SNAPSHOT.jar  -DgroupId=org.dspace.dependencies.solr -DartifactId=dspace-solr-solrj -Dversion=1.4.0.1-SNAPSHOT -Dpackaging=jar
mvn install:install-file -Dfile=discovery-xmlui-block-0.9.4-SNAPSHOT.jar  -DgroupId=org.dspace.discovery -DartifactId=discovery-xmlui-block -Dversion=0.9.4-SNAPSHOT -Dpackaging=jar

# Carrot2 is missing, discovered on fresh ubuntu install
cd /tmp
mvn install:install-file -DgroupId=org.carrot2 -DartifactId=carrot2-mini -Dversion=3.1.0 -Dpackaging=jar -Dfile=carrot2-mini-3.1.0.jar

# Ensure presence of correct postgres driver
mvn install:install-file -DgroupId=postgresql -DartifactId=postgresql -Dversion=9.4-1206-jdbc4 -Dpackaging=jar -Dfile=/home/ubuntu/dryad-repo/dspace/etc/postgres/postgresql-9.4-1206-jdbc4.jar
