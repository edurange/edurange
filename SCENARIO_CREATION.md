
Scenario resources are provisioned using terraform.
A scenario directory must be valid terraform project.

Additionally a `yaml` file is loaded by `edurange-server` and contains information such as a description, player groups, variables, questions, and scenario instances.
This information copied to the `edurange-server` database when creating a new scenario.

Some of this information, such as a list of players and variables, is passed to terraform to be used during configuration.
Also, a scenario's terraform project should output values such as instances public and private ips to update the `edurange-server` datebase.

# Scenario YAML

A scenario yaml file should specify instances, groups, and possibly variables.

## Groups
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

Additionally a group can have variables, which are instantiated for each player in the group.
For example:

```yaml
Groups:
  - Name: Team_1
  - Variables:
    - Name: a_variable
      Type: random
```

This will instantiate a random string for each player in the group.

# Instances
Instances have a name.
The terraform project can output a public and private ip to update the `edurange-server` database.
This allows users to know what public ip to log on to.

```yaml
Instances:
  - Name: NAT_Instance
```
