Creating a scenario in EDURange is quite straightforward, although it will be easier as the API gets further developed. Currently all you need to do is edit the YML file, which defines some combination of the objects below. This document will serve as a reference for all of the parameters any object can take currently.

Currently, the YML format is quite simple. All objects are kept within a root key named the pluralization of the object. "Instance" objects are kept within "Instances:", etc. Example code for each object is provided. Please note any "name" parameters MUST BE UNIQUE.


# Roles
Roles are container objects for both software packages and chef recipes, either built into EDURange or part of the community, and are referenced by name within an Instance object in order to apply the role.

Definining the "attacker" role

```yaml
Roles:
  - Name: attacker
    Packages:
      - nmap
      - wireshark
      - tshark
    Recipes:
      - sshd_password_login
      - wheelie
```

Referencing it within an instance
```yaml
  - Name: Player_1_Instance
    Subnet: Player_Subnet 
    OS: ubuntu
    IP_Address: 10.0.123.2
    Roles:
      - web_server
```

# Groups
Groups are container objects which each have a name, like "Team_1", a list of users (login/password pair), a list of Instance objects the group has user access to, as well as a list of Instance objects the group has administrator access to.

```yaml
Groups:
  - Name: Team_1
    Access:
      Administrator:
        - Team_1_Instance
      User:
        - NAT_Instance
    Users:
      - Login: edurange_1
        Password: abcd
      - Login: edurange_2
        Password: abcd
```

# Scenarios
Currently, scenarios only have two parameters - a Game_Type, which is currently discarded yet mandatory, and a name, which sets the scenario display name (and is referenced by clouds).

```
Scenarios:
  - Game_Type: ctf
    Name: Recon
```

# Clouds
Clouds have a name as well, but only for subnets to reference. The reference a scenario they belong to, and have a CIDR_Block, which must contain all subnets and at least for AWS may not be larger than a /16.

```yaml
Clouds:
  - Name: Cloud_1
    CIDR_Block: 10.0.0.0/16
    Scenario: Recon
```

# Subnets
Subnets have a name describing the subnet, reference a cloud, and have a CIDR_Block which must be within the cloud. The subnet cannot be smaller than a /28 in AWS. Currently there cannot be more than one internet accessible subnet, if a subnet is internet accessible the routing of internet-bound traffic travels through ths subnet's NAT instance.

```yaml
Subnets:
  - Name: Player_Subnet
    Cloud: Cloud_1
    CIDR_Block: 10.0.128.0/24
    Internet_Accessible: false # only necessary if true
```

# Instances
Instances have a name, subnet, and reference roles. Additionally, they have a boolean value Internet_Acessible, which determines if they are assigned a public IP address, and if they are the NAT instance of the corresponding internet accessible subnet. Currently the OS must be set to NAT, but if they are not internet accessible the OS can also be set to ubuntu. No other OSs are supported at this time, but if you need a specific OS we can add support trivially. Finally, instances are given a private IP address which must be within the Subnet's CIDR_Block.

```yaml
Instances:
  - Name: NAT_Instance
    Subnet: NAT_Subnet
    OS: nat
    IP_Address: 10.0.129.5
    Internet_Accessible: true
    Roles:
      - NAT
```
