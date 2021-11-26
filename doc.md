# Commands(CLI)
- `vagrant box [url]`
- `vagrant dox add [url]`
- `vagrant int`
- `vagrant up`
- `vagrant ssh [vm_name]`
- `vagrant rsync-auto`
- `vagrant destroy [-f]`
- `vagrant reload [--provision | --provision-with [provision_name]]`

---
---

# Box Download
- https://vagrantcloud.com
---
---

# Vagrantfile

## Configuration Version
```ruby
Vagrant.configure("2") do |config|
  # v2 configs...
end
```


## Minimum Vagrant Version
```ruby
Vagrant.require_version ">= 1.3.5"

# or

Vagrant.require_version ">= 1.3.5", "< 1.4.0"
```

## Loop Over VM Definitions
```ruby
(1..3).each do |i|
    config.vm.define "node-#{i}" do |node|
        node.vm.provision "shell",
        inline: "echo hello from node #{i}"
end
```

## Machine Settings
```
config.vm.box = "hashicorp/bionic64"
config.vm.box_version = "1.0.282"
config.vm.box_url = "https://vagrantcloud.com/hashicorp/bionic64"
```

## Network
### forwarded_port
```ruby
config.vm.network "forwarded_port", guest: 4646, host: 4646, host_ip: "127.0.0.1"
```

### public_network
```ruby
master.vm.network "public_network", ip: ip
```
---
---

# Provision

## Shell 
- `name`
- `type`
- `run`
- `inline`
- `path`
### inline
```ruby
config.vm.provision "ins_jenkins", type: "shell", inline: <<-SHELL
        echo "shell command"
SHELL
```

### path
```ruby
node.vm.provision "shell", path: "install.sh", args: [i]
```
---

## Ansible

## Dynamically generate list
```ruby
num_instances = 3

config.vm.provision "ansible" do |ansible|
  ansible.playbook = "playbook.yml"
  ansible.groups = {
      "masters" => ["master"],
      # "nodes" => ["node1", "node2", "node3"],
      "nodes" => ["node[1:#{num_instances}]"],
      "all_group:children" => ["masters", "nodes"]
  }
end
```