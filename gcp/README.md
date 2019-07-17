# Poor man's GCP .

## TL;DR

More, easily create virtual machines for development, and disposable.  
There is an important thing, the script is only for my own  .

## Overview
1. Startup script of Google Compute Engine, inject parameter using GCloud and GSUtil .
    1. makes some optimizations for the VM to stands a web server .
        1. i18N setting (localectl) .
        1. l10N setting (timedatectl) .
        1. unforcing SELinux .
        1. makes ready to use some of necessary packages (city-fan, epel, ius, nginx, remi) .
    1. change SSH port number for protect under crack .
        1. SSH port number setting (sshd) .
        1. only use Public Key Authentication .
        1. Firewall setting (firewalld) .
        1. generate SSH key pair .
1. And never do those twice .

## Prerequirement

add some metadatas before create VM instance .

| Sccope | Key | Default value | 
----|----|---- 
| Project | lang | ja_JP.UTF-8 | 
| Project | time-zone | Asia/Tokyo | 
| Project / Instance | ssh-port | 23456 | 
| Project / Instance | ssh-passphrase |(no create SSH key pair, if not specified the value of this key .) | 

