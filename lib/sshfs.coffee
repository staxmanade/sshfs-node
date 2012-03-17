exec = require('child_process').exec
util = require 'util'
fs = require 'fs'

sshfs = {}

sshfs.mount = (user, host, mountpoint, callback) ->
  #sshfs -o StrictHostKeyChecking=no ec2-user@ec2-50-16-89-0.compute-1.amazonaws.com:/ ssh-test
  command = util.format 'sshfs -o StrictHostKeyChecking=no %s@%s:/ %s', user, host, mountpoint
  sshfs.exec command, callback
    
sshfs.umount = (mountpoint, force, tryMax, callback) ->
  #fusermount -u ssh-test

  # This method is called 10 times if the device is busy

  # following errors should not be retry:
  ##### fusermount: bad mount point /tmp/cbe/mountpoints/4f358725d5e285bb79000004: No such file or directory

  if arguments.length == 3
    callback = arguments[2]
    force = arguments[1]
    tryMax = 10
  else if arguments.length == 2
    callback = arguments[1]
    tryMax = 10
    force = false
  else if arguments.length == 1
    return ;

  forceArg = ''
  if force
    forceArg = '-z'
    tryMax = 0

  command = util.format 'fusermount -u %s %s', forceArg, mountpoint
  sshfs.exec command, (error, stdout, stderr) ->
    if error
      if tryMax == 0
        if force 
          callback null
          return
        callback 'Try Max is reached'
        return
      else
        setTimeout ()-> 
          sshfs.umount mountpoint, (tryMax-1), callback 
        , 1000
    else
      sshfs.log ['umounted ' + mountpoint]
      callback null
    return

sshfs.exec = (command, callback) ->
  tryMax = 10;
  sshfs.log ['Call command: ' + command]
  exec command, (error, stdout, stderr) ->
    if error
      sshfs.log [error, stdout, stderr]
      callback error, stdout, stderr
    else
      callback null

sshfs.log = (messages) ->


exports = module.exports = sshfs;