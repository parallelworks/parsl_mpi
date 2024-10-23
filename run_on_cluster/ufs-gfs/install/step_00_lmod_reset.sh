#! /bin/bash
#=============================
# Some cloud clusters' images
# come set up expecting to use
# modules at attached storage
# /apps. Run this script to 
# destroy this persistent 
# background assumption.
#=============================

echo Starting step 00 lmod reset...

sudo rm /etc/profile.d/modules.*
sudo rm /usr/share/Modules/init/profile.sh
sudo rm /usr/share/Modules/init/profile.csh
sudo yum reinstall -y environment-modules

# After these commands, source .bashrc or /etc/profile.d/modules.sh
# or log out and log back in to reload the profile.d scripts.
# On some previous images, simply sourcing ~/.bashrc worked, but
# on some newer images, need to add the modules config explicitly.
# Do not automate this step since we need to do this on the head
# node, too, and it only needs to be done once.
#echo "source /etc/profile.d/modules.sh" >> ~/.bashrc

echo "Done with lmod reset."
echo "Please run: echo "source /etc/profile.d/modules.sh" >> ~/.bashrc"
echo "You now need to log back in or source ~/.bashrc to setup modules environment!"

