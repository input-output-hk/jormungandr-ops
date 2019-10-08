#!/usr/bin/env bash

# https://nixos.org/nixops/manual/#idm140737322394336
# Needed for libvirtd:
#
# virtualisation.libvirtd.enable = true;
# networking.firewall.checkReversePath = false;

sudo mkdir /var/lib/libvirt/images
sudo chgrp libvirtd /var/lib/libvirt/images
sudo chmod g+w /var/lib/libvirt/images
