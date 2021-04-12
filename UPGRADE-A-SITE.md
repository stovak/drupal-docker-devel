# How to upgrade a site to d9 with the latest upstream

1. make source-site

   This command copies a repository down from the cloud: Either from a git url or from
   a pantheon site id.

2. make destination-site

   ** WORK IN PROGRESS - Pardon our construction in this build step **

   Create a new site at pantheon that has the d9 upstream, and integrated composer build step
   As well as Maria DB 10.4

3. make source-destination-upgrade

   not working yet













# Definitions

1. upstream

   A lineage repo on pantheon that tells pantheon's WEB OPS DASHBOARD how to interact with your site,
   request upgrades and basically all the features you've come to love on the dashboard.
