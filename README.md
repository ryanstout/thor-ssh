# thor-ssh

ThorSsh takes thor and allows it to run from local to remote.
It assumes that the sources are always local and the remotes
are always remote.

## Use
		gem 'thor-ssh'

Use thor as you normally would, but on any thor instance add the following:

		class ThorTest < Thor
			include Thor::Actions
			include ThorSsh::Actions

Then set a destination server to an Net::SSH connection to make all actions use a different server for the destination.

		self.destination_server = Net::SSH.start(... [ssh connection] ...)

## Things that don't work yet

This is still a work in progress.  The main issue is that calling #inside or anything that depends on it (in_root) does not work yet.  I'll get it working soon though.

TODO: Get #inside working
TODO: Add other features needed for provisioning system
TODO: Make way to copy remote to remote

## Running Tests
The test run through vagrant, which seemed logical since we want to test ssh stuff.

### Install a box (first time only)
		cd spec/vagrant
		vagrant box add ubuntu11 http://timhuegdon.com/vagrant-boxes/ubuntu-11.10.box
		vagrant init ubuntu11

### Start box
		vagrant up

### Run the tests
		cd ../..
		bundle exec rspec
		
### When you're done
		cd spec/vagrant
		vagrant halt
		
		
### TODO:

Add upload progress: https://github.com/net-ssh/net-sftp/blob/master/lib/net/sftp/operations/upload.rb