# Commands(CLI)
- vagrant box

- vagrant int

- vagrant up

- vagrant ssh

- vagrant rsync-auto

- vagrant destroy


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
