# Edurange

Join us in #edurange on irc.freenode.net!

EDURange is a project sponsored by the National Science Foundation intended to help automate creation of cyber security training games.
## Introduction
EDURange is working!  This document will be updated at new features are added.  EDURange is both a collection of interactive, collaborative cybersecurity exercises and a framework for creating these exercises. Currently, we have
three exercises: Recon I, ELF Infection, and Scapy Hunt. Recon I was the first exercise created and was based on a scenario
from PacketWars. It focuses on reconnaissance to determine hosts in an unknown network. The standard
tool for this is nmap, and while the student will need to learn how to use that tool in order to do this exercise,
that is not the most important learning goal. The most important learning goal is to develop analysis skills to understand complex systems and complex data. Similarly, the Elf Infection exercise uses standard tools
such as netstat and readelf but requires that students reason about the behavior of a complex system to discover which
binary is infected, where the malicious code is, and what it is doing, e.g. it opens a port and listens for connections, which it should not be doing. Scapy hunt is about listening passively to discover hosts on
the local network and which other hosts on other networks that they are talking to.

There are several more exercises planned, and they can be found in the Future Work section

## Setup

As an instructor, you will use an Instructor VM that will allow you to run scenarios and observe the scoring
events that you can use for assessment. The edurange code that runs the three scenarios that we have is
already installed on the Instructor VM and it launches new VM instances and configures them. Currently,
we have created one instructor machine that you can use or you can make a copy and customize it for your
class. You can start and stop different exercises from the Instructor machine. The AWS console gives you
a way to start and stop the instructor machine and to kill any Amazon Instances (AMIs) that were created
by the instructor machine. For each scenario, there is a YAML file in the edurange directory that specifies the
exercise. It includes the number of students and their temporary passwords. These can be changed in the
YAML file subject to the resource limitations of the account. In general, students will each have their own
EC2 instances to log into and work on the exercises (first they connect through an external IP address to a
Gateway). The next section will lead you through starting an instructor machine and how to use it to create
the scenarios. There are two modes for using EDURange. You may be using your own account or you may
be using the EDURange group account. The use of those two modes will described separately.  We are in the process
of developing a new interface that should eliminate the need to use the AWS console and simplify the process.
You will simply login to the instructor machine, which will always be running.


### Starting the instructor machine from the EDURange account
If you are going to use the EDURange account, you will need the URL for the EDURange account, a
username and password, and you will need to be a member of the edurange group or the edu
fac group. In
the future, we will provide a form on this website for you to request access, but for now send e-mail. Once
you have an account, the URL to sign in will be
https://edurange.signin.aws.amazon.com/
console
After you login to the console, you can navigate to EC2.

At the upper right, there will be a dropdown tab for the different AWS centers. You want East (N Virginia)
and you should see a heading called Resources. Under that, click on the link to
Running Instances. You
should see a list of instances. You want one of the instructor instances, e.g. locasto-instructor.1.
Starting the instructor machine: Scroll down to Locasto-Instructor machine. Look at its instance
status. If it is ”running” then it will have an external IP address and you can login to it. You can login
to this VM with the credentials ubuntu/edurange12. If it is stopped, then click on the box next to the
instance and go to the Actions pull-down tab at the top, and you can start it. You can also right click
on the word “stopped” and you should see an option to start it. The circle in the status will turn from
red to yellow and finally, to green. This can take 5 minutes. It will first say initializing, but eventually
the status check will be complete and you can login. On the lower part of the screen, you will see the
public IP address, using ssh client (on Windows you can use PuTTY),
Be sure to stop the machine when you are done with the exercise.
Do not terminate it, since that
will remove it completely.

If you created your own Instructor machine, you must configure it. You can set the username and
password, as well as a key pair, in the AWS console. AWS can generate a key pair for you. There is
additional information about Installation on the github:
http://www.github.com/sboesen/
edurange/README/
Note: If you are new to EDURange, you can just use the existing Instructor machine and start it.
3.
After logging in to the instructor machine,
> cd edurange
## Usage

We now have three scenarios -
- recon.yml, a host discovery game with a scoring site (github.com/sboesen/edurange_scoring)
- elf.yml, an scenario with an instances with where 'ls' has an elf infection. Scoring is being developed to support elf and other scenarios.
- scapy.yml

Browse to http://ip:3000/scenarios/new, and select from a template if you want to use one of them.



# EDURange Scenarios


Here is a description of how to play the various scenarios

## Recon
The objective of the Recon I exercise is to enumerate all of the hosts on a large network.  You will get
one point for every host that you find (see scoring).  You identify a host by its IP address.
The standard tool to use is nmap, which scans a network by sending multiple packets using a variety of network protocols
and analyzing the responses.
Some of the protocols include ICMP, TCP, and UDP.  You should be familiar at a general level with how these
protocols work and how they can be used to get information about hosts that are alive on a network.
You can start by using nmap without any options, but you will
need the network address to be scanned.  The network address will be specified as a "10." address, and the instructor
should have that information.  You should
be familiar with how to specify an network address using CIDR notation or as a range of IP addresses.


The VM that you will use to scan and the network
that you will be scanning are on AWS/EC2.  
The first step  is to login to the gateway.  The instructor will have the IP address of the gateway.
The main purpose of the gateway is to allow you to login to your player VM instance.  The gateway
will have an external (routable) IP address, while your player VM will not.  The same credentials
should be valid to login to both VMs.   Your instructor will give you the credentials.


## Scapy Hunt
This exercise simulates a network on a single VM.
The game is scored based on finding a file on an FTP server on the simulated network which consists of multiple
subnetworks.


### Scoring.
The way that you submit your answers to be scored is with the following shell command:

echo <answer IP> >> /tmp/scoring

where <answer IP> is the IP address of a host that you found.  If you submit the same IP more than once,
Scorebot will ignore the duplicates.  If you submit an incorrect IP, Scorebot will deduct points from your
score.  You may view your score using the following shell command:

curl http://<ip_of_Scorebot>
This will allow you to view your score without having a browser running.




## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
